import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.headlineMedium;
    final body = Theme.of(context).textTheme.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Story Pals Privacy Policy', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Text('Last updated: May 2026', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('Our Commitment', style: heading),
        const SizedBox(height: 8),
        Text(
          'Story Pals is designed for children ages 2–8 and their families. '
          'We take privacy seriously and comply with the Children\'s Online '
          'Privacy Protection Act (COPPA).',
          style: body,
        ),
        const SizedBox(height: 20),
        Text('What We Collect', style: heading),
        const SizedBox(height: 8),
        Text(
          '• By default, all play data (progress, emotions check-ins, session records) '
          'is stored ONLY on this device.\n'
          '• We do NOT collect personal information from children.\n'
          '• If a parent creates an account and opts in to cloud sync, a parent email '
          'address is stored securely. Child data synced to the cloud is tied to the '
          'parent account and is never shared.\n'
          '• We do NOT collect location data, device identifiers, or behavioral data '
          'beyond what is needed for the app to function.',
          style: body,
        ),
        const SizedBox(height: 20),
        Text('No Ads. No Social Features.', style: heading),
        const SizedBox(height: 8),
        Text(
          'Story Pals contains no advertising of any kind. There are no chat features, '
          'no social feeds, no user-generated content visible to children.',
          style: body,
        ),
        const SizedBox(height: 20),
        Text('AI and Story Generation', style: heading),
        const SizedBox(height: 8),
        Text(
          'All stories in Story Pals are pre-written by our team. No AI or external '
          'language model is used in the child-facing experience. Story content does '
          'not change based on child behavior and is not personalized.',
          style: body,
        ),
        const SizedBox(height: 20),
        Text('Parental Controls', style: heading),
        const SizedBox(height: 8),
        Text(
          'Parents can view and delete all data stored on this device at any time '
          'from the Parent Dashboard. If cloud sync is enabled, you can request '
          'complete data deletion by contacting us at privacy@storypals.app.',
          style: body,
        ),
        const SizedBox(height: 20),
        Text('Contact', style: heading),
        const SizedBox(height: 8),
        Text(
          'For privacy questions: privacy@storypals.app\n'
          'For support: support@storypals.app',
          style: body,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
