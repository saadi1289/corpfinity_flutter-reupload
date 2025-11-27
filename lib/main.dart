import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/theme/app_theme.dart';
import 'src/models/user.dart';
import 'src/models/app_view.dart';
import 'src/services/auth_service.dart';
import 'src/widgets/app_layout.dart';
import 'src/widgets/bottom_navbar.dart';
import 'src/pages/auth_page.dart';
import 'src/pages/home_page.dart';
import 'src/pages/challenges_page.dart';
import 'src/pages/insights_page.dart';
import 'src/pages/profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimize for high refresh rate displays
  if (!kIsWeb) {
    // Enable high refresh rate on supported devices
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  runApp(
    const ProviderScope(
      child: CorpFinityApp(),
    ),
  );
}

class CorpFinityApp extends StatelessWidget {
  const CorpFinityApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CorpFinity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _authService = AuthService();
  
  User? _user;
  AppView _currentView = AppView.home;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
      _loading = false;
    });
  }
  
  void _handleLogin(User user) {
    setState(() => _user = user);
  }
  
  void _handleUpdateUser(User user) {
    setState(() => _user = user);
  }
  
  Future<void> _handleLogout() async {
    await _authService.logout();
    setState(() {
      _user = null;
      _currentView = AppView.home;
    });
  }
  
  void _handleChangeView(AppView view) {
    setState(() => _currentView = view);
  }
  
  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_loading) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Not authenticated - show auth page
    if (_user == null) {
      return AuthPage(onLogin: _handleLogin);
    }
    
    // Authenticated - show app with bottom navigation
    return AppLayout(
      bottomBar: BottomNavbar(
        currentView: _currentView,
        onChangeView: _handleChangeView,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: _buildCurrentPage(),
      ),
    );
  }
  
  Widget _buildCurrentPage() {
    switch (_currentView) {
      case AppView.home:
        return HomePage(key: const ValueKey('home'), user: _user!);
      case AppView.challenges:
        return const ChallengesPage(key: ValueKey('challenges'));
      case AppView.insights:
        return const InsightsPage(key: ValueKey('insights'));
      case AppView.profile:
        return ProfilePage(
          key: const ValueKey('profile'),
          user: _user!,
          onLogout: _handleLogout,
          onUpdateUser: _handleUpdateUser,
        );
    }
  }
}
