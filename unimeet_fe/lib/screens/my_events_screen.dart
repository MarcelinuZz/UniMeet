import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/meetup_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'squad_chat_screen.dart';
import 'event_details_screen.dart';
import 'host_meetup_screen.dart';

class MyEventsScreen extends StatefulWidget {
  final VoidCallback? onOpenDiscover;
  final VoidCallback? onHostMeetup;

  const MyEventsScreen({
    super.key,
    this.onOpenDiscover,
    this.onHostMeetup,
  });

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<MeetupItem> _allMyEvents = [];
  Map<String, dynamic> _schedulesData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final myEmail = AuthService.instance.currentUser?.email.toLowerCase() ??
        'melvin.goh@binus.ac.id';

    try {
      final futures = await Future.wait([
        ApiService.instance.fetchEvents(currentUserEmail: myEmail),
        ApiService.instance.fetchMySchedules(myEmail),
      ]);

      final allEvents = futures[0] as List<MeetupItem>;
      final schedules = futures[1] as Map<String, dynamic>;

      // Filter events where user is joined or host
      final myEvents = allEvents.where((e) {
        final isHost = e.hostName.toLowerCase().contains(
                  AuthService.instance.currentUser?.name.toLowerCase() ?? 'melvin',
                ) ||
            e.isJoined;
        return isHost || e.isJoined;
      }).toList();

      if (mounted) {
        setState(() {
          _allMyEvents = myEvents;
          _schedulesData = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading my events: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _findTicketCode(String eventId) {
    final upcoming = _schedulesData['upcoming'] as List? ?? [];
    for (final u in upcoming) {
      if (u is Map && u['id'] == eventId) {
        return u['ticketCode']?.toString() ?? 'CONFIRMED';
      }
    }
    final past = _schedulesData['past'] as List? ?? [];
    for (final p in past) {
      if (p is Map && p['id'] == eventId) {
        return p['ticketCode']?.toString() ?? 'COMPLETED';
      }
    }
    return '';
  }

  bool _isCurrentUserHost(MeetupItem event) {
    final currentName = AuthService.instance.currentUser?.name.toLowerCase() ?? '';
    final currentEmail = AuthService.instance.currentUser?.email.toLowerCase() ?? '';
    if (currentEmail.contains('melvin') && event.hostName.toLowerCase().contains('melvin')) {
      return true;
    }
    if (currentEmail.contains('marcelinus') && event.hostName.toLowerCase().contains('marcelinus')) {
      return true;
    }
    return currentName.isNotEmpty && event.hostName.toLowerCase().contains(currentName);
  }

  void _openEventDetails(MeetupItem event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(meetup: event),
      ),
    );
  }

  void _openSquadChat(MeetupItem event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SquadChatScreen(
          eventId: event.id,
          title: event.title,
          memberCount: '${event.confirmedCount}/${event.totalSlots}',
          categoryEmoji: event.categoryEmoji,
        ),
      ),
    );
  }

  void _handleHostNew() {
    if (widget.onHostMeetup != null) {
      widget.onHostMeetup!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HostMeetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hostedEvents = _allMyEvents.where(_isCurrentUserHost).toList();
    final joinedEvents = _allMyEvents.where((e) => !_isCurrentUserHost(e)).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'My Events & Passes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Events',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadEvents();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: _handleHostNew,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Host',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('All Events'),
                  const SizedBox(width: 6),
                  _buildCountBadge(_allMyEvents.length, AppColors.primary),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Joined'),
                  const SizedBox(width: 6),
                  _buildCountBadge(joinedEvents.length, AppColors.statusOpenEmerald),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hosted by Me'),
                  const SizedBox(width: 6),
                  _buildCountBadge(hostedEvents.length, AppColors.accentElectricViolet),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(_allMyEvents, isDark, 'No events found in your campus schedule.'),
                  _buildEventList(joinedEvents, isDark, 'You haven\'t joined any events yet.'),
                  _buildEventList(hostedEvents, isDark, 'You haven\'t hosted any events yet.'),
                ],
              ),
            ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEventList(List<MeetupItem> events, bool isDark, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Events in Schedule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onOpenDiscover != null) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: widget.onOpenDiscover,
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: Text(
                        'Discover Events',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: _handleHostNew,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Host Meetup',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isHost = _isCurrentUserHost(event);
        final ticketCode = _findTicketCode(event.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Color Ribbon
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: isHost ? AppColors.accentElectricViolet : AppColors.statusOpenEmerald,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(event.categoryEmoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                event.category.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Role Pill (Host vs Joined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isHost ? AppColors.accentElectricViolet : AppColors.statusOpenEmerald)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHost ? Icons.campaign_rounded : Icons.check_circle_rounded,
                                size: 13,
                                color: isHost ? AppColors.accentElectricViolet : AppColors.statusOpenEmerald,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isHost ? 'HOST' : 'JOINED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isHost ? AppColors.accentElectricViolet : AppColors.statusOpenEmerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    InkWell(
                      onTap: () => _openEventDetails(event),
                      child: Text(
                        event.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          event.time,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location & Campus
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.outline),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${event.location} • BINUS Campus',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Digital Turnstile / Ticket Code Card
                    if (ticketCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CAMPUS TURNSTILE PASS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    Text(
                                      ticketCode,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.statusOpenEmerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusOpenEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Actions Row: Open Squad Chat & View Details
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              side: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => _openEventDetails(event),
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: Text(
                              'Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => _openSquadChat(event),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            label: Text(
                              'Squad Chat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
