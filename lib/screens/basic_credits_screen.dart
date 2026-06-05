import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'cinematic_credits_screen.dart';

class BasicCreditsScreen extends StatefulWidget {
  const BasicCreditsScreen({super.key});

  @override
  State<BasicCreditsScreen> createState() => _BasicCreditsScreenState();
}

class _BasicCreditsScreenState extends State<BasicCreditsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: colorScheme.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colorScheme.primary,
                ),
                onPressed: () {
                  settings.playTapSound();
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                settings.translate('credits_title').toUpperCase(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  color: colorScheme.primary,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _HeroBanner(
                  settings: settings,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 64),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSection(
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                    icon: Icons.code_rounded,
                    title: settings.translate('credits_developed_by'),
                    credits: [
                      _Credit('Erl Teodemar D. Sofer', settings.translate('credits_lead_dev')),
                      _Credit('Nixon E. Coronado', settings.translate('credits_thesis_leader')),
                      _Credit('Riana Alexis C. Bagalso', settings.translate('credits_researcher')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                    icon: Icons.handshake_rounded,
                    title: settings.translate('credits_partnership'),
                    credits: [
                      _Credit('Cacao Farmers Association of Nagcarlan', ''),
                      _Credit('Marites O. Caña', settings.translate('credits_head_cfan')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                    icon: Icons.verified_rounded,
                    title: settings.translate('credits_validation'),
                    credits: [
                      _Credit('Cer Jay B. Jimenez', settings.translate('credits_isp_manager')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                    icon: Icons.layers_rounded,
                    title: settings.translate('credits_built_with'),
                    credits: [
                      _Credit('Flutter & Dart', settings.translate('credits_app_framework')),
                      _Credit('YOLOv11s', settings.translate('credits_object_detection')),
                      _Credit('ONNX', settings.translate('credits_ml_inference')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSpecialThanksSection(settings, textTheme, colorScheme),
                  const SizedBox(height: 32),
                  _buildFooter(context, settings, textTheme, colorScheme),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required List<_Credit> credits,
  }) {
    return _SectionCard(
      colorScheme: colorScheme,
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 15),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          for (int i = 0; i < credits.length; i++) ...[
            _buildCreditTile(
                textTheme, colorScheme, credits[i].name, credits[i].role),
            if (i < credits.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialThanksSection(
      SettingsProvider settings, TextTheme textTheme, ColorScheme colorScheme) {
    return _SectionCard(
      colorScheme: colorScheme,
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.favorite_rounded, color: colorScheme.primary, size: 15),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              settings.translate('credits_special_thanks').toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Column(
          children: [
            _buildCreditTile(textTheme, colorScheme,
                settings.translate('credits_lspu'), settings.translate('credits_lspu_campus')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            _buildCreditTile(
                textTheme, colorScheme, settings.translate('credits_cfan_farmers'), ''),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                settings.translate('credits_farmers_list'),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.85,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditTile(
      TextTheme textTheme, ColorScheme colorScheme, String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (role.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              role,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, SettingsProvider settings, TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            settings.playTapSound();
            Navigator.of(context)
                .push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const CinematicCreditsScreen(),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 800),
                  ),
                )
                .then((_) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            });
          },
          icon: Icon(
            Icons.play_circle_outline_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          label: Text(
            settings.translate('credits_footer_button'),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.07),
                colorScheme.primaryContainer.withValues(alpha: 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 28,
                      height: 1,
                      color: colorScheme.primary.withValues(alpha: 0.35)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child:
                        Icon(Icons.eco_rounded, color: colorScheme.primary, size: 13),
                  ),
                  Container(
                      width: 28,
                      height: 1,
                      color: colorScheme.primary.withValues(alpha: 0.35)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '© ${DateTime.now().year} ${settings.translate('credits_cape_dev_team')}',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                settings.translate('credits_all_rights'),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.settings,
    required this.colorScheme,
    required this.textTheme,
  });

  final SettingsProvider settings;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  String _getHeaderIconPath(int themeIndex) {
    switch (themeIndex) {
      case 1:
        return 'assets/images/header_icon_pink.png';
      case 2:
        return 'assets/images/header_icon_blue.png';
      case 3:
        return 'assets/images/header_icon_green.png';
      case 0:
      default:
        return 'assets/images/header_icon_purple.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentIconPath = _getHeaderIconPath(settings.selectedThemeIndex);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.75),
                colorScheme.surface,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: -30,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 30,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 52),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.onPrimary.withValues(alpha: 0.10),
                  border: Border.all(
                    color: colorScheme.onPrimary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Image.asset(
                    currentIconPath,
                    key: ValueKey<String>(currentIconPath),
                    width: 62,
                    height: 62,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.spa_rounded,
                      size: 62,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'CAPE',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onPrimary,
                  letterSpacing: 10,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                settings.translate('cape_description'),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.72),
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(
                  settings.translate('cape_version'),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.colorScheme,
    required this.header,
    required this.body,
  });

  final ColorScheme colorScheme;
  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.primary.withValues(alpha: 0.03),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: header,
            ),
            body,
          ],
        ),
      ),
    );
  }
}

class _Credit {
  final String name;
  final String role;
  const _Credit(this.name, this.role);
}