import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/meetup_model.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/image_picker_service.dart';
import 'squad_chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;

  const ProfileScreen({
    super.key,
    this.onToggleTheme,
    this.isDark = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Past, 2: Preferences
  bool _pushNotifications = true;

  List<dynamic> _upcomingEvents = [];
  List<dynamic> _pastEvents = [];
  bool _isLoadingEvents = true;

  String? _selectedAvatarUrl;
  String? _uploadedFileName;
  int? _uploadedFileSize;
  String? _selectedCampus;
  String? _selectedMajor;
  bool _isSavingProfile = false;
  final TextEditingController _customUrlController = TextEditingController();
  final TextEditingController _customDegreeController = TextEditingController();

  static const List<String> _binusCampuses = [
    'BINUS Anggrek Campus',
    'BINUS Syahdan Campus',
    'BINUS Kijang Campus',
    'BINUS Alam Sutera Campus',
    'BINUS Bekasi Campus',
    'BINUS Senayan Campus',
    'BINUS Bandung Campus',
    'BINUS Malang Campus',
    'BINUS Semarang Campus',
  ];

  static const List<String> _binusMajors = [
    'Computer Science',
    'Cyber Security',
    'Data Science',
    'Artificial Intelligence',
    'Information Systems',
    'Business Information Technology',
    'Interactive Design & Technology',
    'Mobile Application & Technology',
    'Game Application & Technology',
    'Software Engineering',
    'Accounting & Finance',
    'International Business & Management',
    'Digital Communication & Media',
  ];

  @override
  void initState() {
    super.initState();
    _loadRealSchedules();
    final u = AuthService.instance.currentUser;
    _selectedAvatarUrl = u?.avatarUrl;
    _selectedCampus = u?.campus ?? 'BINUS Anggrek Campus';
    _selectedMajor = u?.major ?? 'Computer Science';
    AuthService.instance.syncProfileFromBackend().then((_) {
      if (mounted) {
        final synced = AuthService.instance.currentUser;
        if (synced != null) {
          setState(() {
            _selectedAvatarUrl = synced.avatarUrl ?? _selectedAvatarUrl;
            _selectedCampus = synced.campus;
            _selectedMajor = synced.major;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    _customDegreeController.dispose();
    super.dispose();
  }

  Future<void> _loadRealSchedules() async {
    final email = AuthService.instance.currentUser?.email.toLowerCase() ??
        'melvin.goh@binus.ac.id';
    try {
      final res = await ApiService.instance.fetchMySchedules(email);
      if (mounted) {
        setState(() {
          _upcomingEvents = res['upcoming'] as List? ?? [];
          _pastEvents = res['past'] as List? ?? [];
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  final List<Map<String, String>> _badges = [
    {'emoji': '🏸', 'text': 'Badminton Enthusiast'},
    {'emoji': '☕', 'text': 'Cafe Hopper'},
    {'emoji': '💻', 'text': 'UI/UX & Web Dev'},
    {'emoji': '🎮', 'text': 'Valorant Gamer'},
    {'emoji': '📚', 'text': 'Late Night Crammer'},
    {'emoji': '🍕', 'text': 'Pizza Fan'},
  ];

  final List<Map<String, String>> _extraBadges = [
    {'emoji': '🎨', 'text': 'Figma Wizard'},
    {'emoji': '🏃', 'text': '5K Morning Runner'},
    {'emoji': '🍜', 'text': 'Ramen Hunter'},
    {'emoji': '🎸', 'text': 'Acoustic Jam'},
  ];
  int _extraIndex = 0;

  void _addMoreBadge() {
    if (_extraIndex < _extraBadges.length) {
      setState(() {
        _badges.add(_extraBadges[_extraIndex]);
        _extraIndex++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All campus roles already added!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmLogout(BuildContext context, UserModel? user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.statusTrendingCoral, size: 24),
            const SizedBox(width: 8),
            Text(
              'Log Out of UniMeet?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'You will be signed out from ${user?.email ?? 'your campus account'}. You can sign back in anytime with your campus email.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusTrendingCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.instance.logout();
              UniMeetApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatarFile() async {
    try {
      final picked = await pickImageFromDevice();
      if (picked != null) {
        setState(() {
          _selectedAvatarUrl = picked.dataUrl;
          _uploadedFileName = picked.name;
          _uploadedFileSize = picked.size;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _openCampusSelectorSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Active Campus',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _binusCampuses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final campus = _binusCampuses[idx];
                    final isSelected = _selectedCampus == campus;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Icon(
                        Icons.account_balance_rounded,
                        color: isSelected ? AppColors.primary : AppColors.outline,
                        size: 20,
                      ),
                      title: Text(
                        campus,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedCampus = campus);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMajorSelectorSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Active Degree / Major',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customDegreeController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Or enter custom degree...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final text = _customDegreeController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() => _selectedMajor = text);
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Text('Set'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: _binusMajors.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final major = _binusMajors[idx];
                    final isSelected = _selectedMajor == major;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Icon(
                        Icons.school_rounded,
                        color: isSelected ? AppColors.primary : AppColors.outline,
                        size: 20,
                      ),
                      title: Text(
                        major,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedMajor = major);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfileSettings() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    setState(() => _isSavingProfile = true);

    final campusToSave = _selectedCampus ?? user.campus;
    final majorToSave = _selectedMajor ?? user.major;
    final avatarToSave = _selectedAvatarUrl;

    try {
      final res = await ApiService.instance.updateProfile(
        email: user.email,
        userId: user.id,
        campus: campusToSave,
        major: majorToSave,
        avatarUrl: avatarToSave,
      );

      if (res == null) {
        throw Exception('Server failed to update profile.');
      }

      final updated = user.copyWith(
        campus: campusToSave,
        major: majorToSave,
        avatarUrl: avatarToSave,
      );
      await AuthService.instance.updateActiveUser(updated);

      if (mounted) {
        setState(() => _isSavingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile settings saved! Others will now see your updated profile picture, campus, and degree.',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.statusOpenEmerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AppColors.statusTrendingCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Profile',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              setState(() => _selectedTab = 2);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.statusTrendingCoral),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context, AuthService.instance.currentUser),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // 1. Profile Visual Card & Core Info
          ValueListenableBuilder<UserModel?>(
            valueListenable: AuthService.instance.currentUserNotifier,
            builder: (context, user, _) {
              final displayName = user?.name ?? 'Binusian Student';
              final displayEmail = user?.email ?? 'student@binus.ac.id';
              final displayMajor = user != null
                  ? '${user.major} \'${user.batch.length >= 2 ? user.batch.substring(user.batch.length - 2) : '24'}'
                  : 'Computer Science \'25';
              final displayCampus = user?.campus ?? 'BINUS Anggrek Campus';
              final displayInitials = user?.avatarInitials ?? UserModel.extractInitials(displayName);
              final meetupsJoined = user?.meetupsJoined.toString() ?? '1';
              final hostedCount = user?.hostedCount.toString() ?? '0';
              final karma = user?.karma.toStringAsFixed(1) ?? '5.0';

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _pickAvatarFile,
                            child: Stack(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primaryContainer, AppColors.campusBlue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    image: UserModel.getAvatarImageProvider(user?.avatarUrl) != null
                                        ? DecorationImage(
                                            image: UserModel.getAvatarImageProvider(user!.avatarUrl)!,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withAlpha(60),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: UserModel.getAvatarImageProvider(user?.avatarUrl) == null
                                      ? Text(
                                          displayInitials,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusOpenLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified, size: 12, color: AppColors.campusBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified Student Account',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.campusBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.terminal, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        displayMajor,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 13, color: AppColors.outline),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        displayCampus,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.outline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        displayEmail,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Micro-stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(meetupsJoined, Icons.groups, AppColors.primary, 'Meetups Joined', isDark),
                            Container(width: 1, height: 28, color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
                            _buildStatItem(hostedCount, Icons.campaign, AppColors.accentElectricViolet, 'Hosted', isDark),
                            Container(width: 1, height: 28, color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
                            _buildStatItem(karma, Icons.star, AppColors.statusOpenEmerald, 'Karma (Reliable)', isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Interest & Squad Badges
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.interests, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Interest & Squad Badges',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_badges.length} Active',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._badges.map((b) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(b['emoji']!, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                              b['text']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    InkWell(
                      onTap: _addMoreBadge,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '+ Add Role',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Segmented Tab Bar Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'Upcoming (${_upcomingEvents.length})', isDark),
                  _buildTabButton(1, 'Past (${_pastEvents.length})', isDark),
                  _buildTabButton(2, 'Settings', isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Tab Content
          if (_selectedTab == 0) ...[
            if (_isLoadingEvents)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_upcomingEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.event_available_outlined, color: AppColors.outline, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'No upcoming meetups scheduled',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explore events on Discover or host your own meetup!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._upcomingEvents.map((ev) {
                final isHost = (ev['role'] ?? '').toString().toUpperCase() == 'HOST';
                final ticket = ev['ticketCode']?.toString() ?? '';
                final title = ev['title']?.toString() ?? 'Campus Meetup';
                final location = ev['location']?.toString() ?? 'BINUS Campus';
                final time = MeetupItem.formatRelativeTime(ev['dateTime'], ev['timeString']?.toString());
                final eventId = ev['id']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isHost ? AppColors.accentElectricViolet : AppColors.statusOpenEmerald,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isHost ? AppColors.accentElectricViolet : AppColors.statusOpenEmerald)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isHost ? '👑 HOST' : 'JOINED',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isHost ? AppColors.accentElectricViolet : AppColors.statusOpenEmerald,
                                      ),
                                    ),
                                  ),
                                  if (ticket.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.qr_code_2, size: 12, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            ticket,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.outline),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => SquadChatScreen(
                                            eventId: eventId,
                                            title: title,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                                    label: Text(
                                      'Open Squad Chat',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ] else if (_selectedTab == 1) ...[
            if (_pastEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.history_rounded, color: AppColors.outline, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'No past meetups completed yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._pastEvents.map((ev) {
                final title = ev['title']?.toString() ?? 'Past Event';
                final time = MeetupItem.formatRelativeTime(ev['dateTime'], ev['timeString']?.toString());
                final location = ev['location']?.toString() ?? 'BINUS';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                            ),
                            Text(
                              '$time • $location',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Completed',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ] else ...[
            // 1. Profile & Campus Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ValueListenableBuilder<UserModel?>(
                valueListenable: AuthService.instance.currentUserNotifier,
                builder: (context, user, _) {
                  final currentAvatar = _selectedAvatarUrl ?? user?.avatarUrl;
                  final currentCampus = _selectedCampus ?? user?.campus ?? 'BINUS Anggrek Campus';
                  final currentMajor = _selectedMajor ?? user?.major ?? 'Computer Science';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Profile & Campus Settings',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your photo, campus, and degree so other Binusians can recognize you in meetups and squad chats.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Profile Picture Section
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Profile Picture',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (currentAvatar != null && currentAvatar.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedAvatarUrl = null;
                                          _uploadedFileName = null;
                                          _uploadedFileSize = null;
                                        });
                                      },
                                      child: Text(
                                        'Reset to Initials',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.statusTrendingCoral,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Drop file to upload box
                              GestureDetector(
                                onTap: _pickAvatarFile,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: currentAvatar != null
                                          ? AppColors.primary
                                          : (isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (currentAvatar != null && currentAvatar.isNotEmpty) ...[
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                  image: UserModel.getAvatarImageProvider(currentAvatar)!,
                                                  fit: BoxFit.cover,
                                                ),
                                                border: Border.all(color: AppColors.primary, width: 2),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _uploadedFileName ?? 'Custom Photo Selected',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_uploadedFileSize != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(_uploadedFileSize! / 1024).toStringAsFixed(1)} KB',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Change File',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 24),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Drop file to upload or browse',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Supports PNG, JPG, or WEBP',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Or Image URL input
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _customUrlController,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'Or enter image URL (https://...)',
                                        hintStyle: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        filled: true,
                                        fillColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      final text = _customUrlController.text.trim();
                                      if (text.isNotEmpty) {
                                        setState(() {
                                          _selectedAvatarUrl = text;
                                          _uploadedFileName = 'URL Image';
                                          _uploadedFileSize = null;
                                        });
                                      }
                                    },
                                    child: const Text('Apply'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Active Campus Section
                        InkWell(
                          onTap: () => _openCampusSelectorSheet(context, isDark),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
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
                                    color: AppColors.primaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_rounded, size: 18, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Campus',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentCampus,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
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
                                    color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Change',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Active Degree / Major Section
                        InkWell(
                          onTap: () => _openMajorSelectorSheet(context, isDark),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
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
                                    color: AppColors.secondaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.school_rounded, size: 18, color: AppColors.onSecondaryContainer),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Degree / Major',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentMajor,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
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
                                    color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Change',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Save Settings Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            onPressed: _isSavingProfile ? null : _saveProfileSettings,
                            icon: _isSavingProfile
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.cloud_upload_rounded, size: 20),
                            label: Text(
                              _isSavingProfile ? 'Saving...' : 'Save',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // 2. Account & Safety Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Account & Safety Settings',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dark Theme Switch
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDark ? Icons.light_mode : Icons.dark_mode,
                                  size: 18,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dark Theme',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Switch contrast mode',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: isDark,
                            activeColor: AppColors.primary,
                            onChanged: (_) => widget.onToggleTheme?.call(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // User Session & Verification Details
                    ValueListenableBuilder<UserModel?>(
                      valueListenable: AuthService.instance.currentUserNotifier,
                      builder: (context, user, _) {
                        final email = user?.email ?? 'student@binus.ac.id';
                        final nim = user?.nim ?? '2602194831';
                        final campus = user?.campus ?? 'BINUS Anggrek Campus';

                        return Column(
                          children: [
                            // Campus Email Verified
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: AppColors.statusOpenLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.mark_email_read, size: 18, color: AppColors.statusOpenEmerald),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Campus Email Verified',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check_circle, size: 14, color: AppColors.statusOpenEmerald),
                                          ],
                                        ),
                                        Text(
                                          email,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'NIM: $nim • $campus',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.campusBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Push Notifications
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryFixed,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.notifications_active, size: 18, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Push Reminders',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                            ),
                                          ),
                                          Text(
                                            'Alert 1 hour before meetups',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _pushNotifications,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) => setState(() => _pushNotifications = val),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Campus Safety Banner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.statusTrendingSoft.withOpacity(isDark ? 0.3 : 0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: AppColors.statusTrendingSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.health_and_safety, size: 18, color: AppColors.statusTrendingCoral),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Campus Security & Safety',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Anti-harassment code, safe-zone meetups & 24/7 campus security hotline.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.statusTrendingCoral),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Log Out Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.statusTrendingCoral,
                                  side: BorderSide(
                                    color: AppColors.statusTrendingCoral.withOpacity(0.6),
                                    width: 1.5,
                                  ),
                                  backgroundColor: AppColors.statusTrendingCoral.withOpacity(0.06),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _confirmLogout(context, user),
                                icon: const Icon(Icons.logout_rounded, size: 20),
                                label: Text(
                                  'Log Out of Account (${user?.name ?? 'Student'})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, IconData icon, Color color, String label, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              val,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Icon(icon, size: 16, color: color),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int idx, String title, bool isDark) {
    final isSelected = _selectedTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = idx),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceCard : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline),
            ),
          ),
        ),
      ),
    );
  }
}
