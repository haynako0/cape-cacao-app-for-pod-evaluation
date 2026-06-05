import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

sealed class CreditItem { const CreditItem(); }

final class CreditHeader extends CreditItem {
  final String text;
  const CreditHeader(this.text);
}

final class CreditBody extends CreditItem {
  final String title;
  final String body;
  const CreditBody({required this.title, required this.body});
}

final class CreditImage extends CreditItem {
  final String assetPath;
  final String caption;
  final double? width;
  final double? height;
  const CreditImage({required this.assetPath, this.caption = '', this.width, this.height});
}

final class CreditSpacer extends CreditItem {
  final double height;
  const CreditSpacer(this.height);
}

final class CreditGauntlet extends CreditItem {
  const CreditGauntlet();
}

class _Particle {
  final double startX;
  final double startY;
  final double speed;
  final double radius;
  final double opacity;
  final double blur;
  final double swayFreq;
  final double flickerFreq;
  final double phase;

  _Particle(math.Random r)
      : startX = r.nextDouble(),
        startY = r.nextDouble(),
        speed = 0.03 + r.nextDouble() * 0.12,
        radius = 0.5 + r.nextDouble() * 2.0,
        opacity = 0.06 + r.nextDouble() * 0.28,
        blur = 1.5 + r.nextDouble() * 5.0,
        swayFreq = 0.2 + r.nextDouble() * 1.2,
        flickerFreq = 0.5 + r.nextDouble() * 2.5,
        phase = r.nextDouble() * math.pi * 2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.time,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final y = ((p.startY - time * p.speed) % 1.0 + 1.0) % 1.0;
      final x = (p.startX + math.sin(time * math.pi * 2 * p.swayFreq + p.phase) * 0.04)
          .clamp(0.0, 1.0);
      final flicker = 0.5 + 0.5 * math.sin(time * math.pi * 2 * p.flickerFreq + p.phase);
      final alpha = (p.opacity * flicker).clamp(0.0, 1.0);
      final paint = Paint()..color = color.withValues(alpha: alpha);

      if (i < 14) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, p.blur);
        canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          p.radius * 2.5,
          paint,
        );
      } else {
        canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          p.radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.time != time;
}

class CinematicCreditsScreen extends StatefulWidget {
  const CinematicCreditsScreen({super.key});

  @override
  State<CinematicCreditsScreen> createState() => _CinematicCreditsScreenState();
}

