import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/child_profile.dart';
import '../../providers/child_profile_provider.dart';

// Avatar emojis indexed by avatarIndex
const _avatars = ['🦕', '🪆', '🐬', '🐒', '🚀'];
const _avatarColors = [
  AppColors.dinoGreen,
  AppColors.dollPink,
  AppColors.oceanBlue,
  AppColors.jungleGold,
  AppColors.spacePurple,
];

class ProfileSelectScreen extends ConsumerWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(childProfilesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Who\'s playing?',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onLongPress: () => context.go(AppRoutes.parentGate),
              child: Text(
                'Tap your picture!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: profilesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (profiles) => profiles.isEmpty
                    ? _EmptyState(
                        onAddProfile: () =>
                            context.go(AppRoutes.parentGate),
                      )
                    : _ProfileGrid(profiles: profiles),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileGrid extends ConsumerWidget {
  const _ProfileGrid({required this.profiles});
  final List<ChildProfile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, i) => _ProfileCard(
        profile: profiles[i],
        onTap: () {
          ref.read(activeChildProvider.notifier).state = profiles[i];
          context.go(AppRoutes.emotionCheckin);
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});
  final ChildProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idx = profile.avatarIndex.clamp(0, _avatars.length - 1);
    final color = _avatarColors[idx];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _avatars[idx],
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddProfile});
  final VoidCallback onAddProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🌟', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 16),
        Text(
          'No profiles yet!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'A parent needs to set up a profile first.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onAddProfile,
          child: const Text('Parent Setup'),
        ),
      ],
    );
  }
}
