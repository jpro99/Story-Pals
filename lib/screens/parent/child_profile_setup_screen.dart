import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/child_profile_provider.dart';

const _avatarEmojis = ['🦕', '🪆', '🐬', '🐒', '🚀'];
const _avatarColors = [
  AppColors.dinoGreen,
  AppColors.dollPink,
  AppColors.oceanBlue,
  AppColors.jungleGold,
  AppColors.spacePurple,
];

class ChildProfileSetupScreen extends ConsumerStatefulWidget {
  const ChildProfileSetupScreen({super.key, this.editingChildId});
  final String? editingChildId;

  @override
  ConsumerState<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState
    extends ConsumerState<ChildProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  int _age = 4;
  int _avatarIndex = 0;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(childProfilesProvider.notifier).addProfile(
          name: name,
          ageYears: _age,
          avatarIndex: _avatarIndex,
        );
    if (!mounted) return;
    context.go(AppRoutes.parentDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Child Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Child's Name",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                hintText: 'e.g. Emma',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Age', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filled(
                  onPressed: _age > 2 ? () => setState(() => _age--) : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 28,
                ),
                const SizedBox(width: 24),
                Text('$_age',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(width: 24),
                IconButton.filled(
                  onPressed: _age < 10 ? () => setState(() => _age++) : null,
                  icon: const Icon(Icons.add),
                  iconSize: 28,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Pick an Avatar',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_avatarEmojis.length, (i) {
                final selected = _avatarIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _avatarIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarColors[i].withOpacity(selected ? 0.3 : 0.1),
                      border: Border.all(
                        color: selected
                            ? _avatarColors[i]
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _avatarColors[i].withOpacity(0.4),
                                blurRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(_avatarEmojis[i],
                          style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile',
                        style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
