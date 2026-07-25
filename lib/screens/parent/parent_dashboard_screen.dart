import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/isar_service.dart';
import '../../models/child_profile.dart';
import '../../models/emotion_entry.dart';
import '../../providers/child_profile_provider.dart';
import '../../providers/skill_level_provider.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(childProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.profileSelect),
            child: const Text('Kids →'),
          ),
        ],
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Child Profiles',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            if (profiles.isEmpty)
              _EmptyProfilesCard(
                onAdd: () => context.go(AppRoutes.childProfileSetup),
              )
            else ...[
              ...profiles.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ChildCard(profile: p),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.childProfileSetup),
                icon: const Icon(Icons.add),
                label: const Text('Add Another Child'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _VoiceCard(),
            const SizedBox(height: 16),
            _PrivacyCard(),
          ],
        ),
      ),
    );
  }
}

class _EmptyProfilesCard extends StatelessWidget {
  const _EmptyProfilesCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🌟', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              "Let's add your first child!",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add Child'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends ConsumerStatefulWidget {
  const _ChildCard({required this.profile});
  final ChildProfile profile;

  @override
  ConsumerState<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends ConsumerState<_ChildCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const avatarEmojis = ['🦕', '🪆', '🐬', '🐒', '🚀'];
    final emoji =
        avatarEmojis[widget.profile.avatarIndex.clamp(0, avatarEmojis.length - 1)];

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Text(emoji, style: const TextStyle(fontSize: 36)),
            title: Text(widget.profile.name,
                style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('Age ${widget.profile.ageYears}'),
            trailing: IconButton(
              icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _MoodSection(
                childUuid: widget.profile.uuid,
                childName: widget.profile.name,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _MasteryLevels(childUuid: widget.profile.uuid),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _InterestPicker(childUuid: widget.profile.uuid),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _LearningWeights(profile: widget.profile),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterestPicker extends StatefulWidget {
  const _InterestPicker({required this.childUuid});
  final String childUuid;

  @override
  State<_InterestPicker> createState() => _InterestPickerState();
}

class _InterestPickerState extends State<_InterestPicker> {
  List<String>? _selected;

  @override
  void initState() {
    super.initState();
    InterestStore.getInterests(widget.childUuid).then((v) {
      if (mounted) setState(() => _selected = v);
    });
  }

  Future<void> _toggle(String id) async {
    final current = List<String>.from(_selected ?? []);
    current.contains(id) ? current.remove(id) : current.add(id);
    setState(() => _selected = current);
    await InterestStore.setInterests(widget.childUuid, current);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected == null) return const SizedBox(height: 24);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interests', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'What does your child love? Puzzles re-theme around these — '
          'a dinosaur kid counts T-Rexes, a soccer kid counts goals.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: InterestStore.available.map((interest) {
            final isOn = selected.contains(interest.id);
            return FilterChip(
              label: Text(interest.label),
              selected: isOn,
              onSelected: (_) => _toggle(interest.id),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontWeight: isOn ? FontWeight.w800 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MoodSection extends StatelessWidget {
  const _MoodSection({required this.childUuid, required this.childName});
  final String childUuid;
  final String childName;

  static const _emojiFor = {
    EmotionLevel.verySad: '😢',
    EmotionLevel.sad: '😕',
    EmotionLevel.neutral: '😐',
    EmotionLevel.happy: '🙂',
    EmotionLevel.veryHappy: '😄',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EmotionEntry>>(
      future: IsarService.getEmotionsForChild(
        childUuid,
        since: DateTime.now().subtract(const Duration(days: 14)),
      ),
      builder: (context, snap) {
        final entries = snap.data;
        if (entries == null || entries.isEmpty) {
          return const SizedBox.shrink();
        }

        // Alert when the last 3 days contain a very-sad, or 2+ sad check-ins.
        final cutoff = DateTime.now().subtract(const Duration(days: 3));
        final recent =
            entries.where((e) => e.recordedAt.isAfter(cutoff)).toList();
        final verySadCount =
            recent.where((e) => e.emotion == EmotionLevel.verySad).length;
        final sadCount =
            recent.where((e) => e.emotion == EmotionLevel.sad).length;
        final needsAttention = verySadCount >= 1 || sadCount >= 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mood Check-Ins',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            // Latest check-ins, most recent first.
            Wrap(
              spacing: 6,
              children: entries
                  .take(10)
                  .map((e) => Tooltip(
                        message:
                            '${e.checkInType == 'pre' ? 'Before' : 'After'} playing · '
                            '${e.recordedAt.month}/${e.recordedAt.day}',
                        child: Text(_emojiFor[e.emotion] ?? '😐',
                            style: const TextStyle(fontSize: 26)),
                      ))
                  .toList(),
            ),
            if (needsAttention) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💛', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$childName has checked in feeling sad recently. '
                        'It might be a nice moment to sit together, play a '
                        'chapter side by side, or just ask about their day.',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MasteryLevels extends StatelessWidget {
  const _MasteryLevels({required this.childUuid});
  final String childUuid;

  static const _skills = [
    (id: 'coding', label: '💻 Coding'),
    (id: 'math', label: '🔢 Math'),
    (id: 'english', label: '📖 Letters'),
    (id: 'spanish', label: '🌎 Spanish'),
    (id: 'tagalog', label: '🌺 Tagalog'),
  ];

  Future<List<(String, int, int)>> _load() async {
    final out = <(String, int, int)>[];
    for (final s in _skills) {
      final level = await SkillLevelStore.getLevel(childUuid, s.id);
      final solved = await SkillLevelStore.getSolvedCount(childUuid, s.id);
      out.add((s.label, level, solved));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<(String, int, int)>>(
      future: _load(),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox(height: 24);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practice Mastery',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...data.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(row.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: row.$2 / 10,
                            minHeight: 8,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Lv ${row.$2} · ${row.$3} solved',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _LearningWeights extends ConsumerStatefulWidget {
  const _LearningWeights({required this.profile});
  final ChildProfile profile;

  @override
  ConsumerState<_LearningWeights> createState() => _LearningWeightsState();
}

class _LearningWeightsState extends ConsumerState<_LearningWeights> {
  late double _coding;
  late double _math;
  late double _english;
  late double _language;
  late double _geography;
  late int _sessionMinutes;

  @override
  void initState() {
    super.initState();
    _coding = widget.profile.codingWeight;
    _math = widget.profile.mathWeight;
    _english = widget.profile.englishWeight;
    _language = widget.profile.additionalLanguageWeight;
    _geography = widget.profile.geographyWeight;
    _sessionMinutes = widget.profile.sessionLimitMinutes;
  }

  Future<void> _save() async {
    await ref.read(childProfilesProvider.notifier).updateWeights(
          widget.profile.uuid,
          coding: _coding,
          math: _math,
          english: _english,
          language: _language,
          geography: _geography,
          sessionMinutes: _sessionMinutes,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Learning Focus',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Slide to control how often each topic appears.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _WeightSlider(
          label: '💻 Coding',
          value: _coding,
          color: AppColors.spacePurple,
          onChanged: (v) => setState(() => _coding = v),
        ),
        _WeightSlider(
          label: '🔢 Math',
          value: _math,
          color: AppColors.oceanBlue,
          onChanged: (v) => setState(() => _math = v),
        ),
        _WeightSlider(
          label: '📖 English',
          value: _english,
          color: AppColors.dinoGreen,
          onChanged: (v) => setState(() => _english = v),
        ),
        _WeightSlider(
          label: '🌍 Language',
          value: _language,
          color: AppColors.secondary,
          onChanged: (v) => setState(() => _language = v),
        ),
        _WeightSlider(
          label: '🗺 Geography',
          value: _geography,
          color: AppColors.jungleGold,
          onChanged: (v) => setState(() => _geography = v),
        ),
        const SizedBox(height: 24),
        Text('Session Limit', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _sessionMinutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '$_sessionMinutes min',
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _sessionMinutes = v.round()),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                '$_sessionMinutes min',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Settings'),
          ),
        ),
      ],
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Slider(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _VoiceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.dollPinkLight,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: const Text('🎙️', style: TextStyle(fontSize: 32)),
        title: Text('Record Your Voice',
            style: Theme.of(context).textTheme.titleLarge),
        subtitle: const Text(
            'Read a few praise lines so your child hears YOU cheering '
            'them on — not a computer voice.'),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: () => context.go(AppRoutes.parentVoice),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy & Data',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Story Pals does not collect personal data from children. '
              'All play data is stored only on this device unless you opt in '
              'to cloud sync. No ads. No social features.',
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push(AppRoutes.privacyPolicy),
              child: const Text('View Full Privacy Policy →'),
            ),
          ],
        ),
      ),
    );
  }
}
