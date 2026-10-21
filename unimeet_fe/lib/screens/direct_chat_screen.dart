import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/meetup_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DirectChatScreen extends StatefulWidget {
  final String friendEmail;
  final String friendName;
  final String friendMajor;
  final String friendInitials;
  final String friendNim;
  final String friendCampus;
  final bool isOnline;

  const DirectChatScreen({
    super.key,
    required this.friendEmail,
    required this.friendName,
    required this.friendMajor,
    required this.friendInitials,
    required this.friendNim,
    required this.friendCampus,
    this.isOnline = true,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _canChat = false;
  String _lockReason = 'Checking friend relation...';
  Timer? _pollingTimer;

  String get _myEmail =>
      AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Poll messages every 2.5 seconds to receive real incoming messages
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _pollMessages();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    await _pollMessages();
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _pollMessages() async {
    try {
      final res = await ApiService.instance.fetchDirectMessages(
        _myEmail,
        widget.friendEmail,
      );

      final canChat = res['canChat'] == true;
      final reason = res['reason']?.toString() ??
          'You can only chat after accepting a friend request.';

      final List rawMessages = res['messages'] as List? ?? [];
      final List<ChatMessage> mapped = rawMessages.map((m) {
        final isMe = m['isMe'] == true || (m['senderEmail'] ?? '').toString().toLowerCase() == _myEmail;
        DateTime? dt;
        try {
          if (m['createdAt'] != null) dt = DateTime.parse(m['createdAt'].toString()).toLocal();
        } catch (_) {}
        final timeStr = dt != null
            ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : 'Just now';

        return ChatMessage(
          id: m['id']?.toString() ?? UniqueKey().toString(),
          senderName: isMe ? 'You' : (m['senderName'] ?? widget.friendName),
          senderMajor: isMe ? '' : widget.friendMajor,
          avatarUrl: '',
          text: m['content']?.toString() ?? '',
          time: timeStr,
          isSelf: isMe,
        );
      }).toList();

      if (mounted) {
        final hadNewMessages = mapped.length > _messages.length;
        setState(() {
          _canChat = canChat;
          _lockReason = reason;
          _messages = mapped;
        });
        if (hadNewMessages) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error polling direct messages: $e');
    }
  }

  Future<void> _sendMessage({String? quickText}) async {
    if (!_canChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lockReason),
          backgroundColor: AppColors.statusTrendingCoral,
        ),
      );
      return;
    }

    final text = quickText ?? _textController.text.trim();
    if (text.isEmpty) return;

    if (quickText == null) {
      _textController.clear();
    }

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final optimisticMsg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      senderName: 'You',
      avatarUrl: '',
      text: text,
      time: timeStr,
      isSelf: true,
    );

    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    // Send real message to database
    final res = await ApiService.instance.sendDirectMessage(
      _myEmail,
      widget.friendEmail,
      text,
    );

    if (res == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: AppColors.statusTrendingCoral,
        ),
      );
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

  void _showStudentProfileModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.campusBlue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.friendInitials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.friendName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.friendMajor} • NIM ${widget.friendNim}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.friendEmail,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _canChat ? Icons.check_circle : Icons.lock,
                      size: 16,
                      color: _canChat ? AppColors.statusOpenEmerald : AppColors.statusTrendingCoral,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _canChat ? 'Accepted Friends • Chat Unlocked' : 'Friend Request Pending / Locked',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _canChat ? AppColors.statusOpenEmerald : AppColors.statusTrendingCoral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close Profile',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _showStudentProfileModal(isDark),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryContainer, AppColors.campusBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.friendInitials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_canChat)
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.statusOpenEmerald,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                              width: 2,
                            ),
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
                          Flexible(
                            child: Text(
                              widget.friendName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: AppColors.campusBlue),
                        ],
                      ),
                      Text(
                        _canChat
                            ? 'Friend • ${widget.friendMajor}'
                            : 'Friend Request Required',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: _canChat
                              ? AppColors.statusOpenEmerald
                              : AppColors.statusTrendingCoral,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded,
                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface),
            tooltip: 'Friend Information',
            onPressed: () => _showStudentProfileModal(isDark),
          ),
        ],
      ),
      body: Column(
        children: [
          // Friend Status / Safety Banner
          if (!_canChat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.statusTrendingCoral.withOpacity(0.12),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.statusTrendingCoral, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Chat Locked',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusTrendingCoral,
                          ),
                        ),
                        Text(
                          'You can only chat once both students have accepted the friend request.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow)
                    .withOpacity(0.7),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Direct chat with verified ${widget.friendCampus} friend',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
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
                              child: Icon(
                                _canChat ? Icons.chat_bubble_outline_rounded : Icons.lock_outline_rounded,
                                size: 28,
                                color: _canChat ? AppColors.primary : AppColors.outline,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _canChat
                                  ? 'No messages yet\nSend a message to ${widget.friendName.split(' ').first}!'
                                  : 'Chat is locked until friend request is accepted',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg, isDark);
                        },
                      ),
          ),

          // Typing Input Bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final isSelf = msg.isSelf;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSelf) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.campusBlue],
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.friendInitials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelf
                    ? const LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelf
                    ? null
                    : (isDark ? AppColors.darkSurfaceCard : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isSelf ? 18 : 4),
                  bottomRight: Radius.circular(isSelf ? 4 : 18),
                ),
                border: isSelf
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: isSelf
                          ? Colors.white
                          : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: isSelf
                              ? Colors.white.withOpacity(0.7)
                              : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline),
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _textController,
                enabled: _canChat,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: _canChat
                      ? 'Message ${widget.friendName.split(' ').first}...'
                      : 'Chat locked (Requires accepted friend request)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant.withOpacity(0.6)
                        : AppColors.outline,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _canChat ? () => _sendMessage() : null,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: _canChat
                    ? const LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _canChat ? null : Colors.grey.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
