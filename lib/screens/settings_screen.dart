import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final settingsReader = context.read<SettingsProvider>();

    if (settingsProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSettingsContainer(
              context: context,
              backgroundColor: colorScheme.primaryContainer,
              textColor: colorScheme.onPrimaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context, 
                    settingsProvider.translate('language'), 
                    Icons.language_rounded, 
                    colorScheme.onPrimaryContainer
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    context: context,
                    value: settingsProvider.selectedLanguage,
                    items: settingsProvider.languageOptions,
                    onChanged: (val) {
                      settingsReader.changeLanguage(val);
                      settingsReader.playTapSound();
                    },
                    dropdownColor: colorScheme.surface, 
                    textColor: colorScheme.onSurface,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSettingsContainer(
              context: context,
              backgroundColor: colorScheme.secondaryContainer,
              textColor: colorScheme.onSecondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context, 
                    settingsProvider.translate('app_theme'), 
                    Icons.palette_rounded, 
                    colorScheme.onSecondaryContainer
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withAlpha(150), 
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          settingsProvider.translate('dark_mode'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: settingsProvider.isDarkMode,
                          activeThumbColor: colorScheme.secondary,
                          onChanged: (bool value) {
                            settingsReader.toggleDarkMode(value);
                            settingsReader.playTapSound();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeButton(context: context, index: 0), 
                      _buildThemeButton(context: context, index: 1), 
                      _buildThemeButton(context: context, index: 2), 
                      _buildThemeButton(context: context, index: 3), 
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            _buildSettingsContainer(
              context: context,
              backgroundColor: colorScheme.tertiaryContainer,
              textColor: colorScheme.onTertiaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context, 
                    settingsProvider.translate('text_settings'), 
                    Icons.text_fields_rounded, 
                    colorScheme.onTertiaryContainer
                  ),
                  const SizedBox(height: 20),

                  _buildSubTitle(context, settingsProvider.translate('text_size'), colorScheme.onTertiaryContainer),
                  const SizedBox(height: 12),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withAlpha(150),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SegmentedButton<String>(
                      segments: settingsProvider.textSizeOptions.map((String size) {
                        final translationKey = size.toLowerCase();
                        return ButtonSegment<String>(
                          value: size,
                          label: Text(
                            settingsProvider.translate(translationKey),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      selected: {settingsProvider.selectedTextSize},
                      onSelectionChanged: (Set<String> newSelection) {
                        settingsReader.changeTextSize(newSelection.first);
                        settingsReader.playTapSound();
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.tertiary;
                            }
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return colorScheme.onTertiary;
                            }
                            return colorScheme.onSurface;
                          },
                        ),
                        side: WidgetStateProperty.all(BorderSide.none),
                        elevation: WidgetStateProperty.all(0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSubTitle(context, settingsProvider.translate('font_style'), colorScheme.onTertiaryContainer),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    context: context,
                    value: settingsProvider.selectedFont,
                    items: settingsProvider.fontOptions,
                    onChanged: (val) {
                      settingsReader.changeFont(val);
                      settingsReader.playTapSound();
                    },
                    dropdownColor: colorScheme.surface,
                    textColor: colorScheme.onSurface,
                    itemLabelBuilder: (val) => settingsProvider.translate(val.toLowerCase().replaceAll(' ', '_')),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSettingsContainer(
              context: context,
              backgroundColor: colorScheme.surfaceContainerHighest,
              textColor: colorScheme.onSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context, 
                    settingsProvider.translate('sounds'), 
                    Icons.volume_up_rounded, 
                    colorScheme.primary 
                  ),
                  
                  const SizedBox(height: 20),

                  _buildSoundSwitchRow(
                    context, 
                    settingsProvider.translate('tap_feedback'), 
                    settingsProvider.translate('enable_tap'),
                    settingsProvider.tapSfxEnabled,
                    (val) {
                      settingsReader.toggleTapSfx(val);
                      settingsReader.playTapSound();
                    },
                    colorScheme
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: settingsProvider.tapSfxEnabled ? 1.0 : 0.5,
                    child: _buildDropdown(
                      context: context,
                      value: settingsProvider.selectedSfx,
                      items: settingsProvider.sfxOptions,
                      onChanged: settingsProvider.tapSfxEnabled 
                        ? (val) { settingsReader.changeSfx(val); settingsReader.playTapSound(); } 
                        : null,
                      dropdownColor: colorScheme.surface,
                      textColor: colorScheme.onSurface,
                      itemLabelBuilder: (val) => settingsProvider.getTranslatedSoundName(val),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: colorScheme.outline.withAlpha(50)),
                  const SizedBox(height: 24),

                  _buildSoundSwitchRow(
                    context, 
                    settingsProvider.translate('scan_feedback'), 
                    settingsProvider.translate('enable_scan'),
                    settingsProvider.scanSfxEnabled,
                    (val) {
                      settingsReader.toggleScanSfx(val);
                      settingsReader.playTapSound();
                    },
                    colorScheme
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: settingsProvider.scanSfxEnabled ? 1.0 : 0.5,
                    child: _buildDropdown(
                      context: context,
                      value: settingsProvider.selectedScanSfx,
                      items: settingsProvider.scanSfxOptions,
                      onChanged: settingsProvider.scanSfxEnabled 
                        ? (val) { settingsReader.changeScanSfx(val); settingsReader.playTapSound(); } 
                        : null,
                      dropdownColor: colorScheme.surface,
                      textColor: colorScheme.onSurface,
                      itemLabelBuilder: (val) => settingsProvider.getTranslatedSoundName(val),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSettingsContainer(
              context: context,
              backgroundColor: colorScheme.errorContainer, 
              textColor: colorScheme.onErrorContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context, 
                    settingsProvider.translate('experimental'), 
                    Icons.science_rounded, 
                    colorScheme.onErrorContainer
                  ),
                  const SizedBox(height: 20),

                  



                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSubTitle(context, settingsProvider.translate('confidence_threshold'), colorScheme.onErrorContainer),
                      Text(
                        "${(settingsProvider.confidenceThreshold * 100).toInt()}%",
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onErrorContainer),
                      ),
                    ],
                  ),
                  Slider(
                    value: settingsProvider.confidenceThreshold,
                    min: 0.1,
                    max: 0.95,
                    divisions: 17,
                    activeColor: colorScheme.onErrorContainer,
                    inactiveColor: colorScheme.surface.withAlpha(100),
                    onChanged: (val) {
                      settingsReader.changeConfidenceThreshold(val);
                    },
                    onChangeEnd: (_) => settingsReader.playTapSound(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }


  Widget _buildSettingsContainer({
    required BuildContext context,
    required Color backgroundColor,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: textColor,
            displayColor: textColor,
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        child: child,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(30), 
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTitle(BuildContext context, String title, Color color) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: color.withAlpha(200),
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required Function(String?)? onChanged,
    required Color dropdownColor,
    required Color textColor,
    String Function(String)? itemLabelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: dropdownColor.withAlpha(255), 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: dropdownColor,
          icon: Icon(Icons.arrow_drop_down_rounded, color: textColor),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                itemLabelBuilder != null ? itemLabelBuilder(item) : item,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSoundSwitchRow(
    BuildContext context, 
    String title, 
    String subtitle, 
    bool value, 
    Function(bool) onChanged,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold
              ),
            ),
            Text(
              subtitle, 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150)
              ),
            ),
          ],
        ),
        Switch(
          value: value,
          activeThumbColor: colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required int index,
  }) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settingsReader = context.read<SettingsProvider>();

    final bool isSelected = settingsProvider.selectedThemeIndex == index;
    final previewScheme = settingsProvider.getThemeSchemeAtIndex(index);

    return GestureDetector(
      onTap: () {
        settingsReader.changeTheme(index);
        settingsReader.playTapSound(); 
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                previewScheme.primary, 
                previewScheme.secondary, 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isSelected 
            ? const Icon(Icons.check, color: Colors.white, size: 30)
            : null,
        ),
      ),
    );
  }
}