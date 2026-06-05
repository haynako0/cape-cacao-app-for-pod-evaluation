import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../sfx_service.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  final SfxService _sfxService = SfxService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  static const String _defaultLanguage = 'English';
  static const String _defaultSfx = 'Tap 1';
  static const bool _defaultSfxEnabled = true;
  static const int _defaultThemeIndex = 0;
  static const bool _defaultDarkMode = false;
  static const String _defaultScanSfx = 'Complete 1';
  static const bool _defaultScanSfxEnabled = true;
  
  static const String _defaultTextSize = 'Small';
  static const String _defaultFont = 'Font 1'; 

  static const String _defaultModel = 'v1'; 
  static const double _defaultConfidence = 0.4;

  String _selectedLanguage = _defaultLanguage;
  int _selectedThemeIndex = _defaultThemeIndex;
  bool _isDarkMode = _defaultDarkMode;
  bool _tapSfxEnabled = _defaultSfxEnabled;
  String _selectedSfx = _defaultSfx;
  bool _scanSfxEnabled = _defaultScanSfxEnabled;
  String _selectedScanSfx = _defaultScanSfx;
  
  String _selectedTextSize = _defaultTextSize;
  String _selectedFont = _defaultFont;

  String _selectedModel = _defaultModel;
  double _confidenceThreshold = _defaultConfidence;

  String get selectedLanguage => _selectedLanguage;
  int get selectedThemeIndex => _selectedThemeIndex;
  bool get isDarkMode => _isDarkMode;
  bool get tapSfxEnabled => _tapSfxEnabled;
  String get selectedSfx => _selectedSfx;
  bool get scanSfxEnabled => _scanSfxEnabled;
  String get selectedScanSfx => _selectedScanSfx;
  String get selectedTextSize => _selectedTextSize;
  String get selectedFont => _selectedFont;
  
  String get selectedModel => _selectedModel;
  double get confidenceThreshold => _confidenceThreshold;

  final List<String> languageOptions = ['English', 'Tagalog', 'Bisaya'];
  final List<String> sfxOptions = ['Tap 1', 'Tap 2', 'Tap 3', 'Vibration'];
  final List<String> scanSfxOptions = ['Complete 1', 'Complete 2', 'Complete 3', 'Vibration'];
  
  final List<String> modelOptions = ['v1'];
  
  final List<String> textSizeOptions = ['Small', 'Medium', 'Large'];
  final Map<String, double> textSizeFactors = {
    'Small': 1.0,
    'Medium': 1.15, 
    'Large': 1.3,
  };
  
  final List<String> fontOptions = ['Font 1', 'Font 2', 'Font 3'];

  static const String _langKey = 'selectedLanguage';
  static const String _themeKey = 'selectedThemeIndex';
  static const String _darkModeKey = 'isDarkMode';
  static const String _sfxEnabledKey = 'tapSfxEnabled';
  static const String _sfxKey = 'selectedSfx';
  static const String _scanSfxEnabledKey = 'scanSfxEnabled';
  static const String _scanSfxKey = 'selectedScanSfx';
  static const String _textSizeKey = 'selectedTextSize';
  static const String _fontKey = 'selectedFont';
  static const String _modelKey = 'selectedModel';
  static const String _confidenceKey = 'confidenceThreshold';

  SettingsProvider();

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    _selectedLanguage = _prefs.getString(_langKey) ?? _defaultLanguage;
    _selectedThemeIndex = _prefs.getInt(_themeKey) ?? _defaultThemeIndex;
    _isDarkMode = _prefs.getBool(_darkModeKey) ?? _defaultDarkMode;
    _tapSfxEnabled = _prefs.getBool(_sfxEnabledKey) ?? _defaultSfxEnabled;
    _selectedSfx = _prefs.getString(_sfxKey) ?? _defaultSfx;
    _scanSfxEnabled = _prefs.getBool(_scanSfxEnabledKey) ?? _defaultScanSfxEnabled;
    _selectedScanSfx = _prefs.getString(_scanSfxKey) ?? _defaultScanSfx;
    
    _selectedTextSize = _prefs.getString(_textSizeKey) ?? _defaultTextSize;
    _selectedFont = _prefs.getString(_fontKey) ?? _defaultFont;

    _selectedModel = _prefs.getString(_modelKey) ?? _defaultModel;
    
    if (!modelOptions.contains(_selectedModel)) {
      _selectedModel = _defaultModel;
      await _prefs.setString(_modelKey, _defaultModel);
    }

    _confidenceThreshold = _prefs.getDouble(_confidenceKey) ?? _defaultConfidence;

    await _sfxService.init();

    _isLoading = false;
    notifyListeners();
  }

  static const _kuromiLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF514283),
    onPrimary: Colors.white,
    secondary: Color(0xFFcac5ed), 
    onSecondary: Color(0xFF332E49),
    tertiary: Color(0xFFf0c3e2),
    onTertiary: Color(0xFF332E49),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Color(0xFFe1ddf4),
    onSurface: Color(0xFF332E49),
    surfaceContainerHighest: Color(0xFFcac5ed),
    outline: Color(0xFF514283),
  );

  static const _kuromiDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFcac5ed),
    onPrimary: Color(0xFF221e33),
    primaryContainer: Color(0xFF4F378B),
    onPrimaryContainer: Color(0xFFEADDFF),
    secondary: Color(0xFFf0c3e2),
    onSecondary: Color(0xFF221e33),
    secondaryContainer: Color(0xFF5D3F55),
    onSecondaryContainer: Color(0xFFFFD7F1),
    tertiary: Color(0xFF514283),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF3F3A5E),
    onTertiaryContainer: Color(0xFFE8DEF8),
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Color(0xFF1A1625),
    onSurface: Color(0xFFe1ddf4),
    surfaceContainerHighest: Color(0xFF2D2640),
  );

  static const _melodyLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFbf8d8e),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFD9DE),
    onPrimaryContainer: Color(0xFF3F0008),
    secondary: Color(0xFFf8bdc3),
    onSecondary: Color(0xFF4a2a2a),
    secondaryContainer: Color(0xFFFFD9E2),
    onSecondaryContainer: Color(0xFF3E001D),
    tertiary: Color(0xFFf7d6e1),
    onTertiary: Color(0xFF4a2a2a),
    tertiaryContainer: Color(0xFFFFD8EC),
    onTertiaryContainer: Color(0xFF31111D),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Color(0xFFfdf2fa),
    onSurface: Color(0xFF5E4044),
    surfaceContainerHighest: Color(0xFFfceaf8),
  );

  static const _melodyDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFf8bdc3),
    onPrimary: Color(0xFF2D1F22),
    primaryContainer: Color(0xFF703339),
    onPrimaryContainer: Color(0xFFFFD9DE),
    secondary: Color(0xFFf7d6e1),
    onSecondary: Color(0xFF2D1F22),
    secondaryContainer: Color(0xFF703444),
    onSecondaryContainer: Color(0xFFFFD9E2),
    tertiary: Color(0xFFbf8d8e),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF633B48),
    onTertiaryContainer: Color(0xFFFFD8EC),
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Color(0xFF2D1F22),
    onSurface: Color(0xFFfceaf8),
    surfaceContainerHighest: Color(0xFF422A30),
  );

  static const _cinnamonLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4cb5e8),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFC1E8FF),
    onPrimaryContainer: Color(0xFF001E2F),
    secondary: Color(0xFFffd0e1),
    onSecondary: Color(0xFF1A3B4D),
    secondaryContainer: Color(0xFFFFD9E2),
    onSecondaryContainer: Color(0xFF3E001D),
    tertiary: Color(0xFFfbd8de),
    onTertiary: Color(0xFF1A3B4D),
    tertiaryContainer: Color(0xFFD7E2FF),
    onTertiaryContainer: Color(0xFF001B3F),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Color(0xFFe9dcef),
    onSurface: Color(0xFF1A3B4D),
    surfaceContainerHighest: Color(0xFFc1e7f5),
  );

  static const _cinnamonDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4cb5e8),
    onPrimary: Color(0xFF0D1F29),
    primaryContainer: Color(0xFF004D6F),
    onPrimaryContainer: Color(0xFFC1E8FF),
    secondary: Color(0xFFffd0e1),
    onSecondary: Color(0xFF0D1F29),
    secondaryContainer: Color(0xFF703444),
    onSecondaryContainer: Color(0xFFFFD9E2),
    tertiary: Color(0xFFc1e7f5),
    onTertiary: Color(0xFF0D1F29),
    tertiaryContainer: Color(0xFF234966),
    onTertiaryContainer: Color(0xFFD7E2FF),
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Color(0xFF0D1F29),
    onSurface: Color(0xFFc1e7f5),
    surfaceContainerHighest: Color(0xFF1E3645),
  );

  static const _matchaLight = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF9CCC65), 
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFF9FBE7), 
    onPrimaryContainer: Color(0xFF33691E), 
    secondary: Color(0xFF80CBC4), 
    onSecondary: Color(0xFF004D40),
    secondaryContainer: Color(0xFFE0F2F1), 
    onSecondaryContainer: Color(0xFF004D40),
    tertiary: Color(0xFFDCE775), 
    onTertiary: Color(0xFF33691E),
    tertiaryContainer: Color(0xFFF0F4C3), 
    onTertiaryContainer: Color(0xFF33691E),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Color(0xFFFFFFFF), 
    onSurface: Color(0xFF1B5E20), 
    surfaceContainerHighest: Color(0xFFF1F8E9), 
  );

  static const _matchaDark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFAED581), 
    onPrimary: Color(0xFF1B5E20),
    primaryContainer: Color(0xFF33691E),
    onPrimaryContainer: Color(0xFFDCEDC8),
    secondary: Color(0xFF4DB6AC), 
    onSecondary: Color(0xFF004D40),
    secondaryContainer: Color(0xFF004D40),
    onSecondaryContainer: Color(0xFFB2DFDB),
    tertiary: Color(0xFFDCE775),
    onTertiary: Color(0xFF33691E),
    tertiaryContainer: Color(0xFF827717),
    onTertiaryContainer: Color(0xFFF0F4C3),
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Color(0xFF0C130D), 
    onSurface: Color(0xFFE8F5E9),
    surfaceContainerHighest: Color(0xFF1B5E20),
  );

  ColorScheme get _currentScheme {
    switch (_selectedThemeIndex) {
      case 1: return _isDarkMode ? _melodyDark : _melodyLight;
      case 2: return _isDarkMode ? _cinnamonDark : _cinnamonLight;
      case 3: return _isDarkMode ? _matchaDark : _matchaLight;
      case 0: 
      default: return _isDarkMode ? _kuromiDark : _kuromiLight;
    }
  }

  ColorScheme getThemeSchemeAtIndex(int index) {
    switch (index) {
      case 1: return _isDarkMode ? _melodyDark : _melodyLight;
      case 2: return _isDarkMode ? _cinnamonDark : _cinnamonLight;
      case 3: return _isDarkMode ? _matchaDark : _matchaLight;
      case 0:
      default: return _isDarkMode ? _kuromiDark : _kuromiLight;
    }
  }

  ThemeData get currentTheme {
    final scheme = _currentScheme;
    final double scale = textSizeFactors[_selectedTextSize] ?? 1.0;
    
    String? fontFamily;
    switch (_selectedFont) {
      case 'Font 2':
        fontFamily = 'CustomFont2'; 
        break;
      case 'Font 3':
        fontFamily = 'CustomFont3'; 
        break;
      case 'Font 1':
      default:
        fontFamily = 'CustomFont1'; 
        break;
    }

    final TextTheme explicitTextTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 57.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      displayMedium: TextStyle(fontSize: 45.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      displaySmall: TextStyle(fontSize: 36.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      headlineLarge: TextStyle(fontSize: 32.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      headlineMedium: TextStyle(fontSize: 28.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      headlineSmall: TextStyle(fontSize: 24.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      titleLarge: TextStyle(fontSize: 22.0 * scale, fontFamily: fontFamily, color: scheme.onSurface, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 16.0 * scale, fontFamily: fontFamily, color: scheme.onSurface, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 14.0 * scale, fontFamily: fontFamily, color: scheme.onSurface, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      bodySmall: TextStyle(fontSize: 12.0 * scale, fontFamily: fontFamily, color: scheme.onSurface),
      labelLarge: TextStyle(fontSize: 14.0 * scale, fontFamily: fontFamily, color: scheme.onSurface, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12.0 * scale, fontFamily: fontFamily, color: scheme.onSurface, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11.0 * scale, fontFamily: fontFamily, color: scheme.onSurface, fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: explicitTextTheme, 
      scaffoldBackgroundColor: scheme.surface,
      
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: explicitTextTheme.titleLarge,
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurface.withAlpha(100);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withAlpha(100);
          }
          return scheme.surfaceContainerHighest;
        }),
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withAlpha(30),
      ),
    );
  }

  Future<void> changeLanguage(String? newLanguage) async {
    if (newLanguage == null) return;
    _selectedLanguage = newLanguage;
    await _prefs.setString(_langKey, newLanguage);
    notifyListeners();
  }

  Future<void> changeTheme(int themeIndex) async {
    _selectedThemeIndex = themeIndex;
    await _prefs.setInt(_themeKey, themeIndex);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await _prefs.setBool(_darkModeKey, enabled);
    notifyListeners();
  }
  
  Future<void> changeTextSize(String? newSize) async {
    if (newSize == null) return;
    _selectedTextSize = newSize;
    await _prefs.setString(_textSizeKey, newSize);
    notifyListeners();
  }

  Future<void> changeFont(String? newFont) async {
    if (newFont == null) return;
    _selectedFont = newFont;
    await _prefs.setString(_fontKey, newFont);
    notifyListeners();
  }

  Future<void> toggleTapSfx(bool isEnabled) async {
    _tapSfxEnabled = isEnabled;
    await _prefs.setBool(_sfxEnabledKey, isEnabled);
    notifyListeners();
  }

  Future<void> changeSfx(String? newSfx) async {
    if (newSfx == null) return;
    _selectedSfx = newSfx;
    await _prefs.setString(_sfxKey, newSfx);
    notifyListeners();
  }

  Future<void> toggleScanSfx(bool isEnabled) async {
    _scanSfxEnabled = isEnabled;
    await _prefs.setBool(_scanSfxEnabledKey, isEnabled);
    notifyListeners();
  }

  Future<void> changeScanSfx(String? newSfx) async {
    if (newSfx == null) return;
    _selectedScanSfx = newSfx;
    await _prefs.setString(_scanSfxKey, newSfx);
    notifyListeners();
  }

  Future<void> changeModel(String? newModel) async {
    if (newModel == null) return;
    _selectedModel = newModel;
    await _prefs.setString(_modelKey, newModel);
    notifyListeners();
  }

  Future<void> changeConfidenceThreshold(double newVal) async {
    _confidenceThreshold = newVal;
    await _prefs.setDouble(_confidenceKey, newVal);
    notifyListeners();
  }

  void playTapSound() {
    if (_tapSfxEnabled) {
      if (_selectedSfx == 'Vibration') {
        HapticFeedback.lightImpact();
      } else {
        _sfxService.play(_selectedSfx);
      }
    }
  }

  void playScanSound() {
    if (_scanSfxEnabled) {
      if (_selectedScanSfx == 'Vibration') {
        _sfxService.play('Vibration (Long)'); 
      } else {
        _sfxService.play(_selectedScanSfx);
      }
    }
  }

  @override
  void dispose() {
    _sfxService.dispose();
    super.dispose();
  }

  String translate(String key) {
    if (_localizedStrings.containsKey(_selectedLanguage) &&
        _localizedStrings[_selectedLanguage]!.containsKey(key)) {
      return _localizedStrings[_selectedLanguage]![key]!;
    }
    return _localizedStrings['English']![key] ?? key;
  }

  String getTranslatedSoundName(String soundName) {
    String key = soundName.toLowerCase().replaceAll(' ', '_');
    return translate(key);
  }

  final Map<String, Map<String, String>> _localizedStrings = {
    'English': {
      'language': 'Language',
      'app_theme': 'App Theme',
      'dark_mode': 'Dark Mode',
      'text_settings': 'Text Settings',
      'text_size': 'Text Size',
      'font_style': 'Font Style',
      'small': 'Small',
      'medium': 'Medium',
      'large': 'Large',
      'font_1': 'Font 1',
      'font_2': 'Font 2',
      'font_3': 'Font 3',
      'sounds': 'Sounds',
      'tap_feedback': 'Tap Feedback',
      'enable_tap': 'Enable Tap Feedback',
      'scan_feedback': 'Scan Complete',
      'enable_scan': 'Enable Scan Feedback',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'choose_file': 'Choose File',
      'scan_prompt': 'Image selected. Press the scan button below!',
      'initializing_camera': 'Initializing Camera...',
      'open_settings': 'Open Settings',
      'permission_needed': 'Permission is needed to access photos.',
      'error_camera': 'Error initializing camera',
      'tap_1': 'Tap 1', 'tap_2': 'Tap 2', 'tap_3': 'Tap 3',
      'complete_1': 'Complete 1', 'complete_2': 'Complete 2', 'complete_3': 'Complete 3',
      'vibration': 'Vibration',
      'scan_result': 'Scan Result',
      'welcome_title': 'Welcome to CAPE!',
      'welcome_body': "Cacao arrived in the Philippines way back in 1670, brought over by Spanish ships from Mexico through the Manila-Acapulco galleon trade. Thanks to the country’s warm and rainy climate, cacao thrived and became deeply woven into Filipino traditions, especially in chocolate products and drinks like tablea. Philippine farmers have raised cacao for centuries, and today, the country is celebrated for its world-class beans and growing chocolate industry.",
      'threats_title': 'Cacao Pod Diseases & Pests',
      'threats_subtitle': 'Our app helps you identify and manage these common cacao pod problems:',
      'blackpod_title': 'Blackpod Rot',
      'blackpod_what': "Blackpod rot is a fast-spreading fungal disease. It shows up as dark, sometimes fuzzy, black patches on cacao pods, which quickly ruin the beans inside.",
      'blackpod_spread': "It mainly spreads during rainy or humid weather. Rain, water in the soil, and even insects can move fungal spores from one pod to another.",
      'borer_title': 'Cacao Pod Borer',
      'borer_what': "The pod borer is a tiny moth whose young (larvae) burrow right into cacao pods. Inside, they mess up the beans and make pods hard and difficult to open.",
      'borer_spread': "Pod borers travel when infested pods, leaves, or debris are moved or when adult moths fly to new trees. Having pods on trees all the time gives them more places to lay eggs and breed.",
      'mirid_title': 'Mirid Bugs',
      'mirid_what': "Mirid bugs are small insects that use long, needle-like mouths to poke cacao pods and shoots. This causes little black spots, cankers, and sometimes kills parts of the plant or causes pods to fall early.",
      'mirid_spread': "Adult bugs fly from plant to plant, especially where there are lots of new shoots after rain. Young bugs can crawl to nearby parts. Mirid populations boom during wet seasons in unpruned or overgrown farms.",
      'climate_title': 'How Climate Affects Cacao & Its Threats',
      'climate_body': "Cacao trees love warm, humid places with steady rainfall—just like most of the Philippines. But the same climate also encourages diseases like blackpod rot and pests such as pod borers and mirid bugs to thrive. Rain and humidity make it easier for fungus and bugs to spread. That’s why it’s important for farmers to keep their fields clean, manage tree growth, and adjust habits as the weather changes to help keep cacao healthy.",
      'what_is_it': 'What is it?',
      'how_spread': 'How does it spread?',
      'tap_close': 'Tap to close',
      'tap_open': 'Tap to open',
      'history_loading': 'Loading History...',
      'history_no_history': 'No History Yet',
      'history_prompt': 'Your scan history will appear here',
      'history_delete_title': 'Delete Entry?',
      'history_delete_confirm': 'This action cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'id_label': 'ID',
      'detection_label': 'detection',
      'detections_label': 'detections',
      'analyzing_image': 'Analyzing Image...',
      'condition_detected': 'condition detected',
      'conditions_detected': 'conditions detected',
      'no_conditions_detected_short': 'No conditions detected',
      'view_all': 'View All',
      'all_detections': 'All Detections',
      'confidence': 'confidence',
      'condition_overview_title': 'Condition Overview',
      'detailed_analysis_title': 'Detailed Analysis',
      'prevention_title': 'Prevention & Management',
      'additional_info_title': 'Additional Information',
      'no_conditions_title': 'No Conditions Detected',
      'no_conditions_body': 'The image appears to be free of detectable cocoa pod conditions. This could indicate a healthy pod or that the condition is not visible in this image.',
      'search': 'Search',
      'filter_sort': 'Filter & Sort',
      'sort_order': 'Sort Order',
      'newest': 'Newest',
      'oldest': 'Oldest',
      'date_range': 'Date Range',
      'clear_dates': 'Clear Dates',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'contains_class': 'Contains Class',
      'no_detections': 'No Detections',
      'no_results': 'No files match your filters',
      'reset_all': 'Reset All',
      'apply': 'Apply',
      'file_label': 'File',
      'delete_all_title': 'Delete All Entries?',
      'delete_all_confirm': 'This will permanently delete all history records and images. This cannot be undone.',
      'delete_all_button': 'Delete All',
      'inference_settings': 'Inference Settings',
      'model_version': 'Model Version',
      'confidence_threshold': 'Confidence Threshold',
      'v1': 'CAPE',
      'v2': 'v2 (Pod Borer)',
      'experimental': 'Experimental',
      'back': 'Back',
      'performance_overview': 'Performance Overview',
      'total_scans': 'Total Scans',
      'detections_title': 'Detections',
      'detection_rate': 'Detection Rate',
      'most_detected': 'Most Detected',
      'disease_distribution': 'Disease Distribution',
      'model_confidence': 'Model Confidence',
      'weekly_activity': 'Weekly Activity',
      'today': 'Today',
      'credits_title': 'CREDITS',
      'credits_developed_by': 'Developed By',
      'credits_lead_dev': 'Lead Developer',
      'credits_thesis_leader': 'Thesis Leader',
      'credits_researcher': 'Researcher',
      'credits_partnership': 'In Partnership With',
      'credits_head_cfan': 'Head, CFAN',
      'credits_validation': 'Institutional Validation',
      'credits_isp_manager': 'ISP Manager for Cacao - DOST-PCAARRD',
      'credits_built_with': 'Built With',
      'credits_app_framework': 'App Framework',
      'credits_object_detection': 'Object Detection Model',
      'credits_ml_inference': 'ML Inference',
      'credits_special_thanks': 'SPECIAL THANKS',
      'credits_lspu': 'Laguna State Polytechnic University',
      'credits_lspu_campus': 'Santa Cruz Main Campus',
      'credits_cfan_farmers': 'The CFAN Farmers',
      'credits_farmers_list': 'Rodrigo C. Monteiro • Sanybeth Adela B. Cuento • Primitiva S. Matienzo • Meredita D. Lucido • Perlita N. Formeloza • Antonio Viterbo • Danilo Sotomango • Edmer Orijila • Juliana Suministrado • Garry U. Isleta • Leonida M. Manzano • Felix D. Encarnacion Sr. • Angelito A. Vitangcol Jr. • Rosalinda C. Encarnacion • Joanne Orencia-Bautista • Belinda B. • Liwayway A. Constantino • Laila M. Bagsit • Susan U. Bagsit • John P. Dorado • Imelda V. Dorado • Narcisa A. Joya • Jessica Comendador • Virgilio A. Arban',
      'credits_footer_button': 'From the Students, For everyone',
      'credits_cape_dev_team': 'CAPE Development Team',
      'credits_all_rights': 'Laguna State Polytechnic University\nAll rights reserved.',
      'cape_description': 'Cacao App for Pod Evaluation',
      'cape_version': 'Version 1.0',
      'credits_cape_title': 'CAPE',
      'credits_cape_subtitle': 'Cacao App for Pod Evaluation',
      'credits_cape_body': 'A Flutter-based deep learning mobile application built to detect cacao pod diseases in real time using YOLOv11s object detection. Born from the determination of three state university students who spent months balancing source code, endless paperwork, sleepless revision nights, and unstable internet connections.\n\nBehind every line of this application lives the quiet, unyielding belief that technology should find its way to the people who need it most. We built CAPE for the Filipino cacao farmers who have waited long enough.',
      'credits_ground_truth_title': 'The Ground Truth',
      'credits_ground_truth_subtitle': 'Where the Real Work Happens',
      'credits_ground_truth_body': 'Before there were datasets, annotations, confidence scores, or validation metrics, there were farmers standing beneath unforgiving heat carrying entire harvest seasons on their backs. You are the people who rise before sunrise to inspect cacao pods one by one, searching for signs of disease before infection spreads through months of careful labor.',
      'credits_cfan_title': 'The CFAN Farmers',
      'credits_cfan_body': 'Rodrigo C. Monteiro • Sanybeth Adela B. Cuento • Primitiva S. Matienzo • Meredita D. Lucido • Perlita N. Formeloza • Antonio Viterbo • Danilo Sotomango • Edmer Orijila • Juliana Suministrado • Garry U. Isleta • Leonida M. Manzano • Felix D. Encarnacion Sr. • Angelito A. Vitangcol Jr. • Rosalinda C. Encarnacion • Joanne Orencia-Bautista • Belinda B. • Liwayway A. Constantino • Laila M. Bagsit • Susan U. Bagsit • John P. Dorado • Imelda V. Dorado • Narcisa A. Joya • Jessica Comendador • Virgilio A. Arban\n\nYou are the first line of defense against a problem that does not wait for better weather, larger budgets, or more convenient timing. All of you were THE ground truth long before we had a model to train.',
      'credits_reality_caption': 'The Reality We Aim to Protect',
      'credits_architecture_title': 'The Architecture Shift',
      'credits_architecture_subtitle': 'Beyond Image Classification',
      'credits_architecture_body': 'This thesis did not begin fully formed. Our initial deployment was built on Capacitor and relied on basic image classification. We quickly realized this architecture could not meet the actual demands of the field. A single image of a tree contains multiple cacao pods, each potentially suffering from different conditions—something simple classification could not accurately discern.\n\nWe needed the precision of bounding boxes and real-time object detection. We discarded the legacy codebase, rebuilt entirely in Flutter, and integrated YOLOv11s to evaluate every individual pod independently. We built for reality.',
      'credits_legacy_caption': 'The Legacy Capacitor Build',
      'credits_teaching_title': 'Teaching a Machine to See',
      'credits_chaos_subtitle': 'The Chaos of Early Epochs',
      'credits_chaos_body': 'Machine learning sounds elegant until you actually try to teach an algorithm about the physical world. In the beginning, our neural network saw patterns where none existed. Pixels bled across the UI. Detections misaligned. The application tore its own bounding boxes apart in a desperate attempt to make sense of the camera feed.',
      'credits_glitch_caption': 'One Bug Out of Many · The Bounding Box Glitch',
      'credits_faces_subtitle': 'When Faces Became Pods',
      'credits_faces_body': 'A model only knows what it is taught. During one particularly exhausting testing phase, our weights were so unbalanced that the system started aggressively identifying human faces as cacao pods. Every false positive forced us back into the dataset. We cleaned, we filtered, we spent nights drawing thousands of new annotation boxes, forcing the model to understand the distinct, quiet difference between a human being and a diseased crop.',
      'credits_false_positive_caption': 'The False Positive Era',
      'credits_enemy_title': 'The Real Enemy',
      'credits_rot_subtitle': 'The Rot That Steals Seasons',
      'credits_rot_body': 'We were not building a generic object detector. We were building a weapon against specific agricultural threats. We had to train the model to look past the healthy green and yellow hues and spot the encroaching dark lesions that signal devastation for a farming family.',
      'credits_target_caption': 'Black Pod Rot · The Target',
      'credits_convergence_title': 'Convergence',
      'credits_signal_subtitle': 'Finding the Signal in the Noise',
      'credits_signal_body': 'Eventually, the endless Colab sessions paid off. The loss curves dropped. The precision spiked. The model finally learned how to discern a genuine cacao pod from its background environment, completely ignoring non-cacao objects. It was no longer guessing. It was knowing.',
      'credits_precision_caption': 'Precision Achieved',
      'credits_proof_caption': 'The Mathematical Proof',
      'credits_resilience_subtitle': 'Resilience Against the Elements',
      'credits_resilience_body': 'We threw heavily modified, broken-down, degraded images at the model to simulate the absolute worst lighting and camera conditions a low-end smartphone could produce. The bounding boxes held. The YOLOv11s architecture proved it could survive the chaotic variables of the real world.',
      'credits_inference_caption': 'Inference Under Extreme Degradation',
      'credits_field_title': 'The Field Test',
      'credits_silence_subtitle': 'The Silence Before Detections',
      'credits_silence_body': 'The thesis stopped being theoretical the moment we brought it into actual farms and placed the application into the hands of agricultural personnel. Real sunlight. Real cacao pods. Real uncertainty.\n\nThere is a terrifying silence that exists in the moments before pressing the camera button during a live demonstration. Months of work collapse into a single instant where the system either functions or fails in front of experts who know the field better than we ever will.',
      'credits_deployment_caption': 'Deployment',
      'credits_soil_caption': 'The Technology Meets the Soil',
      'credits_output_subtitle': 'The Output',
      'credits_output_body': 'It worked. The predictions logged successfully into the local history base. The offline architecture held up precisely as designed, requiring zero internet connectivity to deliver disease diagnostics straight into the palms of the people evaluating the crops.',
      'credits_history_caption': 'Diagnostic History in Production',
      'credits_people_title': 'The People',
      'credits_team_subtitle': 'The Team and the Community',
      'credits_team_body': 'Erl Teodemar D. Sofer (Lead Developer), Nixon E. Coronado (Thesis Leader), and Riana Alexis C. Bagalso (Researcher). Three students who refused to surrender to impossible timelines. But we did not do this alone. We stood alongside Marites O. Caña, head of the Cacao Farmers Association of Nagcarlan, translating their generational knowledge into our datasets.',
      'credits_dev_ground_truth_caption': 'The Developers and the Ground Truth',
      'credits_validation_subtitle': 'Institutional Validation',
      'credits_validation_body': 'We brought the voices of the fields into the highest academic and governmental panels. Presenting to officials like Cer Jay B. Jimenez, ISP Manager for Cacao - DOST-PCAARRD, was not just a defense requirement; it was our attempt to prove that student-led innovation deserves a permanent seat at the table of national agricultural development.',
      'credits_defending_caption': 'Defending the Vision',
      'credits_soundscape_title': 'Soundscape',
      'credits_theme_subtitle': 'Ending Theme',
      'credits_theme_body': 'Letter Song (Arrange / Instrumental)\nOriginal by doriko\nArranged by Official Viewfit\nhttps://youtu.be/WJm5I3Uyz7E',
      'credits_commit_title': 'The Final Commit',
      'credits_lspu_subtitle': 'To Laguna State Polytechnic University\nSanta Cruz Main Campus',
      'credits_lspu_body': 'Thank you for becoming the place where this idea was allowed to exist. Inside your classrooms, hallways, laboratories, and defense rooms, three students slowly transformed uncertainty into something tangible, submittable, and real.\n\nWe carry your name with pride in every page of this manuscript and in every line of this application. Whatever comes next begins here.',
      'credits_generation_subtitle': 'To the Next Generation',
      'credits_generation_body': 'If you inherit this codebase someday, do not treat it as sacred. Break it apart. Refactor the parts that no longer serve the mission. Replace entire systems if you find better ones. Make it faster, smarter, cleaner, and more accessible to the people it was built for.\n\nThe mission matters more than the original implementation. That was always true. Keep it true.',
      'credits_cape_final_title': 'CAPE',
      'credits_cape_final_subtitle': 'Cacao App for Pod Evaluation · Version 1.0',
      'credits_cape_final_body': '"Maging malusog ang inyong cacao."\n"Unta ang inyong cacao magmaayo."\n"May your harvests remain abundant."\n\nFor every farmer still fighting disease beneath the heat of the Philippine sun.\nFor every family whose livelihood grows on trees.\nFor every harvest that deserved better tools.\n\nThis was built for you.\nAll of it.\nAlways.',
    },
    'Tagalog': {
      'language': 'Wika',
      'app_theme': 'Tema ng App',
      'dark_mode': 'Madilim na Tema',
      'text_settings': 'Settings ng Teksto',
      'text_size': 'Laki ng Teksto',
      'font_style': 'Estilo ng Font',
      'small': 'Maliit',
      'medium': 'Katamtaman',
      'large': 'Malaki',
      'font_1': 'Font 1',
      'font_2': 'Font 2',
      'font_3': 'Font 3',
      'sounds': 'Mga Tunog',
      'tap_feedback': 'Tunog sa Pagpindot',
      'enable_tap': 'Paganahin ang Tunog',
      'scan_feedback': 'Tunog Pagkatapos Mag-scan',
      'enable_scan': 'Paganahin ang Tunog',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'choose_file': 'Pumili ng File',
      'scan_prompt': 'Napili na ang larawan. Pindutin ang scan button sa ibaba!',
      'initializing_camera': 'Binubuksan ang Camera...',
      'open_settings': 'Buksan ang Settings',
      'permission_needed': 'Kailangan ng pahintulot upang ma-access ang mga larawan.',
      'error_camera': 'Error sa pagbukas ng camera',
      'tap_1': 'Pindot 1', 'tap_2': 'Pindot 2', 'tap_3': 'Pindot 3',
      'complete_1': 'Tapos 1', 'complete_2': 'Tapos 2', 'complete_3': 'Tapos 3',
      'vibration': 'Vibration',
      'scan_result': 'Resulta ng Scan',
      'welcome_title': 'Maligayang pagdating sa CAPE!',
      'welcome_body': "Dumating ang Cacao sa Pilipinas noong 1670, dala ng mga barkong Espanyol mula sa Mexico sa pamamagitan ng Manila-Acapulco galleon trade. Dahil sa mainit at maulan na klima ng bansa, lumago ang cacao at naging bahagi na ng tradisyong Pilipino, lalo na sa mga inuming tsokolate tulad ng tablea. Ilang siglo nang nagtatanim ng cacao ang mga magsasakang Pilipino, at ngayon, kilala ang bansa sa world-class na beans at lumalagong industriya ng tsokolate.",
      'threats_title': 'Mga Sakit at Peste ng Cacao Pod',
      'threats_subtitle': 'Tumutulong ang aming app na matukoy ang mga karaniwang problema ng cacao:',
      'blackpod_title': 'Blackpod Rot',
      'blackpod_what': "Ang Blackpod rot ay isang sakit na dulot ng fungus na mabilis kumalat. Makikita ito bilang madilim at maitim na mga patch sa cacao pods, na mabilis sumisira sa mga beans sa loob.",
      'blackpod_spread': "Kumakalat ito lalo na tuwing maulan o mahalumigmig ang panahon. Ang ulan, tubig sa lupa, at maging ang mga insekto ay maaaring maglipat ng fungal spores mula sa isang pod patungo sa iba.",
      'borer_title': 'Cacao Pod Borer',
      'borer_what': "Ang pod borer ay isang maliit na gamugamo na ang mga uod (larvae) ay bumabaon sa loob ng cacao pods. Sa loob, sinisira nito ang mga beans at ginagawang matigas at mahirap buksan ang pods.",
      'borer_spread': "Kumakalat ang pod borers kapag inilipat ang mga apektadong pods, dahon, o basura, o kapag lumipad ang mga gamugamo sa bagong puno. Ang pagkakaroon ng bunga sa puno sa lahat ng oras ay nagbibigay sa kanila ng lugar para mangitlog at dumami.",
      'mirid_title': 'Mirid Bugs',
      'mirid_what': "Ang Mirid bugs ay maliliit na insekto na gumagamit ng mahahabang bibig para tusukin ang cacao pods at shoots. Nagdudulot ito ng itim na batik, cankers, at minsan ay pagkamatay ng bahagi ng halaman o maagang pagkahulog ng bunga.",
      'mirid_spread': "Ang mga insekto ay lumilipad mula sa isang halaman patungo sa iba, lalo na kung may bagong sibol pagkatapos ng ulan. Ang mga batang insekto ay gumagapang. Dumadami ang Mirid tuwing tag-ulan sa mga sakahan na hindi nalilinis o napuputulan ng sanga.",
      'climate_title': 'Epekto ng Klima sa Cacao',
      'climate_body': "Gusto ng cacao ang mainit at maulan na lugar—tulad ng karamihan sa Pilipinas. Ngunit ang klimang ito ay pabor din sa mga sakit tulad ng blackpod rot and mga peste tulad ng pod borers at mirid bugs. Mas madaling kumalat ang fungus at insekto kapag maulan at mahalumigmig. Kaya mahalagang panatilihing malinis ang sakahan, ayusin ang paglago ng puno, at iakma ang pag-aalaga depende sa pagbabago ng panahon para manatiling malusog ang cacao.",
      'what_is_it': 'Ano ito?',
      'how_spread': 'Paano ito kumakalat?',
      'tap_close': 'I-tap para isara',
      'tap_open': 'I-tap para buksan',
      'history_loading': 'Kinukuha ang Kasaysayan...',
      'history_no_history': 'Wala pang Kasaysayan',
      'history_prompt': 'Dito lalabas ang iyong scan history',
      'history_delete_title': 'Burahin ang Entry?',
      'history_delete_confirm': 'Hindi na ito maibabalik.',
      'cancel': 'Kanselahin',
      'delete': 'Burahin',
      'id_label': 'ID',
      'detection_label': 'kondisyon',
      'detections_label': 'mga kondisyon',
      'analyzing_image': 'Sinusuri ang Larawan...',
      'condition_detected': 'kondisyon ang natukoy',
      'conditions_detected': 'mga kondisyon ang natukoy',
      'no_conditions_detected_short': 'Walang natukoy na kondisyon',
      'view_all': 'Tingnan Lahat',
      'all_detections': 'Lahat ng Natukoy',
      'confidence': 'kumpiyansa',
      'condition_overview_title': 'Pangkalahatang-ideya',
      'detailed_analysis_title': 'Detalyadong Pagsusuri',
      'prevention_title': 'Pag-iwas at Pamamahala',
      'additional_info_title': 'Karagdagang Impormasyon',
      'no_conditions_title': 'Walang Kondisyon na Natukoy',
      'no_conditions_body': 'Ang larawan ay mukhang walang nakikitang sakit o peste. Maaaring ito ay malusog o hindi lang nakikita ang kondisyon sa larawang ito.',
      'search': 'Maghanap',
      'filter_sort': 'Salain at Ayusin',
      'sort_order': 'Ayos ng Pagkakasunod',
      'newest': 'Pinakabago',
      'oldest': 'Pinakaluma',
      'date_range': 'Saklaw ng Petsa',
      'clear_dates': 'Alisin ang Petsa',
      'start_date': 'Simulang Petsa',
      'end_date': 'Huling Petsa',
      'contains_class': 'Naglalaman ng',
      'no_detections': 'Walang Natukoy',
      'no_results': 'Walang tugma sa filter',
      'reset_all': 'I-reset Lahat',
      'apply': 'Ilapat',
      'file_label': 'File',
      'delete_all_title': 'Burahin Lahat?',
      'delete_all_confirm': 'Permanenteng buburahin nito ang lahat ng history at larawan. Hindi na ito maibabalik.',
      'delete_all_button': 'Burahin Lahat',
      'inference_settings': 'Settings ng Pagsusuri',
      'model_version': 'Bersyon ng Modelo',
      'confidence_threshold': 'Antas ng Kumpiyansa',
      'v1': 'CAPE',
      'v2': 'v2 (May Borer)',
      'experimental': 'Eksperimental',
      'back': 'Bumalik',
      'performance_overview': 'Pangkalahatang Pagganap',
      'total_scans': 'Kabuuang Scan',
      'detections_title': 'Mga Nakita',
      'detection_rate': 'Antas ng Pagtukoy',
      'most_detected': 'Pinakamadalas Makita',
      'disease_distribution': 'Distribusyon ng Sakit',
      'model_confidence': 'Kumpiyansa ng Modelo',
      'weekly_activity': 'Lingguhang Aktibidad',
      'today': 'Ngayon',
      'credits_title': 'MGA KREDITS',
      'credits_developed_by': 'Binuo Ni',
      'credits_lead_dev': 'Pangunahing Developer',
      'credits_thesis_leader': 'Lider ng Tesis',
      'credits_researcher': 'Mananaliksik',
      'credits_partnership': 'Katuwang Ang',
      'credits_head_cfan': 'Pinuno, CFAN',
      'credits_validation': 'Institusyonal na Pagpapatibay',
      'credits_isp_manager': 'ISP Manager para sa Cacao - DOST-PCAARRD',
      'credits_built_with': 'Ginawa Gamit Ang',
      'credits_app_framework': 'App Framework',
      'credits_object_detection': 'Modelo sa Pagtukoy ng Bagay',
      'credits_ml_inference': 'ML Inference',
      'credits_special_thanks': 'ESPESYAL NA PASASALAMAT',
      'credits_lspu': 'Laguna State Polytechnic University',
      'credits_lspu_campus': 'Santa Cruz Main Campus',
      'credits_cfan_farmers': 'Ang Mga Magsasaka ng CFAN',
      'credits_farmers_list': 'Rodrigo C. Monteiro • Sanybeth Adela B. Cuento • Primitiva S. Matienzo • Meredita D. Lucido • Perlita N. Formeloza • Antonio Viterbo • Danilo Sotomango • Edmer Orijila • Juliana Suministrado • Garry U. Isleta • Leonida M. Manzano • Felix D. Encarnacion Sr. • Angelito A. Vitangcol Jr. • Rosalinda C. Encarnacion • Joanne Orencia-Bautista • Belinda B. • Liwayway A. Constantino • Laila M. Bagsit • Susan U. Bagsit • John P. Dorado • Imelda V. Dorado • Narcisa A. Joya • Jessica Comendador • Virgilio A. Arban',
      'credits_footer_button': 'Mula sa mga Estudyante, Para sa lahat',
      'credits_cape_dev_team': 'Koponan sa Pagbuo ng CAPE',
      'credits_all_rights': 'Laguna State Polytechnic University\nReserbado ang lahat ng karapatan.',
      'cape_description': 'Cacao App for Pod Evaluation',
      'cape_version': 'Bersyon 1.0',
      'credits_cape_title': 'CAPE',
      'credits_cape_subtitle': 'Cacao App for Pod Evaluation',
      'credits_cape_body': 'Isang deep learning mobile application na binuo sa Flutter para matukoy ang mga sakit ng cacao pod sa real time gamit ang YOLOv11s object detection. Binuo mula sa determinasyon ng tatlong estudyante na gumugol ng maraming buwan sa pagbalanse ng code, napakaraming paperwork, puyatan, at hindi matatag na internet.\n\nSa likod ng bawat linya ng application na ito ay ang tahimik at matibay na paniniwala na ang teknolohiya ay dapat makarating sa mga taong higit na nangangailangan nito. Binuo namin ang CAPE para sa mga magsasakang Pilipino na matagal nang naghihintay.',
      'credits_ground_truth_title': 'Ang Katotohanan sa Bukid',
      'credits_ground_truth_subtitle': 'Kung Saan Nangyayari ang Tunay na Trabaho',
      'credits_ground_truth_body': 'Bago pa man magkaroon ng mga dataset, annotation, confidence score, o metrics, nariyan ang mga magsasaka na nakatayo sa ilalim ng matinding init, dala ang buong panahon ng pag-aani sa kanilang mga likod. Kayo ang mga taong bumabangon bago pa sumikat ang araw upang suriin ang mga cacao pod isa-isa, naghahanap ng senyales ng sakit bago pa man ito kumalat sa loob ng ilang buwang pag-aalaga.',
      'credits_cfan_title': 'Ang mga Magsasaka ng CFAN',
      'credits_cfan_body': 'Rodrigo C. Monteiro • Sanybeth Adela B. Cuento • Primitiva S. Matienzo • Meredita D. Lucido • Perlita N. Formeloza • Antonio Viterbo • Danilo Sotomango • Edmer Orijila • Juliana Suministrado • Garry U. Isleta • Leonida M. Manzano • Felix D. Encarnacion Sr. • Angelito A. Vitangcol Jr. • Rosalinda C. Encarnacion • Joanne Orencia-Bautista • Belinda B. • Liwayway A. Constantino • Laila M. Bagsit • Susan U. Bagsit • John P. Dorado • Imelda V. Dorado • Narcisa A. Joya • Jessica Comendador • Virgilio A. Arban\n\nKayo ang unang depensa laban sa problemang hindi naghihintay ng mas maayos na panahon, mas malaking budget, o mas maginhawang pagkakataon. Kayo ang nagsilbing "ground truth" bago pa kami nagkaroon ng modelong sasanayin.',
      'credits_reality_caption': 'Ang Katotohanang Layunin Naming Protektahan',
      'credits_architecture_title': 'Ang Pagbabago sa Arkitektura',
      'credits_architecture_subtitle': 'Higit Pa sa Pag-uuri ng Larawan',
      'credits_architecture_body': 'Hindi agad nabuo ang tesis na ito sa ganitong anyo. Ang aming unang deployment ay binuo sa Capacitor at umasa lamang sa simpleng image classification. Mabilis naming napagtanto na hindi nito kayang matugunan ang aktwal na pangangailangan sa bukid. Ang isang larawan ng puno ay naglalaman ng maraming cacao pod, na bawat isa ay maaaring may iba\'t ibang kondisyon—bagay na hindi kayang matukoy nang tama ng simpleng classification.\n\nKailangan namin ng katumpakan ng bounding boxes at real-time object detection. Binuwag namin ang lumang codebase, muling binuo sa Flutter, at isinama ang YOLOv11s para masuri ang bawat pod nang indibidwal. Binuo namin ito para sa realidad.',
      'credits_legacy_caption': 'Ang Legacy Capacitor Build',
      'credits_teaching_title': 'Pagtuturo sa Makina na Makakita',
      'credits_chaos_subtitle': 'Ang Kaguluhan ng mga Unang Epoch',
      'credits_chaos_body': 'Ang machine learning ay mukhang elegante hanggang sa subukan mong turuan ang algorithm tungkol sa pisikal na mundo. Sa simula, nakakita ang aming neural network ng mga pattern kung saan wala naman. Nagkalat ang mga pixel sa UI. Maling-mali ang detections. Pinunit ng application ang sarili nitong bounding boxes sa desperadong pagtatangkang intindihin ang camera feed.',
      'credits_glitch_caption': 'Isang Bug sa Napakarami · Ang Bounding Box Glitch',
      'credits_faces_subtitle': 'Nang Maging Pod ang mga Mukha',
      'credits_faces_body': 'Ang modelo ay natututo lamang base sa itinuturo dito. Sa isang mapanghamong bahagi ng testing, ang aming timbang (weights) ay hindi balanse kaya sinimulan ng system na kilalanin ang mga mukha ng tao bilang cacao pods. Bawat maling detect ay nagbabalik sa amin sa dataset. Naglinis kami, nag-filter, at gumugol ng mga gabi sa paggawa ng libu-libong bagong annotation boxes para matutunan ng modelo ang pagkakaiba ng tao sa pananim.',
      'credits_false_positive_caption': 'Ang Panahon ng False Positive',
      'credits_enemy_title': 'Ang Tunay na Kalaban',
      'credits_rot_subtitle': 'Ang Pagkabulok na Nagnanakaw ng Ani',
      'credits_rot_body': 'Hindi lang kami bumubuo ng generic object detector. Bumubuo kami ng sandata laban sa mga partikular na banta sa agrikultura. Kinailangan naming turuan ang modelo na tumingin lagpas sa malusog na kulay berde at dilaw, at matukoy ang mga madidilim na sugat na senyales ng pagkasira para sa isang magsasaka.',
      'credits_target_caption': 'Black Pod Rot · Ang Target',
      'credits_convergence_title': 'Convergence',
      'credits_signal_subtitle': 'Paghanap ng Signal sa Gitna ng Noise',
      'credits_signal_body': 'Sa huli, nagbunga ang walang katapusang sessions sa Colab. Bumaba ang loss curves. Tumaas ang precision. Sa wakas, natutunan ng modelo kung paano makilala ang tunay na cacao pod mula sa kapaligiran, na binabalewala ang mga bagay na hindi cacao. Hindi na ito nanghuhula. Alam na nito.',
      'credits_precision_caption': 'Natamo na ang Katumpakan',
      'credits_proof_caption': 'Ang Patunay sa Matematika',
      'credits_resilience_subtitle': 'Katatagan Laban sa Panahon',
      'credits_resilience_body': 'Binigyan namin ang modelo ng mga modified, sira, at degraded na mga larawan para gayahin ang pinakamalalang kondisyon ng ilaw at camera na maaaring makuha ng isang simpleng smartphone. Nanatili ang mga bounding boxes. Pinatunayan ng YOLOv11s architecture na kaya nitong makaligtas sa magulo at mapaghamong sitwasyon ng totoong mundo.',
      'credits_inference_caption': 'Inference sa Matinding Degradation',
      'credits_field_title': 'Ang Field Test',
      'credits_silence_subtitle': 'Ang Katahimikan Bago ang mga Detection',
      'credits_silence_body': 'Huminto ang pagiging teoretikal ng tesis nang dinala namin ito sa aktwal na mga sakahan at ipinasa ang application sa mga kamay ng mga agricultural personnel. Totoong sikat ng araw. Totoong cacao pods. Totoong kawalan ng katiyakan.\n\nMay isang nakakatakot na katahimikan sa mga sandali bago pindutin ang camera button sa isang live demonstration. Ang mga buwan ng trabaho ay nagkakaroon ng kahulugan sa isang saglit kung saan ang system ay gagana o mabibigo sa harap ng mga eksperto na mas alam ang bukid kaysa sa amin.',
      'credits_deployment_caption': 'Deployment',
      'credits_soil_caption': 'Teknolohiya Nakaharap sa Lupa',
      'credits_output_subtitle': 'Ang Resulta',
      'credits_output_body': 'Gumana ito. Ang mga prediksyon ay matagumpay na naitala sa lokal na history base. Ang offline architecture ay gumana nang eksakto ayon sa disenyo, na nangangailangan ng zero internet connectivity para maghatid ng diagnostic ng sakit direkta sa mga kamay ng mga nagsusuri ng pananim.',
      'credits_history_caption': 'Diagnostic History sa Produksyon',
      'credits_people_title': 'Ang mga Tao',
      'credits_team_subtitle': 'Ang Koponan at ang Komunidad',
      'credits_team_body': 'Erl Teodemar D. Sofer (Lead Developer), Nixon E. Coronado (Thesis Leader), at Riana Alexis C. Bagalso (Researcher). Tatlong estudyanteng tumangging sumuko sa mga imposible na deadline. Ngunit hindi namin ito nagawa nang mag-isa. Nakasama namin si Marites O. Caña, pinuno ng Cacao Farmers Association of Nagcarlan, sa pagsasalin ng kanilang henerasyong kaalaman sa aming mga dataset.',
      'credits_dev_ground_truth_caption': 'Ang mga Developer at ang Ground Truth',
      'credits_validation_subtitle': 'Institusyonal na Pagpapatibay',
      'credits_validation_body': 'Dinala namin ang mga tinig ng sakahan sa pinakamataas na akademikong panel. Ang pagharap sa mga opisyal tulad ni Cer Jay B. Jimenez, ISP Manager para sa Cacao - DOST-PCAARRD, ay hindi lamang requirement sa depensa; ito ay aming pagsubok na patunayan na ang inobasyong binuo ng mga estudyante ay karapat-dapat sa pwesto sa pag-unlad ng agrikultura sa bansa.',
      'credits_defending_caption': 'Pagdepensa sa Bisyon',
      'credits_soundscape_title': 'Soundscape',
      'credits_theme_subtitle': 'Ending Theme',
      'credits_theme_body': 'Letter Song (Arrange / Instrumental)\nOriginal by doriko\nArranged by Official Viewfit\nhttps://youtu.be/WJm5I3Uyz7E',
      'credits_commit_title': 'Ang Huling Commit',
      'credits_lspu_subtitle': 'Para sa Laguna State Polytechnic University\nSanta Cruz Main Campus',
      'credits_lspu_body': 'Salamat sa pagiging lugar kung saan hinayaang umiral ang ideyang ito. Sa loob ng inyong mga silid-aralan, pasilyo, laboratoryo, at defense rooms, tatlong estudyante ang unti-unting nagbago ng kawalan ng katiyakan tungo sa isang bagay na kongkreto, naipasa, at totoo.\n\nDala namin ang inyong pangalan nang may pagmamalaki sa bawat pahina ng manuscript na ito at sa bawat linya ng application na ito. Kung ano man ang susunod, dito nagsisimula.',
      'credits_generation_subtitle': 'Para sa Susunod na Henerasyon',
      'credits_generation_body': 'Kung mamanahin mo ang codebase na ito balang araw, huwag mo itong ituring na sagrado. Paghiwalayin mo ang mga bahagi nito. I-refactor ang mga bahagi na hindi na nagsisilbi sa misyon. Palitan ang buong system kung makakahanap ka ng mas mahusay. Gawin itong mas mabilis, mas matalino, mas malinis, at mas accessible para sa mga taong binuo ito.\n\nAng misyon ay mas mahalaga kaysa sa orihinal na implementasyon. Lagi itong totoo. Panatilihin itong totoo.',
      'credits_cape_final_title': 'CAPE',
      'credits_cape_final_subtitle': 'Cacao App for Pod Evaluation · Bersyon 1.0',
      'credits_cape_final_body': '"Maging malusog ang inyong cacao."\n"Unta ang inyong cacao magmaayo."\n"May your harvests remain abundant."\n\nPara sa bawat magsasaka na patuloy na lumalaban sa sakit sa ilalim ng init ng araw.\nPara sa bawat pamilya na ang kabuhayan ay lumalago sa mga puno.\nPara sa bawat ani na nararapat sa mas mahusay na kasangkapan.\n\nIto ay binuo para sa inyo.\nLahat nito.\nPalagi.',
    },
    'Bisaya': {
      'language': 'Pinulongan',
      'app_theme': 'Tema sa App',
      'dark_mode': 'Ngitngit nga Paagi',
      'text_settings': 'Settings sa Teksto',
      'text_size': 'Gidak-on sa Teksto',
      'font_style': 'Estilo sa Font',
      'small': 'Gamay',
      'medium': 'Sakto',
      'large': 'Dako',
      'font_1': 'Font 1',
      'font_2': 'Font 2',
      'font_3': 'Font 3',
      'sounds': 'Mga Tingog',
      'tap_feedback': 'Tingog sa Pislit',
      'enable_tap': 'I-on ang Tingog',
      'scan_feedback': 'Humana ang Scan',
      'enable_scan': 'I-on ang Tingog',
      'gallery': 'Gallery',
      'camera': 'Kamera',
      'choose_file': 'Pagpili og File',
      'scan_prompt': 'Nakapili na. Pislita ang scan button sa ubos!',
      'initializing_camera': 'Gi-andam ang Kamera...',
      'open_settings': 'Ablihi ang Settings',
      'permission_needed': 'Kinahanglan og pagtugot para sa photos.',
      'error_camera': 'Naay error sa kamera',
      'tap_1': 'Pislit 1', 'tap_2': 'Pislit 2', 'tap_3': 'Pislit 3',
      'complete_1': 'Humana 1', 'complete_2': 'Humana 2', 'complete_3': 'Humana 3',
      'vibration': 'Vibrate',
      'scan_result': 'Resulta sa Scan',
      'welcome_title': 'Maayong pag-abot sa CAPE!',
      'welcome_body': "Ang Cacao miabot sa Pilipinas niadtong 1670, dala sa mga barkong Espanyol gikan sa Mexico pinaagi sa Manila-Acapulco galleon trade. Tungod sa init ug ulanon nga klima sa nasud, ni-lambo ang cacao ug nahimong parte na sa tradisyong Pilipino, labi na sa mga tsokolate nga ilimnon sama sa tablea. Pila na ka siglo nga nagatanom og cacao ang mga mag-uuma sa Pilipinas, ug karon, naila na ang nasud sa world-class nga beans ug nagkadako nga industriya sa tsokolate.",
      'threats_title': 'Mga Sakit ug Peste sa Cacao',
      'threats_subtitle': 'Gitabangan ka niini nga app nga mailhan ug masulbad ang mga problema sa cacao:',
      'blackpod_title': 'Blackpod Rot',
      'blackpod_what': "Ang Blackpod rot usa ka sakit nga gikan sa fungus nga paspas mokatag. Makita kini isip itom nga mga patch sa cacao pods, nga dali makadaot sa mga beans sa sulod.",
      'blackpod_spread': "Mokatag kini kasagaran kung ting-ulan o umog ang panahon. Ang ulan, tubig sa yuta, ug bisan ang mga insekto makabalhin sa fungus spores gikan sa usa ka pod ngadto sa lain.",
      'borer_title': 'Cacao Pod Borer',
      'borer_what': "Ang pod borer usa ka gamay nga anunugba (moth) diin ang mga ulod niini (larvae) mokaon sa sulod sa cacao pods. Sa sulod, ilang gubaon ang mga beans ug himoong gahi ug lisud ablihan ang pods.",
      'borer_spread': "Mokatag ang pod borers kung ibalhin ang mga apektadong pods, dahon, o basura, o kung molupad ang mga anunugba sa bagong punoan. Kung kanunay naay bunga ang punoan, mas daghan silag lugar nga pangitlogan ug modaghan.",
      'mirid_title': 'Mirid Bugs',
      'mirid_what': "Ang Mirid bugs mga gagmay nga insekto nga mogamit og taas nga baba para tusokon ang cacao pods ug shoots. Naghatag kini og itom nga lama, cankers, ug usahay makapatay sa parte sa tanom o hinungdan nga matagak ang bunga.",
      'mirid_spread': "Ang mga hamtong nga insekto molupad gikan sa usa ka tanom ngadto sa lain, labi na kung naay bag-ong tubo human sa ulan. Ang mga piso mokamang ra. Modaghan ang Mirid kung ting-ulan sa mga umahan nga wala malimpyohi o maputli og sanga.",
      'climate_title': 'Epekto sa Klima sa Cacao',
      'climate_body': "Ganahan ang cacao sa init ug ulanon nga lugar—sama sa kasagaran sa Pilipinas. Apan kining klima pabor usab sa mga sakit sama sa blackpod rot ug mga peste sama sa pod borers ug mirid bugs aron modaghan. Ang ulan ug umog makapadali sa pagkatag sa fungus ug insekto. Busa importante nga limpyo ang umahan, dumalahon ang pagtubo sa punoan, ug ipahaum ang mga pamaagi base sa panahon aron magpabiling himsog ang cacao.",
      'what_is_it': 'Unsa kini?',
      'how_spread': 'Unsaon kini pagkaylap?',
      'tap_close': 'I-sirado',
      'tap_open': 'Ablihi',
      'history_loading': 'Gikuha ang History...',
      'history_no_history': 'Wala pay History',
      'history_prompt': 'Dinhi makita ang imong scan history',
      'history_delete_title': 'Papason ang Entry?',
      'history_delete_confirm': 'Dili na kini mabalik.',
      'cancel': 'Kanselahon',
      'delete': 'Papason',
      'id_label': 'ID',
      'detection_label': 'kondisyon',
      'detections_label': 'mga kondisyon',
      'analyzing_image': 'Gisusi ang Hulagway...',
      'condition_detected': 'kondisyon ang nakita',
      'conditions_detected': 'mga kondisyon ang nakita',
      'no_conditions_detected_short': 'Walay nakita nga kondisyon',
      'view_all': 'Tan-awa Tanan',
      'all_detections': 'Tanan nga Nakita',
      'confidence': 'kompiyansa',
      'condition_overview_title': 'Kinatibuk-ang Paglantaw',
      'detailed_analysis_title': 'Detalyadong Pagsusi',
      'prevention_title': 'Paglikay ug Pagdumala',
      'additional_info_title': 'Dugang Impormasyon',
      'no_conditions_title': 'Walay Kondisyon nga Nakita',
      'no_conditions_body': 'Ang hulagway murag walay makita nga sakit o peste. Mahimong himsog kini o dili lang makita ang kondisyon sa kini nga hulagway.',
      'search': 'Pangita',
      'filter_sort': 'Simbag ug Han-ay',
      'sort_order': 'Han-ay sa Pagkasunod',
      'newest': 'Pinakabag-o',
      'oldest': 'Pinakadaan',
      'date_range': 'Sakop sa Petsa',
      'clear_dates': 'Papason ang Petsa',
      'start_date': 'Sinugdanan nga Petsa',
      'end_date': 'Katapusan nga Petsa',
      'contains_class': 'Adunay Sulod nga',
      'no_detections': 'Walay Nakita',
      'no_results': 'Walay ni-match sa filter',
      'reset_all': 'I-reset Tanan',
      'apply': 'I-apply',
      'file_label': 'File',
      'delete_all_title': 'Papason Tanan?',
      'delete_all_confirm': 'Permanente kining mopapas sa tanang history ug hulagway. Dili na kini mabalik.',
      'delete_all_button': 'Papason Tanan',
      'inference_settings': 'Settings sa Pagsusi',
      'model_version': 'Bersyon sa Modelo',
      'confidence_threshold': 'Ang-ang sa Kompiyansa',
      'v1': 'CAPE',
      'v2': 'v2 (Naay Borer)',
      'experimental': 'Eksperimental',
      'back': 'Balik',
      'performance_overview': 'Kinatibuk-ang Dagan',
      'total_scans': 'Total nga Scan',
      'detections_title': 'Mga Nakit-an',
      'detection_rate': 'Gikusgon sa Pagtukoy',
      'most_detected': 'Pinakanakit-an',
      'disease_distribution': 'Pag-apod-apod sa Sakit',
      'model_confidence': 'Kompiyansa sa Modelo',
      'weekly_activity': 'Semana nga Kalihokan',
      'today': 'Karon',
      'credits_title': 'MGA KREDITO',
      'credits_developed_by': 'Gibuhat Ni',
      'credits_lead_dev': 'Pangunang Developer',
      'credits_thesis_leader': 'Lider sa Tesis',
      'credits_researcher': 'Tigdukiduki',
      'credits_partnership': 'Kaabag Ang',
      'credits_head_cfan': 'Hepe, CFAN',
      'credits_validation': 'Institusyonal nga Pagpanghimatuud',
      'credits_isp_manager': 'ISP Manager para sa Cacao - DOST-PCAARRD',
      'credits_built_with': 'Gibuhat Gamit Ang',
      'credits_app_framework': 'App Framework',
      'credits_object_detection': 'Modelo sa Pag-ila sa Butang',
      'credits_ml_inference': 'ML Inference',
      'credits_special_thanks': 'ESPESYAL NGA PASALAMAT',
      'credits_lspu': 'Laguna State Polytechnic University',
      'credits_lspu_campus': 'Santa Cruz Main Campus',
      'credits_cfan_farmers': 'Ang Mga Mag-uuma sa CFAN',
      'credits_farmers_list': 'Rodrigo C. Monteiro • Sanybeth Adela B. Cuento • Primitiva S. Matienzo • Meredita D. Lucido • Perlita N. Formeloza • Antonio Viterbo • Danilo Sotomango • Edmer Orijila • Juliana Suministrado • Garry U. Isleta • Leonida M. Manzano • Felix D. Encarnacion Sr. • Angelito A. Vitangcol Jr. • Rosalinda C. Encarnacion • Joanne Orencia-Bautista • Belinda B. • Liwayway A. Constantino • Laila M. Bagsit • Susan U. Bagsit • John P. Dorado • Imelda V. Dorado • Narcisa A. Joya • Jessica Comendador • Virgilio A. Arban',
      'credits_footer_button': 'Gikan sa mga Estudyante, Para sa tanan',
      'credits_cape_dev_team': 'Grupo sa Pag-develop sa CAPE',
      'credits_all_rights': 'Laguna State Polytechnic University\nTanan nga katungod gigahin.',
      'cape_description': 'Cacao App for Pod Evaluation',
      'cape_version': 'Bersyon 1.0',
      'credits_cape_title': 'CAPE',
      'credits_cape_subtitle': 'Cacao App for Pod Evaluation',
      'credits_cape_body': 'Usa ka deep learning mobile application nga gibuhat sa Flutter para mailhan ang mga sakit sa cacao pod sa real time gamit ang YOLOv11s object detection. Gikan sa determinasyon sa tulo ka mga estudyante nga gigugol ang daghang bulan sa pagbalanse sa code, daghang paperwork, puy-anan, ug dili lig-on nga internet.\n\nLuyo sa matag linya sa application niini mao ang hilom ug lig-on nga pagtuo nga ang teknolohiya angay moabot sa mga tawo nga labing nagkinahanglan niini. Gihimo namo ang CAPE para sa mga mag-uuma sa Pilipinas nga dugay na nga naghulat.',
      'credits_ground_truth_title': 'Ang Tinuod sa Umahan',
      'credits_ground_truth_subtitle': 'Asa Mahitabo ang Tinuod nga Trabaho',
      'credits_ground_truth_body': 'Sa wala pa ang mga dataset, annotation, confidence score, o metrics, anaa ang mga mag-uuma nga nagtindog ubos sa grabe nga kainit, nagpas-an sa tibuok panahon sa ting-ani sa ilang mga likod. Kamo ang mga tawo nga momata sa wala pa mosubang ang adlaw para susihon ang mga cacao pod usa-usa, nangita og timailhan sa sakit sa wala pa kini mokaylap sa pipila ka buwan nga pag-atiman.',
      'credits_cfan_title': 'Ang mga Mag-uuma sa CFAN',
      'credits_cfan_body': 'Rodrigo C. Monteiro • Sanybeth Adela B. Cuento • Primitiva S. Matienzo • Meredita D. Lucido • Perlita N. Formeloza • Antonio Viterbo • Danilo Sotomango • Edmer Orijila • Juliana Suministrado • Garry U. Isleta • Leonida M. Manzano • Felix D. Encarnacion Sr. • Angelito A. Vitangcol Jr. • Rosalinda C. Encarnacion • Joanne Orencia-Bautista • Belinda B. • Liwayway A. Constantino • Laila M. Bagsit • Susan U. Bagsit • John P. Dorado • Imelda V. Dorado • Narcisa A. Joya • Jessica Comendador • Virgilio A. Arban\n\nKamo ang unang depensa batok sa problema nga wala maghulat og mas maayo nga panahon, mas dako nga budget, o mas sayon nga higayon. Kamo ang nagsilbing "ground truth" sa wala pa kami nakabaton og modelo nga bansayon.',
      'credits_reality_caption': 'Ang Kamatuoran nga Tumong Namong Protektahan',
      'credits_architecture_title': 'Ang Pagbag-o sa Arkitektura',
      'credits_architecture_subtitle': 'Labaw Pa sa Klasipikasyon sa Hulagway',
      'credits_architecture_body': 'Wala dayon maporma ang tesis niini sa maong porma. Ang among unang deployment gihimo sa Capacitor ug nagsalig lang sa simpleng image classification. Dali namong naamgohan nga dili kini makatubag sa aktuwal nga panginahanglan sa umahan. Ang usa ka hulagway sa kahoy adunay daghang cacao pod, nga matag usa mahimong adunay lainlaing kondisyon—butang nga dili tukma nga mailhan sa simpleng classification.\n\nKinahanglan namo ang katukma sa bounding boxes ug real-time object detection. Gibungkag namo ang karaan nga codebase, gihimo pag-usab sa Flutter, ug giapil ang YOLOv11s para susihon ang matag pod sa tagsa-tagsa. Gihimo namo kini para sa realidad.',
      'credits_legacy_caption': 'Ang Legacy Capacitor Build',
      'credits_teaching_title': 'Pagtudlo sa Makina nga Makakita',
      'credits_chaos_subtitle': 'Ang Kaguliyang sa mga Unang Epoch',
      'credits_chaos_body': 'Ang machine learning morag elegante hangtod nga sulayan nimo pagtudlo ang algorithm bahin sa pisikal nga kalibutan. Sa sinugdanan, ang among neural network nakakita og mga pattern diin wala man unta. Nagkalat ang mga pixel sa UI. Sayop ang mga detection. Gigisi sa application ang kaugalingon niini nga bounding boxes sa desperado nga paningkamot nga masabtan ang camera feed.',
      'credits_glitch_caption': 'Usa ka Bug sa Daghan · Ang Bounding Box Glitch',
      'credits_faces_subtitle': 'Sa dihang ang mga Nawong Nahimong Pod',
      'credits_faces_body': 'Ang modelo makat-on lamang base sa gitudlo niini. Sa usa ka mahagiton nga bahin sa testing, ang among weights wala mabalanse mao nga gisugdan sa system ang pag-ila sa mga nawong sa tawo isip mga cacao pod. Matag sayop nga detect magbalik kanamo sa dataset. Nanglimpyo mi, nag-filter, ug migugol og mga gabii sa paghimo og liboan ka bag-ong annotation boxes para makat-on ang modelo sa kalainan sa tawo ug sa tanom.',
      'credits_false_positive_caption': 'Ang Panahon sa False Positive',
      'credits_enemy_title': 'Ang Tinuod nga Kaaway',
      'credits_rot_subtitle': 'Ang Pagkadunot nga Mokawat sa Ani',
      'credits_rot_body': 'Dili lang kami naghimo og generic object detector. Naghimo kami og hinagiban batok sa mga piho nga hulga sa agrikultura. Kinahanglan namong tudloan ang modelo nga motan-aw lapas sa himsog nga kolor berde ug dalag, ug mailhan ang mga itom nga samad nga timailhan sa pagkaguba para sa usa ka mag-uuma.',
      'credits_target_caption': 'Black Pod Rot · Ang Target',
      'credits_convergence_title': 'Convergence',
      'credits_signal_subtitle': 'Pagpangita sa Signal sa Taliwala sa Noise',
      'credits_signal_body': 'Sa katapusan, namunga ang walay katapusan nga sessions sa Colab. Miubos ang loss curves. Miubos ang precision. Sa katapusan, nakat-on ang modelo unsaon pag-ila sa tinuod nga cacao pod gikan sa palibot, nga gibaliwala ang mga butang nga dili cacao. Dili na kini magtagna-tagna. Kahibalo na kini.',
      'credits_precision_caption': 'Nakab-ot na ang Katukma',
      'credits_proof_caption': 'Ang Patunay sa Matematika',
      'credits_resilience_subtitle': 'Kalig-on Batok sa Panahon',
      'credits_resilience_body': 'Gihatagan namo ang modelo og mga modified, guba, ug degraded nga mga hulagway para sundogon ang pinakagrabe nga kondisyon sa suga ug camera nga mahimong makuha sa usa ka simpleng smartphone. Nagpabilin ang mga bounding box. Gipamatud-an sa YOLOv11s architecture nga makalahutay kini sa magubot ug mahagiton nga sitwasyon sa tinuod nga kalibutan.',
      'credits_inference_caption': 'Inference sa Grabe nga Degradation',
      'credits_field_title': 'Ang Field Test',
      'credits_silence_subtitle': 'Ang Kahilom sa Wala Pa ang mga Detection',
      'credits_silence_body': 'Huminto ang pagka-teoretikal sa tesis sa dihang gidala namo kini sa aktuwal nga mga umahan ug gitunol ang application sa mga kamot sa mga agricultural personnel. Tinuod nga kahayag sa adlaw. Tinuod nga cacao pods. Tinuod nga kawalay kasigurohan.\n\nAdunay usa ka makahahadlok nga kahilom sa mga gutlo sa wala pa i-press ang camera button sa usa ka live demonstration. Ang mga bulan sa trabaho nahimong makahuluganon sa usa ka gutlo diin ang system molihok o mapakyas atubangan sa mga eksperto nga mas nakaila sa umahan kay kanamo.',
      'credits_deployment_caption': 'Deployment',
      'credits_soil_caption': 'Teknolohiya nga Nag-atubang sa Yuta',
      'credits_output_subtitle': 'Ang Resulta',
      'credits_output_body': 'Nilihok kini. Ang mga prediksyon malampuson nga natala sa lokal nga history base. Ang offline architecture nilihok sumala sa disenyo, nga nagkinahanglan og zero internet connectivity para maghatod og diagnostic sa sakit direkta sa mga kamot sa mga nagsusi sa tanom.',
      'credits_history_caption': 'Diagnostic History sa Produksyon',
      'credits_people_title': 'Ang mga Tawo',
      'credits_team_subtitle': 'Ang Grupo ug ang Komunidad',
      'credits_team_body': 'Erl Teodemar D. Sofer (Lead Developer), Nixon E. Coronado (Thesis Leader), ug Riana Alexis C. Bagalso (Researcher). Tulo ka mga estudyante nga midumili sa pag-surender sa imposible nga deadline. Apan wala namo kini gihimo nga kami ra. Kauban namo si Marites O. Caña, hepe sa Cacao Farmers Association of Nagcarlan, sa paghubad sa ilang kahibalo ngadto sa among mga dataset.',
      'credits_dev_ground_truth_caption': 'Ang mga Developer ug ang Ground Truth',
      'credits_validation_subtitle': 'Institusyonal nga Pagpanghimatuod',
      'credits_validation_body': 'Gidala namo ang mga tingog sa umahan ngadto sa kinatas-ang akademikong panel. Ang pag-atubang sa mga opisyal sama ni Cer Jay B. Jimenez, ISP Manager para sa Cacao - DOST-PCAARRD, dili lang requirement sa defense; kini among pagsulay nga pamatud-an nga ang inobasyon nga gihimo sa mga estudyante angayan sa dapit sa pag-uswag sa agrikultura sa nasud.',
      'credits_defending_caption': 'Pagdepensa sa Bisyon',
      'credits_soundscape_title': 'Soundscape',
      'credits_theme_subtitle': 'Ending Theme',
      'credits_theme_body': 'Letter Song (Arrange / Instrumental)\nOriginal by doriko\nArranged by Official Viewfit\nhttps://youtu.be/WJm5I3Uyz7E',
      'credits_commit_title': 'Ang Katapusang Commit',
      'credits_lspu_subtitle': 'Alang sa Laguna State Polytechnic University\nSanta Cruz Main Campus',
      'credits_lspu_body': 'Salamat sa pagkahimong dapit diin gitugotan nga maglungtad kining ideya. Sulod sa inyong mga lawak-saringan, pasilyo, laboratoryo, ug defense rooms, tulo ka mga estudyante ang anam-anam nga nagbag-o sa kawalay kasigurohan ngadto sa usa ka butang nga konkreto, napasar, ug tinuod.\n\nDad-on namo ang inyong ngalan uban sa garbo sa matag panid niining manuscript ug sa matag linya sa application niini. Unsa man ang mosunod, dinhi kini magsugod.',
      'credits_generation_subtitle': 'Alang sa Sunod nga Henerasyon',
      'credits_generation_body': 'Kon panunlon mo kining codebase sa umaabot, ayaw kini isipa nga sagrado. Bungkaga ang mga parte niini. I-refactor ang mga parte nga wala na nagsilbi sa misyon. Ilisi ang tibuok system kon makakita mo og mas maayo. Himoa kini nga mas paspas, mas maalamon, mas limpyo, ug mas accessible para sa mga tawo nga kini gihimo.\n\nAng misyon mas importante kay sa orihinal nga implementasyon. Kanunay kini nga tinuod. Hupti kini nga tinuod.',
      'credits_cape_final_title': 'CAPE',
      'credits_cape_final_subtitle': 'Cacao App for Pod Evaluation · Bersyon 1.0',
      'credits_cape_final_body': '"Maging malusog ang inyong cacao."\n"Unta ang inyong cacao magmaayo."\n"May your harvests remain abundant."\n\nAlang sa matag mag-uuma nga nagpadayon sa pagpakigbisog batok sa sakit ubos sa kainit sa adlaw.\nAlang sa matag pamilya nga ang panginabuhian motubo sa mga kahoy.\nAlang sa matag ani nga angayan sa mas maayo nga kagamitan.\n\nKini gihimo para kaninyo.\nTanan niini.\nKanunay.',
    },
  };
}