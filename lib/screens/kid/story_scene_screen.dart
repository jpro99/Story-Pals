import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/tts_service.dart';
import '../../providers/chapter_provider.dart';

class StorySceneScreen extends ConsumerStatefulWidget {
  const StorySceneScreen({
    super.key,
    required this.chapterId,
    required this.sceneId,
  });
  final String chapterId;
  final String sceneId;

  @override
  ConsumerState<StorySceneScreen> createState() => _StorySceneScreenState();
}

class _StorySceneScreenState extends ConsumerState<StorySceneScreen>
    with TickerProviderStateMixin {
  late AnimationController _charController;
  late AnimationController _dialogController;
  late Animation<Offset> _charSlide;
  late Animation<double> _dialogFade;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _charController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dialogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _charSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _charController, curve: Curves.easeOut));
    _dialogFade = CurvedAnimation(parent: _dialogController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _charController.forward().then((_) {
      setState(() => _dialogVisible = true);
      _dialogController.forward();
      _speakCurrentDialog();
    });
  }

  void _speakCurrentDialog() {
    final chapterAsync = ref.read(chapterContentProvider(widget.chapterId));
    chapterAsync.whenData((chapter) {
      final scene = chapter.scenes.firstWhere(
        (s) => s['scene_id'] == widget.sceneId,
        orElse: () => chapter.scenes.first,
      ) as Map<String, dynamic>;
      final dialog =
          (scene['dialog'] as Map<String, dynamic>?)?['en'] as String? ?? '';
      if (dialog.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(dialog);
      }
    });
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    _charController.dispose();
    _dialogController.dispose();
    super.dispose();
  }

  void _advance(Map<String, dynamic> scene) {
    final next = scene['next'] as String?;
    if (next == null) {
      // Chapter complete — post check-in
      context.go('/emotion-checkin?post=true');
      return;
    }
    if (next.startsWith('puzzle_')) {
      final idx = int.parse(next.split('_').last) - 1;
      context.go('/puzzle/${widget.chapterId}/$idx');
    } else {
      context.go('/story/${widget.chapterId}/$next');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(chapterContentProvider(widget.chapterId));

    return chapterAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (chapter) {
        final scene = chapter.scenes.firstWhere(
          (s) => s['scene_id'] == widget.sceneId,
          orElse: () => chapter.scenes.first,
        ) as Map<String, dynamic>;

        final locale = 'en'; // TODO: wire to locale provider
        final dialog =
            (scene['dialog'] as Map<String, dynamic>?)?[locale] as String? ??
                '';
        final background = scene['background'] as String? ?? 'jungle';
        final action = scene['character_action'] as String? ?? 'idle';

        return Scaffold(
          body: GestureDetector(
            onTap: () => _advance(scene),
            child: Stack(
              children: [
                // Background
                Positioned.fill(
                  child: _SceneBackground(background: background),
                ),
                // Character
                Positioned(
                  left: 20,
                  bottom: 180,
                  child: SlideTransition(
                    position: _charSlide,
                    child: _CharacterWidget(
                      character: chapter.character,
                      action: action,
                    ),
                  ),
                ),
                // Dialog bubble
                if (_dialogVisible)
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: FadeTransition(
                      opacity: _dialogFade,
                      child: _DialogBubble(text: dialog),
                    ),
                  ),
                // Tap hint
                Positioned(
                  bottom: 12,
                  right: 24,
                  child: FadeTransition(
                    opacity: _dialogFade,
                    child: const _TapHint(),
                  ),
                ),
                // Back to chapter map
                Positioned(
                  top: 12,
                  left: 8,
                  child: SafeArea(
                    child: Material(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.go('/chapter-map'),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SceneBackground extends StatelessWidget {
  const _SceneBackground({required this.background});
  final String background;

  static const _gradients = {
    'jungle': [Color(0xFF2E7D32), Color(0xFF81C784)],
    'jungle_river': [Color(0xFF1565C0), Color(0xFF4CAF50)],
    'jungle_clearing': [Color(0xFF558B2F), Color(0xFFAED581)],
    'jungle_feast': [Color(0xFF33691E), Color(0xFF8BC34A)],
    'bedroom': [Color(0xFFCE93D8), Color(0xFFF8BBD0)],
    'tea_table': [Color(0xFFAD1457), Color(0xFFF48FB1)],
    'tea_party': [Color(0xFF6A1B9A), Color(0xFFCE93D8)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[background] ??
        [AppColors.primary, AppColors.primaryDark];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: _BackgroundDetails(background: background),
    );
  }
}

class _BackgroundDetails extends StatelessWidget {
  const _BackgroundDetails({required this.background});
  final String background;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScenePainter(background));
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.background);
  final String background;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Ground
    paint.color = Colors.black.withOpacity(0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
        const Radius.circular(0),
      ),
      paint,
    );

    // Simple tree shapes for jungle scenes
    if (background.contains('jungle')) {
      _drawTree(canvas, size, size.width * 0.85, size.height * 0.5);
      _drawTree(canvas, size, size.width * 0.1, size.height * 0.55);
    }

    // Clouds
    paint.color = Colors.white.withOpacity(0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.12),
        width: 120,
        height: 50,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.08),
        width: 90,
        height: 40,
      ),
      paint,
    );
  }

  void _drawTree(Canvas canvas, Size size, double x, double y) {
    final paint = Paint()..color = Colors.green.shade800.withOpacity(0.6);
    // Trunk
    paint.color = Colors.brown.withOpacity(0.5);
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 60), width: 16, height: 60), paint);
    // Canopy
    paint.color = Colors.green.shade700.withOpacity(0.6);
    canvas.drawCircle(Offset(x, y), 50, paint);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.background != background;
}

class _CharacterWidget extends StatefulWidget {
  const _CharacterWidget({required this.character, required this.action});
  final String character;
  final String action;

  @override
  State<_CharacterWidget> createState() => _CharacterWidgetState();
}

class _CharacterWidgetState extends State<_CharacterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleCtrl;
  late Animation<double> _idleBounce;

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _idleBounce = Tween(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.character == 'dino' ? '🦕' : '🪆';
    final size = _actionSize(widget.action);

    return AnimatedBuilder(
      animation: _idleBounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _idleBounce.value),
        child: child,
      ),
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
  }

  double _actionSize(String action) {
    switch (action) {
      case 'celebrate':
        return 110;
      case 'jump':
        return 100;
      default:
        return 90;
    }
  }
}

class _DialogBubble extends StatelessWidget {
  const _DialogBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TapHint extends StatefulWidget {
  const _TapHint();

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: const Text('👆 Tap anywhere!',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }
}
