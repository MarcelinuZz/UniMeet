import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/verification_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  runApp(const UniMeetApp());
}

class UniMeetApp extends StatefulWidget {
  const UniMeetApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static UniMeetAppState of(BuildContext context) {
    return context.findAncestorStateOfType<UniMeetAppState>()!;
  }

  @override
  State<UniMeetApp> createState() => UniMeetAppState();
}

class UniMeetAppState extends State<UniMeetApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: UniMeetApp.navigatorKey,
      title: 'UniMeet - Campus Student Network',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      routes: {
        '/': (_) => const _AuthGate(),
        '/home': (_) => const _AuthGate(),
      },
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const _AuthGate()),
      initialRoute: '/',
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final appState = UniMeetApp.of(context);
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService.instance.currentUserNotifier,
      builder: (context, currentUser, _) {
        if (currentUser == null) {
          return const CampusVerificationScreen();
        }
        return MainShell(
          onToggleTheme: appState.toggleTheme,
          isDark: appState.isDarkMode,
        );
      },
    );
  }
}
