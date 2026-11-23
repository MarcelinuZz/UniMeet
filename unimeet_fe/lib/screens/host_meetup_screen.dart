import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class HostMeetupScreen extends StatefulWidget {
  const HostMeetupScreen({super.key});

  @override
  State<HostMeetupScreen> createState() => _HostMeetupScreenState();
}

class _HostMeetupScreenState extends State<HostMeetupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedCategory = 'Academic';
  int _capacity = 8;
  bool _allowWaitlist = true;
  bool _campusOnly = true;
  bool _isPublishing = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 16, minute: 0);
  int _durationMinutes = 120;
  final List<int> _durationPresets = [30, 60, 90, 120, 180, 240];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': AppColors.campusBlue},
    {'name': 'Academic', 'icon': Icons.menu_book, 'color': AppColors.primary},
    {'name': 'Hangout', 'icon': Icons.ramen_dining, 'color': AppColors.campusOrange},
    {'name': 'Gaming', 'icon': Icons.sports_esports, 'color': AppColors.accentElectricViolet},
    {'name': 'Creative', 'icon': Icons.palette, 'color': AppColors.statusTrendingCoral},
    {'name': 'Outdoor', 'icon': Icons.park, 'color': AppColors.tertiary},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    final base = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    if (diff == 0) return 'Today, $base';
    if (diff == 1) return 'Tomorrow, $base';
    return base;
  }

  String _getDateSubtitle(DateTime dt, TimeOfDay time) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[dt.weekday - 1];
    String period = 'Morning';
    if (time.hour >= 12 && time.hour < 15) {
      period = 'Afternoon';
    } else if (time.hour >= 15 && time.hour < 18) {
      period = 'Late Afternoon';
    } else if (time.hour >= 18) {
      period = 'Evening';
    }
    return '$dayName $period';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _calculateEndTime(TimeOfDay start, int durationMins) {
    final startTotal = start.hour * 60 + start.minute;
    final endTotal = (startTotal + durationMins) % (24 * 60);
    return TimeOfDay(hour: endTotal ~/ 60, minute: endTotal % 60);
  }

  String _formatDurationLabel(int mins) {
    if (mins < 60) return '$mins Mins meetup';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    if (rem == 0) {
      return '$hrs ${hrs == 1 ? 'Hour' : 'Hours'} meetup';
    }
    return '$hrs.5 Hours meetup';
  }

  String _durationChipLabel(int mins) {
    if (mins < 60) return '${mins}m';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    if (rem == 0) return '${hrs}h';
    return '$hrs.5h';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate.isBefore(now) ? now : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
      });
    }
  }

  void _handlePublish() async {
    setState(() {
      _isPublishing = true;
    });

    final hostEmail =
        AuthService.instance.currentUser?.email.toLowerCase() ?? 'melvin.goh@binus.ac.id';

    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedStartTime.hour,
      _selectedStartTime.minute,
    );
    final endTime = _calculateEndTime(_selectedStartTime, _durationMinutes);
    final timeString = '${_formatTimeOfDay(_selectedStartTime)} - ${_formatTimeOfDay(endTime)} WIB';

    await ApiService.instance.createEvent(
      hostEmail: hostEmail,
      title: _titleController.text.trim().isEmpty ? 'Campus Meetup' : _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? 'Join us for this campus meetup! Let\'s connect and collaborate.'
          : _descController.text.trim(),
      category: _selectedCategory,
      dateTime: eventDateTime,
      timeString: timeString,
      location: _locationController.text.trim().isEmpty
          ? 'BINUS Anggrek Campus'
          : _locationController.text.trim(),
      campus: AuthService.instance.currentUser?.campus ?? 'BINUS Anggrek Campus',
      cost: 'Free',
      maxParticipants: _capacity,
      vibe: 'Friendly & Casual',
    );

    if (!mounted) return;
    setState(() {
      _isPublishing = false;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusOpenEmerald, size: 28),
            const SizedBox(width: 8),
            Text(
              'Meetup Published!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Your campus meetup "${_titleController.text.isEmpty ? 'Study Squad' : _titleController.text}" is now live on the Anggrek Campus Discover Feed! Classmates can now RSVP.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'View on Feed',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Host Meetup',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ValueListenableBuilder<UserModel?>(
              valueListenable: AuthService.instance.currentUserNotifier,
              builder: (context, user, _) {
                final avatarProvider = UserModel.getAvatarImageProvider(user?.avatarUrl);
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  backgroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? Text(
                          user?.avatarInitials ?? 'ME',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Host a Campus Meetup',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Fill in meetup details and preferences',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.rocket_launch, color: AppColors.primary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Activity Title Card
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Activity Title',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_titleController.text.length}/60',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _titleController,
                      maxLength: 60,
                      onChanged: (val) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g., Chill Study Session or Futsal Friendly',
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates, size: 14, color: AppColors.statusOpenEmerald),
                      const SizedBox(width: 4),
                      Text(
                        'Pro-tip: Clear, casual titles fill spots 40% faster!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusOpenEmerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Category Selector Grid
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Category',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Required',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat['name'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['name'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 20,
                                color: isSelected ? Colors.white : (cat['color'] as Color),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Date & Time Picker Cards
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Schedule & Duration',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tap cards to change',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.event, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Date',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.edit_calendar, size: 13, color: AppColors.primary),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(_selectedDate),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    _getDateSubtitle(_selectedDate, _selectedStartTime),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.statusOpenEmerald.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule, size: 14, color: AppColors.statusOpenEmerald),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Start Time',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.access_time, size: 13, color: AppColors.statusOpenEmerald),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatTimeOfDay(_selectedStartTime)} - ${_formatTimeOfDay(_calculateEndTime(_selectedStartTime, _durationMinutes))}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    _formatDurationLabel(_durationMinutes),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusOpenEmerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Duration Presets
                  Row(
                    children: [
                      Text(
                        'Duration:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _durationPresets.map((mins) {
                              final isSel = _durationMinutes == mins;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(
                                    _durationChipLabel(mins),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      color: isSel
                                          ? Colors.white
                                          : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: isDark
                                      ? AppColors.darkSurfaceContainerLow
                                      : AppColors.surfaceContainerLow,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        _durationMinutes = mins;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Meeting Point Input
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Meeting Point',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Where should everyone meet up?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter meeting point or venue...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Capacity Stepper & Waitlist
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.group, size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Roster Size',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Recommended 6-10 for engagement',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _capacity > 2 ? () => setState(() => _capacity--) : null,
                            ),
                            SizedBox(
                              width: 48,
                              child: Column(
                                children: [
                                  Text(
                                    '$_capacity',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'Students',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _capacity < 40 ? () => setState(() => _capacity++) : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Waitlist Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.statusOpenLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_top, size: 18, color: AppColors.statusOpenEmerald),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Allow waitlist when full',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Auto-promote when an RSVP cancels',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _allowWaitlist,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _allowWaitlist = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. Meetup Details Textarea
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Meetup Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'What should attendees know or bring along?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _descController,
                      maxLines: 4,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Share what you will be doing, expectations, and any materials or tools needed...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 7. Security / Verified Campus Toggle
            _buildCardWrapper(
              isDark: isDark,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Campus Only',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Only students with authenticated @binus.ac.id IDs can RSVP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _campusOnly,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _campusOnly = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Co-Host Preview Snip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withOpacity(isDark ? 0.3 : 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ValueListenableBuilder<UserModel?>(
                    valueListenable: AuthService.instance.currentUserNotifier,
                    builder: (context, user, _) {
                      final avatarProvider = UserModel.getAvatarImageProvider(user?.avatarUrl);
                      return Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            backgroundImage: avatarProvider,
                            child: avatarProvider == null
                                ? Text(
                                    user?.avatarInitials ?? 'ME',
                                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(Icons.check_circle, color: AppColors.statusOpenEmerald, size: 14),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'You (Host)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.campusBlue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "CS '25",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.campusBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Host reputation score: 4.9 ★ (12 meetups hosted)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: _isPublishing ? null : _handlePublish,
              child: _isPublishing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue to Review & Publish',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved to drafts!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.bookmark_add_outlined, size: 18, color: AppColors.outline),
              label: Text(
                'Save as Draft',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}
