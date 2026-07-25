import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/sound_service.dart';

// Simple math challenge prevents young children from accidentally entering
class ParentGateScreen extends ConsumerStatefulWidget {
  const ParentGateScreen({super.key});

  @override
  ConsumerState<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends ConsumerState<ParentGateScreen> {
  final _a = 7;
  final _b = 8;
  late int _answer;
  final _ctrl = TextEditingController();
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _answer = _a + _b;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = int.tryParse(_ctrl.text.trim());
    if (input == _answer) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefConsentGiven, true);
      if (!mounted) return;
      context.go(AppRoutes.parentDashboard);
    } else {
      setState(() => _error = true);
      _ctrl.clear();
      Future.delayed(
          const Duration(seconds: 1), () => setState(() => _error = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quiet zone: stop kid-side music so parents (and mic recordings) get silence.
    SoundFx.ambient(null);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              Text(
                'Parent Area',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please solve this to continue:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'What is $_a + $_b?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    errorText: _error ? 'Try again!' : null,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enter', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push(AppRoutes.privacyPolicy),
                child: const Text('Privacy Policy'),
              ),
              TextButton(
                onPressed: () {
                  final hasPrev = Navigator.canPop(context);
                  if (hasPrev) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.profileSelect);
                  }
                },
                child: const Text('Back to Kids'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
