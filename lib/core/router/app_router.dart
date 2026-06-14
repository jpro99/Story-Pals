import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/parent/parent_gate_screen.dart';
import '../../screens/parent/parent_dashboard_screen.dart';
import '../../screens/parent/child_profile_setup_screen.dart';
import '../../screens/parent/privacy_policy_screen.dart';
import '../../screens/kid/profile_select_screen.dart';
import '../../screens/kid/chapter_map_screen.dart';
import '../../screens/kid/story_scene_screen.dart';
import '../../screens/kid/puzzle_screen.dart';
import '../../screens/kid/emotion_checkin_screen.dart';

part 'app_router.g.dart';

// Route path constants
class AppRoutes {
  static const String splash = '/';
  static const String parentGate = '/parent-gate';
  static const String parentDashboard = '/parent-dashboard';
  static const String childProfileSetup = '/child-setup';
  static const String privacyPolicy = '/privacy-policy';
  static const String profileSelect = '/profile-select';
  static const String chapterMap = '/chapter-map';
  static const String storyScene = '/story/:chapterId/:sceneId';
  static const String puzzle = '/puzzle/:chapterId/:puzzleIndex';
  static const String emotionCheckin = '/emotion-checkin';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentGate,
        builder: (context, state) => const ParentGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentDashboard,
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.childProfileSetup,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          return ChildProfileSetupScreen(editingChildId: childId);
        },
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSelect,
        builder: (context, state) => const ProfileSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.chapterMap,
        builder: (context, state) => const ChapterMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.storyScene,
        builder: (context, state) => StorySceneScreen(
          chapterId: state.pathParameters['chapterId']!,
          sceneId: state.pathParameters['sceneId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.puzzle,
        builder: (context, state) => PuzzleScreen(
          chapterId: state.pathParameters['chapterId']!,
          puzzleIndex: int.parse(state.pathParameters['puzzleIndex']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.emotionCheckin,
        builder: (context, state) {
          final isPost = state.uri.queryParameters['post'] == 'true';
          return EmotionCheckinScreen(isPostSession: isPost);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
