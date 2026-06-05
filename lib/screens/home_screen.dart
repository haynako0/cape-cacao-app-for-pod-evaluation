import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                'assets/images/hero_image.jpg',
              ),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            elevation: 2, 
            clipBehavior: Clip.antiAlias,
            color: colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.translate('welcome_title'), 
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    settings.translate('welcome_body'), 
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            elevation: 2, 
            clipBehavior: Clip.antiAlias,
            color: colorScheme.secondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bug_report_outlined, 
                        size: 28,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          settings.translate('threats_title'), 
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    settings.translate('threats_subtitle'), 
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DiseaseExpansionTile(
                    title: settings.translate('blackpod_title'), 
                    imagePath: 'assets/images/blackpod_rot.jpg',
                    whatIsIt: settings.translate('blackpod_what'), 
                    howItSpreads: settings.translate('blackpod_spread'), 
                  ),
                  _DiseaseExpansionTile(
                    title: settings.translate('borer_title'), 
                    imagePath: 'assets/images/cacao_pod_borer.jpg',
                    whatIsIt: settings.translate('borer_what'), 
                    howItSpreads: settings.translate('borer_spread'), 
                  ),
                  _DiseaseExpansionTile(
                    title: settings.translate('mirid_title'), 
                    imagePath: 'assets/images/mirid_bugs.jpg',
                    whatIsIt: settings.translate('mirid_what'), 
                    howItSpreads: settings.translate('mirid_spread'), 
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            elevation: 2, 
            clipBehavior: Clip.antiAlias,
            color: colorScheme.tertiaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined, 
                        size: 28,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          settings.translate('climate_title'), 
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/images/climate_affect.jpg',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    settings.translate('climate_body'), 
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: colorScheme.onTertiaryContainer, 
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DiseaseExpansionTile extends StatefulWidget {
  const _DiseaseExpansionTile({
    required this.title,
    required this.whatIsIt,
    required this.howItSpreads,
    required this.imagePath,
  });

  final String title;
  final String whatIsIt;
  final String howItSpreads;
  final String imagePath;

  @override
  State<_DiseaseExpansionTile> createState() => _DiseaseExpansionTileState();
}

class _DiseaseExpansionTileState extends State<_DiseaseExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext ctxt) {
    final textTheme = Theme.of(ctxt).textTheme;
    final colorScheme = Theme.of(ctxt).colorScheme;
    final settings = ctxt.watch<SettingsProvider>();

    return Card(
      elevation: 2, 
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: _isExpanded
          ? colorScheme.onPrimary
          : colorScheme.surfaceContainerLow,
      child: Theme(
        data: Theme.of(ctxt).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (bool expanded) {
            setState(() {
              _isExpanded = expanded;
            });
            ctxt.read<SettingsProvider>().playTapSound();
          },
          title: Text(
            widget.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          textColor: colorScheme.primary,
          collapsedTextColor: colorScheme.primary, 
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.primary, 
          subtitle: Text(
            _isExpanded
                ? settings.translate('tap_close') 
                : settings.translate('tap_open'), 
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.primary), 
          ),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  widget.imagePath,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              settings.translate('what_is_it'), 
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface, 
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.whatIsIt,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: colorScheme.primary, 
              ),
            ),
            const SizedBox(height: 12),
            Text(
              settings.translate('how_spread'), 
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface, 
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.howItSpreads,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: colorScheme.primary, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}