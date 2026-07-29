import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'sound_service.dart';

/// On-screen music / sound volume controls for kid and parent screens.
class SoundVolumePanel extends StatefulWidget {
  const SoundVolumePanel({super.key, this.compact = false});

  final bool compact;

  @override
  State<SoundVolumePanel> createState() => _SoundVolumePanelState();
}

class _SoundVolumePanelState extends State<SoundVolumePanel> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    SoundFx.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _open ? _expanded() : _collapsed(),
    );
  }

  Widget _collapsed() {
    return Tooltip(
      message: 'Sound',
      child: InkWell(
        onTap: () => setState(() => _open = true),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            SoundFx.musicVolume <= 0.01
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            color: AppColors.primary,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _expanded() {
    return Container(
      width: widget.compact ? 220 : 260,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🔊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sound',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _open = false),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          _row(
            label: 'Song',
            value: SoundFx.musicVolume,
            onDown: () async {
              await SoundFx.nudgeMusic(-0.1);
              setState(() {});
            },
            onUp: () async {
              await SoundFx.nudgeMusic(0.1);
              setState(() {});
            },
            onChanged: (v) async {
              await SoundFx.setMusicVolume(v);
              setState(() {});
            },
          ),
          _row(
            label: 'Taps',
            value: SoundFx.sfxVolume,
            onDown: () async {
              await SoundFx.nudgeSfx(-0.1);
              setState(() {});
            },
            onUp: () async {
              await SoundFx.nudgeSfx(0.1);
              setState(() {});
            },
            onChanged: (v) async {
              await SoundFx.setSfxVolume(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    required double value,
    required VoidCallback onDown,
    required VoidCallback onUp,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          IconButton(
            onPressed: onDown,
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            color: AppColors.primary,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ),
          IconButton(
            onPressed: onUp,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: AppColors.primary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Positions [SoundVolumePanel] in a corner without blocking play.
class SoundVolumeOverlay extends StatelessWidget {
  const SoundVolumeOverlay({
    super.key,
    this.alignment = Alignment.bottomLeft,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 12),
  });

  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: const SoundVolumePanel(),
        ),
      ),
    );
  }
}
