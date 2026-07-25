import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/parent_voice_service.dart';

/// Parents read short praise lines out loud; the app records each one and
/// plays them back to the child during celebrations — real mom or dad,
/// not a computer. All recordings stay on this device.
class ParentVoiceScreen extends ConsumerStatefulWidget {
  const ParentVoiceScreen({super.key});

  @override
  ConsumerState<ParentVoiceScreen> createState() => _ParentVoiceScreenState();
}

class _ParentVoiceScreenState extends ConsumerState<ParentVoiceScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingLineId;
  final Map<String, bool> _recorded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    for (final line in parentVoiceLines) {
      _recorded[line.id] = await ParentVoiceService.isRecorded(line.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startRecording(VoiceLine line) async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Microphone permission is needed to record.')));
      }
      return;
    }
    final path = await ParentVoiceService.filePathFor(line.id);
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() => _recordingLineId = line.id);
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    final id = _recordingLineId;
    setState(() {
      _recordingLineId = null;
      if (id != null) _recorded[id] = true;
    });
  }

  Future<void> _play(VoiceLine line) async {
    await ref.read(parentVoiceServiceProvider).playLine(line.id);
  }

  Future<void> _delete(VoiceLine line) async {
    await ParentVoiceService.deleteRecording(line.id);
    setState(() => _recorded[line.id] = false);
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordedCount = _recorded.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Voice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.parentDashboard),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: AppColors.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Record your voice for your child 💛',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'Read each line out loud, warmly — like you would '
                          'say it to your child. When they solve a puzzle, '
                          "they'll hear YOU cheering, not a computer.\n\n"
                          'Tips: hold the device close, speak with a smile, '
                          'and record where it\'s quiet. Recordings stay on '
                          'this device only.',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$recordedCount of ${parentVoiceLines.length} lines recorded',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildSection('Cheering lines 🎉', 'praise'),
                ..._buildSection('Gentle encouragement 💪', 'encourage'),
                ..._buildSection('Special moments ⭐', 'moment'),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  List<Widget> _buildSection(String title, String category) {
    final lines =
        parentVoiceLines.where((l) => l.category == category).toList();
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      ...lines.map(_buildLineCard),
    ];
  }

  Widget _buildLineCard(VoiceLine line) {
    final isRecording = _recordingLineId == line.id;
    final isRecorded = _recorded[line.id] ?? false;
    final otherRecording =
        _recordingLineId != null && _recordingLineId != line.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRecording
              ? AppColors.error
              : isRecorded
                  ? AppColors.success
                  : Colors.grey.shade300,
          width: isRecording ? 2.5 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(
              isRecorded ? Icons.check_circle_rounded : Icons.mic_none_rounded,
              color: isRecorded ? AppColors.success : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '"${line.text}"',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            if (isRecording)
              TextButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop_circle_rounded,
                    color: AppColors.error, size: 30),
                label: const Text('Stop',
                    style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800)),
              )
            else ...[
              if (isRecorded)
                IconButton(
                  tooltip: 'Listen',
                  icon: const Icon(Icons.play_circle_rounded,
                      color: AppColors.primary, size: 28),
                  onPressed: () => _play(line),
                ),
              if (isRecorded)
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.grey.shade500),
                  onPressed: () => _delete(line),
                ),
              IconButton(
                tooltip: isRecorded ? 'Re-record' : 'Record',
                icon: Icon(
                  Icons.mic_rounded,
                  color: otherRecording ? Colors.grey.shade300 : AppColors.error,
                  size: 28,
                ),
                onPressed:
                    otherRecording ? null : () => _startRecording(line),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
