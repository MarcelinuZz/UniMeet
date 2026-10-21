import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/meetup_model.dart';
import '../models/user_model.dart';
import 'squad_chat_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final MeetupItem meetup;
  final VoidCallback? onJoinedChanged;
  final VoidCallback? onOpenChat;

  const EventDetailsScreen({
    super.key,
    required this.meetup,
    this.onJoinedChanged,
    this.onOpenChat,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late bool _isJoined;
  bool _isLoading = true;

  // Real Database Details
  late String _title;
  late String _description;
  late String _category;
  late String _categoryEmoji;
  late String _time;
  late String _location;
  late String _campus;
  late String _cost;
  late int _maxSlots;
  late int _currentSlots;
  late String _hostName;
  late String _hostMajor;
  late String _hostRating;
  late int _hostedCount;
  bool _isHost = false;
  List<Map<String, dynamic>> _roster = [];

  String get _myEmail =>
      AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';

  @override
  void initState() {
    super.initState();
    // Initialize from widget.meetup
    _isJoined = widget.meetup.isJoined;
    _title = widget.meetup.title;
    _description = widget.meetup.description ?? 'Campus meetup for BINUS students.';
    _category = widget.meetup.category;
    _categoryEmoji = widget.meetup.categoryEmoji;
    _time = widget.meetup.time;
    _location = widget.meetup.location;
    _campus = 'Anggrek';
    _cost = widget.meetup.cost ?? 'FREE';
    _maxSlots = widget.meetup.totalSlots;
    _currentSlots = widget.meetup.confirmedCount;
    _hostName = widget.meetup.hostName;
    _hostMajor = widget.meetup.hostMajor;
    _hostRating = '4.9';
    _hostedCount = 1;

    _loadRealEventDetails();
  }

  Future<void> _loadRealEventDetails() async {
    if (widget.meetup.id.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final details = await ApiService.instance.fetchEventDetails(widget.meetup.id, _myEmail);
      if (details != null && mounted) {
        final host = details['host'] as Map? ?? {};
        final rawRoster = details['roster'] as List? ?? [];
        final parsedRoster = rawRoster.map((r) {
          if (r is Map) {
            return {
              'name': r['name']?.toString() ?? 'Binusian',
              'role': (r['role'] ?? 'MEMBER').toString().toUpperCase(),
              'major': r['major']?.toString() ?? 'Student',
              'avatar': r['avatar']?.toString() ?? 'UM',
              'isCurrentUser': r['isCurrentUser'] == true ||
                  (r['name']?.toString().toLowerCase() ==
                      AuthService.instance.currentUser?.name.toLowerCase()),
            };
          }
          return <String, dynamic>{};
        }).toList();

        final maxP = details['maxSlots'] ?? details['maxParticipants'] ?? _maxSlots;
        final curP = details['currentSlots'] ?? parsedRoster.length;
        final isJoinedServer = details['isJoined'] == true;
        final isHostServer = details['isHost'] == true ||
            (host['name']?.toString().toLowerCase() ==
                AuthService.instance.currentUser?.name.toLowerCase());

        setState(() {
          _title = details['title']?.toString() ?? _title;
          _description = details['description']?.toString() ?? _description;
          _category = (details['category'] ?? _category).toString().toLowerCase();
          _categoryEmoji = _getEmojiForCategory(_category);
          _time = details['timeString']?.toString() ?? _time;
          _location = details['location']?.toString() ?? _location;
          _campus = details['campus']?.toString() ?? _campus;
          _cost = details['cost']?.toString() ?? _cost;
          _maxSlots = maxP is int ? maxP : int.tryParse(maxP.toString()) ?? 6;
          _currentSlots = curP is int ? curP : int.tryParse(curP.toString()) ?? 1;
          _hostName = host['name']?.toString() ?? _hostName;
          _hostMajor = host['major']?.toString() ?? host['batch']?.toString() ?? _hostMajor;
          _hostRating = host['rating']?.toString() ?? '4.9';
          _hostedCount = host['hostedCount'] is int
              ? host['hostedCount']
              : int.tryParse(host['hostedCount']?.toString() ?? '1') ?? 1;
          _roster = parsedRoster;
          _isJoined = isJoinedServer || isHostServer;
          _isHost = isHostServer;
          _isLoading = false;
        });
        widget.meetup.isJoined = _isJoined;
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading event details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getEmojiForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'sports':
        return '🏸';
      case 'gaming':
        return '🎮';
      case 'academic':
      case 'study':
        return '📚';
      case 'tech':
        return '💻';
      case 'food':
        return '🍔';
      case 'outdoor':
        return '🏕️';
      default:
        return '🎯';
    }
  }

  void _handleJoinFlow() async {
    if (_isHost) {
      _openSquadChat();
      return;
    }

    if (_isJoined) {
      _openSquadChat();
      return;
    }

    setState(() {
      _isJoined = true;
      widget.meetup.isJoined = true;
      _currentSlots = (_currentSlots + 1).clamp(1, _maxSlots);
    });
    widget.onJoinedChanged?.call();

    if (widget.meetup.id.isNotEmpty) {
      await ApiService.instance.joinEvent(widget.meetup.id, _myEmail);
      await _loadRealEventDetails();
    }
    _showJoinedCelebrationModal();
  }

  void _openSquadChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SquadChatScreen(
          eventId: widget.meetup.id,
          title: _title,
          memberCount: '$_currentSlots/$_maxSlots',
          categoryEmoji: _categoryEmoji,
        ),
      ),
    );
  }

  void _showJoinedCelebrationModal() {
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.statusOpenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration, color: AppColors.statusOpenEmerald, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                "You're in the squad! 🎉",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Spot locked for "$_title". Added to your squads & group chat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _categoryEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$_time • $_location',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openSquadChat();
                },
                child: Text(
                  'Open Squad Chat',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
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
    final spotsRemaining = (_maxSlots - _currentSlots) > 0 ? (_maxSlots - _currentSlots) : 0;
    final progress = (_currentSlots / _maxSlots).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Meetup Details',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh details',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadRealEventDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meetup link copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    // 1. Hero Cover Banner with Tags
                    Stack(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [AppColors.darkSurfaceContainer, AppColors.darkSurfaceCard]
                                  : [AppColors.primary.withOpacity(0.12), AppColors.campusBlue.withOpacity(0.06)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_categoryEmoji, style: const TextStyle(fontSize: 54)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_category.toUpperCase()} MEETUP',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Floating Badges Row
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.darkSurfaceCard : Colors.white).withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'BINUS $_campus Campus',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: spotsRemaining <= 2
                                      ? AppColors.statusTrendingSoft.withOpacity(0.95)
                                      : AppColors.statusOpenLight.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      spotsRemaining <= 2 ? Icons.local_fire_department : Icons.event_seat,
                                      size: 14,
                                      color: spotsRemaining <= 2
                                          ? AppColors.statusTrendingCoral
                                          : AppColors.statusOpenEmerald,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      spotsRemaining == 0 ? 'Full' : '$spotsRemaining spots left',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: spotsRemaining <= 2
                                            ? AppColors.statusTrendingCoral
                                            : AppColors.statusOpenEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & Verified pill
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_categoryEmoji ${_category.toUpperCase()}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.statusOpenLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified, size: 12, color: AppColors.statusOpenEmerald),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Official Campus Meetup',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.statusOpenEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Real Title
                          Text(
                            _title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Real Host Info Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primaryContainer, AppColors.campusBlue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    UserModel.extractInitials(_hostName),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _hostName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _isHost ? 'YOU (HOST)' : 'HOST',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            _hostMajor,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.star_rounded, size: 14, color: AppColors.campusOrange),
                                          const SizedBox(width: 2),
                                          Text(
                                            _hostRating,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.campusOrange,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '· $_hostedCount hosted',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    side: const BorderSide(color: AppColors.primary),
                                  ),
                                  onPressed: _openSquadChat,
                                  icon: const Icon(Icons.forum_outlined, size: 14, color: AppColors.primary),
                                  label: Text(
                                    'Squad Chat',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Bento Grid: Date & Time, Location, Cost
                          _buildBentoItem(
                            icon: Icons.calendar_today_rounded,
                            iconColor: AppColors.primary,
                            title: 'DATE & TIME',
                            value: _time,
                            subtext: 'Campus Schedule Confirmed',
                            isSubtextEmerald: true,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildBentoItem(
                            icon: Icons.location_on_rounded,
                            iconColor: AppColors.campusBlue,
                            title: 'LOCATION',
                            badge: 'BINUS $_campus',
                            value: _location,
                            subtext: 'BINUS University Official Venue',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildBentoItem(
                            icon: Icons.payments_rounded,
                            iconColor: AppColors.campusOrange,
                            title: 'CONTRIBUTION',
                            value: _cost.toUpperCase() == 'FREE' ? 'FREE' : _cost,
                            subtext: _cost.toUpperCase() == 'FREE'
                                ? 'No fees required for campus students'
                                : 'Split equally among participants',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // Real Attendance Progress & Squad Roster
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Squad Roster',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '$_currentSlots / $_maxSlots Spots Confirmed',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: spotsRemaining <= 1
                                            ? AppColors.statusTrendingSoft
                                            : AppColors.statusOpenLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        spotsRemaining == 0 ? 'Full' : '$spotsRemaining left',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: spotsRemaining <= 1
                                              ? AppColors.statusTrendingCoral
                                              : AppColors.statusOpenEmerald,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: isDark
                                        ? AppColors.darkSurfaceContainerLow
                                        : AppColors.surfaceContainerLow,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CONFIRMED MEMBERS (${_roster.isNotEmpty ? _roster.length : _currentSlots})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.outline,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.verified, size: 12, color: AppColors.statusOpenEmerald),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Real Campus Accounts',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.statusOpenEmerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Roster chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // Real users from database
                                    ..._roster.map((p) {
                                      final pName = p['name']?.toString() ?? 'Member';
                                      final pMajor = p['major']?.toString() ?? '';
                                      final pRole = p['role']?.toString() ?? 'MEMBER';
                                      final pAvatar = p['avatar']?.toString() ?? UserModel.extractInitials(pName);
                                      final isPUserHost = pRole == 'HOST';

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isPUserHost
                                              ? AppColors.primary.withOpacity(0.1)
                                              : (isDark
                                                  ? AppColors.darkSurfaceContainerLow
                                                  : AppColors.surfaceContainerLow),
                                          borderRadius: BorderRadius.circular(20),
                                          border: isPUserHost
                                              ? Border.all(color: AppColors.primary.withOpacity(0.3))
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundColor: isPUserHost ? AppColors.primary : AppColors.outline,
                                              child: Text(
                                                pAvatar,
                                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isPUserHost ? '$pName (Host)' : pName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                              ),
                                            ),
                                            if (pMajor.isNotEmpty) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '• $pMajor',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9,
                                                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                    // Open spots
                                    for (int i = 0; i < spotsRemaining; i++)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkSurfaceContainer
                                              : AppColors.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person_add, size: 13, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              i == 0 && !_isJoined ? 'Your Spot?' : 'Open Spot',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Real About the Meetup Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'About the Meetup',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    '#${_category.toUpperCase()}',
                                    '#BINUS$_campus',
                                    '#UniMeetVerified',
                                    '#CampusSocial',
                                  ].map((t) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        t,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Real Guidelines Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.task_alt, size: 18, color: AppColors.statusOpenEmerald),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Campus Guidelines & Safety',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildGuidelineItem(
                                  'BINUS Student Pass Required',
                                  'Bring your active student ID or Flazz pass for campus turnstile check-in.',
                                  isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildGuidelineItem(
                                  'Punctual & Respectful Roster',
                                  'Please arrive on time at $_location to respect fellow squad members.',
                                  isDark,
                                ),
                                const SizedBox(height: 10),
                                _buildGuidelineItem(
                                  'Squad Chat Coordination',
                                  'Coordinate any changes or equipment directly in the squad group chat.',
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Pinned Sticky Bottom RSVP Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurfaceCard : Colors.white).withOpacity(0.96),
                      border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _cost.toUpperCase() == 'FREE' ? 'FREE' : _cost,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      ' / participant',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: spotsRemaining == 0
                                            ? AppColors.statusTrendingCoral
                                            : AppColors.statusOpenEmerald,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      spotsRemaining == 0
                                          ? 'Squad capacity full'
                                          : '$spotsRemaining spots left',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: spotsRemaining == 0
                                            ? AppColors.statusTrendingCoral
                                            : AppColors.statusOpenEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isHost
                                    ? AppColors.accentElectricViolet
                                    : (_isJoined ? AppColors.statusOpenEmerald : AppColors.primary),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 3,
                              ),
                              onPressed: _handleJoinFlow,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isHost
                                            ? Icons.campaign_rounded
                                            : (_isJoined ? Icons.check_circle_rounded : Icons.login_rounded),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isHost
                                            ? 'Hosting • Squad Chat'
                                            : (_isJoined ? 'In Squad • Chat' : 'Join Squad'),
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _isHost
                                        ? 'Host Controls'
                                        : (_isJoined ? 'Spot Confirmed ✓' : 'Instant RSVP'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Instant turnstile digital pass & active squad group chat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                              ),
                            ),
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

  Widget _buildBentoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    required String value,
    required String subtext,
    bool isSubtextEmerald = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.outline,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                ),
                Text(
                  subtext,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSubtextEmerald ? FontWeight.w700 : FontWeight.w500,
                    color: isSubtextEmerald
                        ? AppColors.statusOpenEmerald
                        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String desc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.statusOpenLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: AppColors.statusOpenEmerald),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
