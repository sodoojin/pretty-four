import 'package:go_router/go_router.dart';
import '../screens/intro/intro_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/main/main_scaffold.dart';
import '../screens/recording/recording_screen.dart';
import '../screens/processing/processing_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/children/children_screen.dart';
import '../services/child_service.dart';
import 'auth_notifier.dart';

final router = GoRouter(
  initialLocation: '/login',
  refreshListenable: authNotifier,
  redirect: (context, state) async {
    if (!authNotifier.initialized) return null;

    final isLoggedIn = authNotifier.isLoggedIn;
    final loc = state.matchedLocation;

    if (!isLoggedIn) {
      // 최초 1회 인트로 노출
      if (!authNotifier.introSeen) {
        return loc == '/intro' ? null : '/intro';
      }
      // 인트로를 본 미로그인 사용자는 로그인으로
      return loc == '/login' ? null : '/login';
    }

    if (loc == '/login' || loc == '/profile-setup' || loc == '/intro') {
      try {
        final child = await ChildService().getCurrentChild();
        if (child == null) return loc == '/profile-setup' ? null : '/profile-setup';
        return '/home';
      } catch (_) {
        return loc == '/profile-setup' ? null : '/profile-setup';
      }
    }

    return null;
  },
  routes: [
    GoRoute(path: '/intro', builder: (_, __) => const IntroScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(path: '/home', builder: (_, __) => const MainScaffold()),
    GoRoute(path: '/recording', builder: (_, __) => const RecordingScreen()),
    GoRoute(
      path: '/processing/:sessionId',
      builder: (_, state) =>
          ProcessingScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      path: '/result/:sessionId',
      builder: (_, state) =>
          ResultScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/children', builder: (_, __) => const ChildrenScreen()),
  ],
);
