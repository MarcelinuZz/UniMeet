import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class CampusVerificationScreen extends StatefulWidget {
  final VoidCallback? onVerified;

  const CampusVerificationScreen({super.key, this.onVerified});

  @override
  State<CampusVerificationScreen> createState() => _CampusVerificationScreenState();
}

class _CampusVerificationScreenState extends State<CampusVerificationScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'melvin.goh@binus.ac.id');


  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.statusTrendingCoral,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinuePressed() {
    final emailInput = _emailController.text.trim();

    if (emailInput.isEmpty) {
      _showWarning('Please enter your campus email address.');
      return;
    }

    final fullEmail = emailInput.contains('@')
        ? emailInput.toLowerCase()
        : '$emailInput@binus.ac.id'.toLowerCase();

    _showOtpBottomSheet(fullEmail);
  }

  void _showOtpBottomSheet(String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OtpPopupSheet(
        email: email,
        isDark: isDark,
        onVerified: () {
          Navigator.of(ctx).pop();
          if (widget.onVerified != null) {
            widget.onVerified!();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo in the Middle Top
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logos/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primary,
                        alignment: Alignment.center,
                        child: const Icon(Icons.school, color: Colors.white, size: 52),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'UniMeet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Campus Student Network',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Container Card (Only Email Needed)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Account Switcher for the 2 real accounts
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _emailController.text = 'melvin.goh@binus.ac.id';
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _emailController.text.contains('melvin')
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkSurfaceContainerLow
                                            : AppColors.surfaceContainerLow),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _emailController.text.contains('melvin')
                                          ? AppColors.primary
                                          : (isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Melvin Goh',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _emailController.text.contains('melvin')
                                          ? Colors.white
                                          : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _emailController.text = 'marcelinus.oey@binus.ac.id';
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _emailController.text.contains('marcelinus')
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkSurfaceContainerLow
                                            : AppColors.surfaceContainerLow),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _emailController.text.contains('marcelinus')
                                          ? AppColors.primary
                                          : (isDark ? AppColors.darkBorder : AppColors.surfaceBorder),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Marcelinus Oey',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _emailController.text.contains('marcelinus')
                                          ? Colors.white
                                          : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Campus Email Field (Only field required)
                        Row(
                          children: [
                            Text(
                              'Campus Email',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '*',
                              style: TextStyle(
                                color: AppColors.statusTrendingCoral,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerLow
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alternate_email_rounded,
                                  size: 20, color: AppColors.outline),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. melvin.goh@binus.ac.id',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.darkOnSurfaceVariant.withOpacity(0.6)
                                          : AppColors.outline,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _onContinuePressed(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _onContinuePressed,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// OTP VERIFICATION POPUP MODAL
// ==========================================
class _OtpPopupSheet extends StatefulWidget {
  final String email;
  final bool isDark;
  final VoidCallback onVerified;

  const _OtpPopupSheet({
    required this.email,
    required this.isDark,
    required this.onVerified,
  });

  @override
  State<_OtpPopupSheet> createState() => _OtpPopupSheetState();
}

class _OtpPopupSheetState extends State<_OtpPopupSheet> {
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  int _countdownSeconds = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first digit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownSeconds = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentPin => _pinControllers.map((c) => c.text).join();

  void _quickFillDemoPin() {
    const demoPin = '882041';
    for (int i = 0; i < 6; i++) {
      _pinControllers[i].text = demoPin[i];
    }
    setState(() {});
    _verifyCode();
  }

  Future<void> _verifyCode() async {
    final code = _currentPin;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.statusTrendingCoral,
          behavior: SnackBarBehavior.floating,
          content: Text('Please enter all 6 digits of the OTP code.'),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Complete student login by email
      await AuthService.instance.loginOrCreateAccount(
        email: widget.email,
      );

      widget.onVerified();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusTrendingCoral,
            content: Text('Verification failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 20),

          // Header Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Enter Verification Code',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'We sent a 6-digit code to\n${widget.email}',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Auto-fill Demo Chip
          InkWell(
            onTap: _quickFillDemoPin,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryFixed),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to auto-fill demo OTP (882041)',
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

          const SizedBox(height: 22),

          // 6-Digit PIN Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 46,
                height: 52,
                child: TextField(
                  controller: _pinControllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainerLow
                        : AppColors.surfaceContainerLow,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.surfaceBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (_currentPin.length == 6) {
                      _verifyCode();
                    }
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Resend Timer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive code? ",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.outline,
                ),
              ),
              _countdownSeconds > 0
                  ? Text(
                      'Resend in ${_countdownSeconds}s',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        _startTimer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New verification code sent! (Use 882041)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'Resend Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ],
          ),

          const SizedBox(height: 24),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 1,
              ),
              onPressed: _isVerifying ? null : _verifyCode,
              child: _isVerifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Verify & Enter UniMeet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
