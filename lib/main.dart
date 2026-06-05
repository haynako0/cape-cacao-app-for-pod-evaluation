import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'providers/history_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/history_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/about_screen.dart';
import 'screens/result_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => HistoryProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const CocoaRomiApp(),
    ),
  );
}

class CocoaRomiApp extends StatelessWidget {
  const CocoaRomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'CAPE',
      debugShowCheckedModeBanner: false,
      theme: settings.currentTheme,
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) {
            context.read<SettingsProvider>().playTapSound();
          },
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _scanPulseController;
  late final AnimationController _smallPulseController;
  late final AnimationController _rainbowRotationController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const ScanScreen(),
    const AboutScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _scanPulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _smallPulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _rainbowRotationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scanPulseController.dispose();
    _smallPulseController.dispose();
    _rainbowRotationController.dispose();
    super.dispose();
  }

  String _getThemeLogo(int index) {
    switch (index) {
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
    final navProvider = context.watch<NavigationProvider>();
    
    if (_pageController.hasClients && _pageController.page?.round() != navProvider.currentIndex) {
      _pageController.jumpToPage(navProvider.currentIndex);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final provider = context.read<NavigationProvider>();
        if (!provider.handleBackPress()) {
          SystemNavigator.pop();
        }
      },
      child: _buildAppScaffold(context),
    );
  }

  Widget _buildAppScaffold(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final settings = context.watch<SettingsProvider>();
    
    final currentIndex = navProvider.currentIndex;

    final isResultVisible = navProvider.resultImageBytes != null ||
        navProvider.viewingHistoryEntry != null;

    final Animation<double> scanPulse = Tween(begin: 0.95, end: 1.12)
        .animate(CurvedAnimation(
            parent: _scanPulseController, curve: Curves.easeInOut));
    final Animation<double> smallPulse = Tween(begin: 0.9, end: 1.12)
        .animate(CurvedAnimation(
            parent: _smallPulseController, curve: Curves.easeInOut));

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isDark = settings.isDarkMode;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(112),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: isDark 
              ? [] 
              : [
                  BoxShadow(
                      color: colorScheme.primary.withAlpha(50), 
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                  BoxShadow(
                      color: colorScheme.tertiary.withAlpha(40),
                      blurRadius: 30,
                      offset: const Offset(0, 8)),
                ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  if (isResultVisible)
                    _SoundAwareIconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: colorScheme.primary, size: 28),
                      onPressed: () {
                        navProvider.hideResult();
                      },
                    )
                  else
                     AnimatedSwitcher(
                       duration: const Duration(milliseconds: 500),
                       transitionBuilder: (Widget child, Animation<double> animation) {
                         return FadeTransition(opacity: animation, child: child);
                       },
                       child: Image.asset(
                          _getThemeLogo(settings.selectedThemeIndex),
                          key: ValueKey<int>(settings.selectedThemeIndex),
                          height: 50, 
                          width: 50, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image_not_supported_rounded, 
                              size: 40, color: colorScheme.primary.withAlpha(100));
                          },
                       ),
                     ),
                  
                  const SizedBox(width: 12), 

                  if (isResultVisible)
                    Expanded(
                      child: Text(
                        settings.translate('scan_result'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: textTheme.headlineSmall?.copyWith(
                          fontSize: 24.0, 
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "CAPE",
                              style: textTheme.headlineLarge?.copyWith(
                                fontSize: 32.0, 
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                                letterSpacing: 2.0,
                              ),
                            ),
                            
                            Container(
                              height: 30,
                              width: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cacao App",
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    height: 1.0, 
                                  ),
                                ),
                                const SizedBox(height: 2), 
                                Text(
                                  "for Pod Evaluation",
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 10.0,
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
          if (isResultVisible) const ResultScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
                boxShadow: isDark 
                  ? [] 
                  : [
                      BoxShadow(
                          color: colorScheme.primary.withAlpha(50),
                          blurRadius: 20,
                          offset: const Offset(0, -4)),
                    ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ScaleTransition(
                          scale: smallPulse,
                          child: _buildFooterIcon(
                              Icons.home_rounded, 0, currentIndex, settings),
                        ),
                        ScaleTransition(
                          scale: smallPulse,
                          child: _buildFooterIcon(
                              Icons.history_rounded, 1, currentIndex, settings),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 100),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ScaleTransition(
                          scale: smallPulse,
                          child: _buildFooterIcon(
                              Icons.info_outline_rounded, 3, currentIndex, settings),
                        ),
                        ScaleTransition(
                          scale: smallPulse,
                          child: _buildFooterIcon(
                              Icons.settings_rounded, 4, currentIndex, settings),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Positioned(
              top: -45,
              child: _SoundAwareGestureDetector(
                onTap: () {
                  if (isResultVisible) {
                    navProvider.hideResult();
                    return;
                  }

                  final action = navProvider.primaryScanAction;
                  if (action != null) {
                    action();
                  } else {
                    _onItemTapped(2, navProvider);
                  }
                },
                child: ScaleTransition(
                  scale: (currentIndex == 2 && !isResultVisible)
                      ? scanPulse
                      : const AlwaysStoppedAnimation(1),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: (navProvider.isScanReady && !isResultVisible) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: RotationTransition(
                          turns: _rainbowRotationController,
                          child: Container(
                            width: (currentIndex == 2 || isResultVisible)
                                ? 118
                                : 108,
                            height: (currentIndex == 2 || isResultVisible)
                                ? 118
                                : 108,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.pink, Colors.red, Colors.orange, Colors.yellow,
                                  Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.pink,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: (currentIndex == 2 || isResultVisible) ? 110 : 100,
                        height: (currentIndex == 2 || isResultVisible) ? 110 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? colorScheme.tertiaryContainer : null,
                          gradient: isDark 
                              ? null 
                              : LinearGradient(
                                  colors: [
                                     colorScheme.surfaceContainerHighest,
                                     colorScheme.tertiary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          border:
                              Border.all(color: colorScheme.primary, width: 3),
                          boxShadow: isDark 
                            ? [] 
                            : [
                                BoxShadow(
                                    color: colorScheme.primary.withAlpha(100),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6)),
                                if (currentIndex == 2 || isResultVisible)
                                  BoxShadow(
                                      color: colorScheme.tertiary.withAlpha(100),
                                      blurRadius: 35,
                                      spreadRadius: 15),
                              ],
                        ),
                        child: Center(
                          child: isResultVisible
                              ? Icon(
                                  Icons.arrow_back_rounded,
                                  size: 45,
                                  color: colorScheme.primary,
                                )
                              : SvgPicture.asset(
                                  'assets/icons/scan_icon.svg',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain, 
                                  colorFilter: ColorFilter.mode(
                                    colorScheme.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index, NavigationProvider provider) {
    if (provider.resultImageBytes != null ||
        provider.viewingHistoryEntry != null) {
      provider.hideResult();
    }
    provider.changePage(index);
    _pageController.jumpToPage(index);
  }

  Widget _buildFooterIcon(IconData icon, int index, int currentIndex, SettingsProvider settings) {
    final bool selected = currentIndex == index;
    final navProvider = context.read<NavigationProvider>();

    final colorScheme = Theme.of(context).colorScheme;
    final bool isDark = settings.isDarkMode;

    return _SoundAwareGestureDetector(
      onTap: () {
        _onItemTapped(index, navProvider);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.tertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: (selected && !isDark)
              ? [
                  BoxShadow(
                      color: colorScheme.tertiary.withAlpha(100),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 6)),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: selected
              ? colorScheme.primary
              : colorScheme.onSurface.withAlpha(170),
          size: selected ? 36 : 30,
        ),
      ),
    );
  }
}

class _SoundAwareGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SoundAwareGestureDetector({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _SoundAwareIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const _SoundAwareIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      onPressed: () {
        onPressed();
      },
    );
  }
}