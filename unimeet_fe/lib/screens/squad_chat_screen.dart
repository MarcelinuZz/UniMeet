import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/meetup_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SquadChatScreen extends StatefulWidget {
  final String eventId;
  final String title;
  final String memberCount;
  final String categoryEmoji;
  final List<ChatMessage>? initialMessages;

  const SquadChatScreen({
    super.key,
    this.eventId = '',
    this.title = 'Squad Chat',
    this.memberCount = '2/4',
    this.categoryEmoji = '🏸',
    this.initialMessages,
  });

  @override
  State<SquadChatScreen> createState() => _SquadChatScreenState();
}

class _SquadChatScreenState extends State<SquadChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<ChatMessage> _messages;
  Timer? _pollingTimer;
  Map<String, dynamic>? _eventDetails;

  String get _myEmail =>
      AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';

  String get _displayTitle => _eventDetails?['title'] ?? widget.title;

  String get _displayMemberCount {
    if (_eventDetails != null) {
      final cur = _eventDetails!['currentSlots'] ??
          (_eventDetails!['roster'] as List?)?.length ??
          1;
      final max = _eventDetails!['maxSlots'] ??
          _eventDetails!['maxParticipants'] ??
          4;
      return '$cur/$max';
    }
    return widget.memberCount;
  }

  String get _displayCategoryEmoji {
    if (_eventDetails != null) {
      final cat = (_eventDetails!['category'] ?? '').toString().toLowerCase();
      if (cat.contains('sport') || cat.contains('badminton')) return '🏸';
      if (cat.contains('game') || cat.contains('gaming')) return '🎯';
      if (cat.contains('acad') || cat.contains('study')) return '📚';
      if (cat.contains('tech') || cat.contains('code')) return '☕';
      if (cat.contains('food')) return '🍔';
    }
    return widget.categoryEmoji;
  }

  String get _displayTimeString => _eventDetails?['timeString'] ?? 'Segera Diumumkan';
  String get _displayLocation => _eventDetails?['location'] ?? 'BINUS Campus Venue';
  String get _displayCampus => _eventDetails?['campus'] ?? 'BINUS Anggrek Campus';
  String get _displayPassCode =>
      _eventDetails?['turnstileCode'] ??
      (widget.eventId.length > 5 ? '#${widget.eventId.substring(0, 4).toUpperCase()}' : '#4402');

  @override
  void initState() {
    super.initState();
    _messages = widget.initialMessages != null
        ? List<ChatMessage>.from(widget.initialMessages!)
        : [];
    if (widget.eventId.isNotEmpty) {
      _loadEventDetails();
      _loadMessages();
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        _pollMessages();
      });
    }
  }

  Future<void> _loadEventDetails() async {
    if (widget.eventId.isEmpty) return;
    try {
      final details = await ApiService.instance.fetchEventDetails(widget.eventId, _myEmail);
      if (mounted && details != null) {
        setState(() {
          _eventDetails = details;
        });
      }
    } catch (e) {
      debugPrint('Error loading squad event details: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    await _pollMessages();
    if (mounted) {
      _scrollToBottom();
    }
  }

  Future<void> _pollMessages() async {
    if (widget.eventId.isEmpty) return;
    try {
      final raw = await ApiService.instance.fetchEventMessages(widget.eventId);
      final myName = AuthService.instance.currentUser?.name ?? '';
      final myEmail = _myEmail.toLowerCase();
      final mapped = raw.map((m) {
        final senderId = (m['senderId'] ?? '').toString().toLowerCase();
        final senderEmail = (m['senderEmail'] ?? '').toString().toLowerCase();
        final senderName = (m['senderName'] ?? '').toString();
        final isMe = (senderEmail.isNotEmpty && senderEmail == myEmail) ||
            senderId == myEmail ||
            (myName.isNotEmpty && senderName.toLowerCase() == myName.toLowerCase());

        DateTime? dt;
        try {
          if (m['createdAt'] != null) dt = DateTime.parse(m['createdAt'].toString()).toLocal();
        } catch (_) {}
        final timeStr = dt != null
            ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : 'Just now';

        return ChatMessage(
          id: m['id']?.toString() ?? UniqueKey().toString(),
          senderName: isMe ? 'You' : (m['senderName'] ?? 'Binusian'),
          senderMajor: m['senderMajor'] ?? '',
          avatarUrl: '',
          text: m['content']?.toString() ?? '',
          time: timeStr,
          isSelf: isMe,
          isHost: m['isHost'] == true,
        );
      }).toList();

      if (mounted) {
        // Retain optimistic messages that haven't yet been confirmed by the server
        final pendingOptimistic = _messages.where((m) => m.id.startsWith('temp-')).toList();
        final confirmedTexts = mapped.map((m) => m.text.trim()).toSet();
        final stillPending = pendingOptimistic
            .where((o) => !confirmedTexts.contains(o.text.trim()))
            .toList();

        final merged = [...mapped, ...stillPending];
        final hadNew = merged.length > _messages.length;
        setState(() {
          _messages = merged;
        });
        if (hadNew) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error polling event messages: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final optimistic = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      senderName: 'You',
      avatarUrl: '',
      text: text,
      time: timeStr,
      isSelf: true,
    );

    setState(() {
      _messages.add(optimistic);
    });
    _scrollToBottom();

    if (widget.eventId.isNotEmpty) {
      final res = await ApiService.instance.sendEventMessage(widget.eventId, _myEmail, text);
      if (res != null) {
        await _pollMessages();
      }
    }
  }

  void _showVenueSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _displayLocation,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_run, size: 36, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      _displayLocation,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ),
                    Text(
                      _displayCampus,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOCKER & TURNSTILE PASS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.outline,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displayPassCode,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Passcode $_displayPassCode copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(
                        'Copy',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Back to Chat',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(_displayCategoryEmoji, style: const TextStyle(fontSize: 18)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.statusOpenEmerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _displayTitle,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($_displayMemberCount)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.statusOpenEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4 online now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.statusOpenEmerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusTrendingSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 12, color: AppColors.statusTrendingCoral),
                const SizedBox(width: 4),
                Text(
                  '3h 15m',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusTrendingCoral,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showVenueSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Event Announcement Banner
          InkWell(
            onTap: _showVenueSheet,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryContainer.withOpacity(0.12),
                    AppColors.accentElectricViolet.withOpacity(0.12),
                    AppColors.campusBlue.withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryContainer.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.stadium, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'PINNED MEETUP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ' · $_displayTimeString',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _displayLocation,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pass: $_displayPassCode',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.qr_code, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat Stream
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                // Day Divider
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Messages
                ..._messages.map((msg) => _buildMessageBubble(msg, isDark)),

                // Empty state if no messages
                if (_messages.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.darkSurfaceCard
                                      : AppColors.surfaceContainerLow)
                                  .withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Squad chat created! 🎉\nSend the first message to your squad members.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),

          // Bottom Suggestions Bar (Icebreakers & Polls)
          Container(
            color: (isDark ? AppColors.darkSurfaceCard : Colors.white).withOpacity(0.95),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _buildPromptChip(
                    '💡 Icebreaker: What major are you in?',
                    () {
                      _msgController.text = "Hey everyone! What major is everyone in? I'm in Computer Science!";
                    },
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPromptChip(
                    '📊 Poll: Warmup time?',
                    () {
                      _msgController.text = "Who wants to do a quick 15-min stretch together before starting?";
                    },
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPromptChip(
                    '📍 Share Court Pass',
                    () => _showVenueSheet(),
                    isDark,
                  ),
                ],
              ),
            ),
          ),

          // Message Input Control Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.poll_outlined, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgController,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Message squad...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.outline,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sentiment_satisfied_outlined, size: 18),
                            color: AppColors.outline,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    if (msg.isSelf) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.outline),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'You',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        msg.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Delivered',
                            style: TextStyle(fontSize: 9, color: Colors.white70),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.done_all, size: 12, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: (msg.avatarUrl.isNotEmpty && msg.avatarUrl.startsWith('http'))
                    ? NetworkImage(msg.avatarUrl)
                    : null,
                child: (msg.avatarUrl.isEmpty || !msg.avatarUrl.startsWith('http'))
                    ? Text(
                        msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : 'U',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              if (msg.isHost)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.campusBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'HOST',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    msg.senderName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                  if (msg.senderMajor != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      msg.senderMajor!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.campusBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    msg.time,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.outline),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        height: 1.35,
                      ),
                    ),
                    if (msg.bookingSlip != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                msg.bookingSlip!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.statusOpenLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PAID',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusOpenEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (msg.reactions != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: msg.reactions!.entries.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${e.key} ${e.value}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