class _CinematicCreditsScreenState extends State<CinematicCreditsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final ScrollController _scrollController;
  late final AudioPlayer _audioPlayer;
  late final List<_Particle> _particles;

  final _stopwatch = Stopwatch();
  double _audioFraction = 0.0;
  bool _disposed = false;

  static const double _totalSeconds = 336.0;
  static const double _tIntroEnd = 5 / _totalSeconds;
  static const double _tBuildupEnd = 196 / _totalSeconds;
  static const double _tClimax1End = 228 / _totalSeconds;
  static const double _tPeakEnd = 259 / _totalSeconds;
  static const double _tWinddownEnd = 334 / _totalSeconds;

  static const Color _cream = Color(0xFFF0EAD6);

  List<CreditItem> _getCredits(SettingsProvider sp) => [
        const CreditSpacer(120),
        const CreditGauntlet(),
        const CreditSpacer(60),
        CreditHeader(sp.translate('credits_cape_title')),
        CreditBody(
          title: sp.translate('credits_cape_subtitle'),
          body: sp.translate('credits_cape_body'),
        ),
        const CreditSpacer(80),
        CreditHeader(sp.translate('credits_ground_truth_title')),
        CreditBody(
          title: sp.translate('credits_ground_truth_subtitle'),
          body: sp.translate('credits_ground_truth_body'),
        ),
        CreditBody(
          title: sp.translate('credits_cfan_title'),
          body: sp.translate('credits_cfan_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/farm.jpg',
          caption: sp.translate('credits_reality_caption'),
          height: 240,
        ),
        const CreditSpacer(90),
        CreditHeader(sp.translate('credits_architecture_title')),
        CreditBody(
          title: sp.translate('credits_architecture_subtitle'),
          body: sp.translate('credits_architecture_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/old_app.jpg',
          caption: sp.translate('credits_legacy_caption'),
          width: 225,
          height: 500,
        ),
        const CreditSpacer(80),
        CreditHeader(sp.translate('credits_teaching_title')),
        CreditBody(
          title: sp.translate('credits_chaos_subtitle'),
          body: sp.translate('credits_chaos_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/bounding_box_bug.jpg',
          caption: sp.translate('credits_glitch_caption'),
          width: 225,
          height: 500,
        ),
        const CreditSpacer(60),
        CreditBody(
          title: sp.translate('credits_faces_subtitle'),
          body: sp.translate('credits_faces_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/blackpod_face_detect.jpg',
          caption: sp.translate('credits_false_positive_caption'),
          width: 225,
          height: 500,
        ),
        const CreditSpacer(90),
        CreditHeader(sp.translate('credits_enemy_title')),
        CreditBody(
          title: sp.translate('credits_rot_subtitle'),
          body: sp.translate('credits_rot_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/blackpod_rot.jpg',
          caption: sp.translate('credits_target_caption'),
          height: 240,
        ),
        const CreditSpacer(80),
        CreditHeader(sp.translate('credits_convergence_title')),
        CreditBody(
          title: sp.translate('credits_signal_subtitle'),
          body: sp.translate('credits_signal_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/fixed_detections.jpg',
          caption: sp.translate('credits_precision_caption'),
          width: 270,
          height: 360,
        ),
        const CreditSpacer(40),
        CreditImage(
          assetPath: 'assets/images/training_graphs.png',
          caption: sp.translate('credits_proof_caption'),
          height: 240,
        ),
        const CreditSpacer(60),
        CreditBody(
          title: sp.translate('credits_resilience_subtitle'),
          body: sp.translate('credits_resilience_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/resilient_detection.jpg',
          caption: sp.translate('credits_inference_caption'),
          height: 240,
        ),
        const CreditSpacer(90),
        CreditHeader(sp.translate('credits_field_title')),
        CreditBody(
          title: sp.translate('credits_silence_subtitle'),
          body: sp.translate('credits_silence_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/infield_testing.jpg',
          caption: sp.translate('credits_deployment_caption'),
          width: 270,
          height: 360,
        ),
        const CreditSpacer(40),
        CreditImage(
          assetPath: 'assets/images/infield_testing2.jpg',
          caption: sp.translate('credits_soil_caption'),
          width: 270,
          height: 360,
        ),
        const CreditSpacer(60),
        CreditBody(
          title: sp.translate('credits_output_subtitle'),
          body: sp.translate('credits_output_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/inapp_results.jpg',
          caption: sp.translate('credits_history_caption'),
          width: 270,
          height: 360,
        ),
        const CreditSpacer(90),
        CreditHeader(sp.translate('credits_people_title')),
        CreditBody(
          title: sp.translate('credits_team_subtitle'),
          body: sp.translate('credits_team_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/team_and_head.jpg',
          caption: sp.translate('credits_dev_ground_truth_caption'),
          width: 270,
          height: 360,
        ),
        const CreditSpacer(60),
        CreditBody(
          title: sp.translate('credits_validation_subtitle'),
          body: sp.translate('credits_validation_body'),
        ),
        const CreditSpacer(60),
        CreditImage(
          assetPath: 'assets/images/pcard_meeting.jpg',
          caption: sp.translate('credits_defending_caption'),
          height: 240,
        ),
        const CreditSpacer(90),
        CreditHeader(sp.translate('credits_soundscape_title')),
        CreditBody(
          title: sp.translate('credits_theme_subtitle'),
          body: sp.translate('credits_theme_body'),
        ),
        const CreditSpacer(90),
        CreditHeader(sp.translate('credits_commit_title')),
        CreditBody(
          title: sp.translate('credits_lspu_subtitle'),
          body: sp.translate('credits_lspu_body'),
        ),
        CreditBody(
          title: sp.translate('credits_generation_subtitle'),
          body: sp.translate('credits_generation_body'),
        ),
        const CreditSpacer(90),
        CreditHeader(sp.translate('credits_cape_final_title')),
        CreditBody(
          title: sp.translate('credits_cape_final_subtitle'),
          body: sp.translate('credits_cape_final_body'),
        ),
        const CreditSpacer(240),
      ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final rng = math.Random();
    _particles = List.generate(44, (_) => _Particle(rng));
    _stopwatch.start();
    _scrollController = ScrollController();
    _audioPlayer = AudioPlayer();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(hours: 24),
    )..repeat();
    _ticker.addListener(_onTick);
    _startPlayback();
  }

  void _onTick() {
    if (_disposed || !mounted) return;
    final duration = _audioPlayer.duration;
    if (duration == null || duration.inMilliseconds == 0) return;
    final rawMs = _audioPlayer.position.inMilliseconds % duration.inMilliseconds;
    _audioFraction = rawMs / duration.inMilliseconds;
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) {
        _scrollController.jumpTo((_audioFraction * max).clamp(0.0, max));
      }
    }
  }

  Future<void> _startPlayback() async {
    try {
      await _audioPlayer.setLoopMode(LoopMode.all);
      await _audioPlayer
          .setAudioSource(AudioSource.asset('assets/audio/credits_theme.mp3'))
          .timeout(const Duration(seconds: 5));
      await _audioPlayer.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  double get _opacity {
    if (_audioFraction < _tIntroEnd) {
      return (_audioFraction / _tIntroEnd).clamp(0.0, 1.0);
    }
    if (_audioFraction > _tWinddownEnd) {
      return (1.0 - (_audioFraction - _tWinddownEnd) / (1.0 - _tWinddownEnd))
          .clamp(0.0, 1.0);
    }
    return 1.0;
  }

  bool get _isClimax1 =>
      _audioFraction >= _tBuildupEnd && _audioFraction < _tClimax1End;

  bool get _isPeak =>
      _audioFraction >= _tClimax1End && _audioFraction < _tPeakEnd;

  double get _imageScale {
    if (!_isPeak) return 1.0;
    final p = (_audioFraction - _tClimax1End) / (_tPeakEnd - _tClimax1End);
    final w = p < 0.5 ? p * 2.0 : (1.0 - p) * 2.0;
    return 1.0 + (0.06 * w);
  }

  List<Shadow> _getGlowShadows(Color primary, Color secondary) {
    if (_isPeak) return [Shadow(color: secondary.withValues(alpha: 0.31), blurRadius: 24, offset: Offset.zero)];
    if (_isClimax1) return [Shadow(color: primary.withValues(alpha: 0.22), blurRadius: 14, offset: Offset.zero)];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;
    final fontFamily = Theme.of(context).textTheme.bodyLarge?.fontFamily;
    
    final creditsList = _getCredits(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          final particleTime = _stopwatch.elapsed.inMilliseconds / 1000.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.4,
                    colors: [Color(0xFF0F0B06), Color(0xFF000000)],
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    time: particleTime,
                    color: primary,
                  ),
                ),
              ),
              Opacity(
                opacity: _opacity.clamp(0.0, 1.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: size.height,
                    bottom: size.height * 0.5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: creditsList
                        .map((c) => _buildItem(c, size.width, primary, secondary, fontFamily))
                        .toList(),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.35),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(CreditItem item, double w, Color primary, Color secondary, String? fontFamily) => switch (item) {
        final CreditHeader h => _buildHeader(h, primary, secondary, fontFamily),
        final CreditBody b => _buildBody(b, primary, secondary, fontFamily),
        final CreditImage img => _buildImage(img, w, primary),
        final CreditSpacer s => SizedBox(height: s.height),
        final CreditGauntlet _ => _buildGauntlet(primary),
      };

  Widget _buildGauntlet(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          height: 320,
          width: 320,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 80,
                left: 10,
                child: _buildGem('assets/images/header_icon_purple.png', primary),
              ),
              Positioned(
                top: 10,
                left: 75,
                child: _buildGem('assets/images/header_icon_pink.png', primary),
              ),
              Positioned(
                top: 10,
                right: 75,
                child: _buildGem('assets/images/header_icon_blue.png', primary),
              ),
              Positioned(
                top: 80,
                right: 10,
                child: _buildGem('assets/images/header_icon_green.png', primary),
              ),
              Positioned(
                bottom: 20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.contain,
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGem(String path, Color primary) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          width: 70,
          height: 70,
        ),
      ),
    );
  }

  Widget _buildHeader(CreditHeader h, Color primary, Color secondary, String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.only(top: 64, bottom: 36, left: 32, right: 32),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primary.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [primary, secondary, primary],
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              h.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                color: Colors.white,
                fontSize: 28.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 8.0,
                shadows: _getGlowShadows(primary, secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CreditBody b, Color primary, Color secondary, String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
      child: Column(
        children: [
          if (b.title.isNotEmpty) ...[
            Text(
              b.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                color: _cream.withValues(alpha: 0.82),
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.8,
                shadows: _getGlowShadows(primary, secondary),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            b.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              color: _cream.withValues(alpha: 0.52),
              fontSize: 13.0,
              height: 2.05,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(CreditImage img, double screenWidth, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Transform.scale(
        scale: _imageScale,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: _isPeak ? 0.22 : 0.07),
                    blurRadius: 36,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: img.width ?? screenWidth * 0.86,
                  height: img.height ?? 240,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1C1208), Color(0xFF0D0706)],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Image.asset(
                          img.assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_outlined,
                                  color: primary.withValues(alpha: 0.22),
                                  size: 38,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  img.assetPath.split('/').last,
                                  style: TextStyle(
                                    color: primary.withValues(alpha: 0.2),
                                    fontSize: 10.0,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                              stops: const [0.35, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (img.caption.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                img.caption.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary.withValues(alpha: 0.5),
                  fontSize: 9.0,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}