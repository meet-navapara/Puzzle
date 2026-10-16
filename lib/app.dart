import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'ui/game/gameplay_screen.dart';
import 'ui/screens/campaign_victory_screen.dart';
import 'ui/screens/connection_screen.dart';
import 'ui/screens/daily_screen.dart';
import 'ui/screens/level_select_screen.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/screens/privacy_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/welcome_screen.dart';
import 'ui/screens/world_map_screen.dart';
import 'ui/theme/petal_theme.dart';

class PetalGridApp extends StatelessWidget {
  const PetalGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preference =
        context.watch<AppState>().save?.settings.themePreference ??
        AppThemePreference.dark;

    final ThemeMode mode = switch (preference) {
      AppThemePreference.dark => ThemeMode.dark,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.system => ThemeMode.system,
    };

    return MaterialApp(
      title: 'PetalGrid',
      debugShowCheckedModeBanner: false,
      theme: PetalTheme.light(),
      darkTheme: PetalTheme.dark(),
      themeMode: mode,
      builder: (context, child) {
        final surfaces = PetalSurfaces.of(context);
        return PetalText.scaleGuard(
          child: DefaultTextStyle(
            style: TextStyle(
              color: surfaces.onPanel,
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
              decorationThickness: 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final screen = context.select<AppState, AppScreen>((a) => a.screen);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final app = context.read<AppState>();
        final mayExit = app.handleSystemBack();
        if (mayExit) {
          maybeExitApp();
        }
      },
      child: _screenFor(screen),
    );
  }

  Widget _screenFor(AppScreen screen) {
    switch (screen) {
      case AppScreen.splash:
        return const SplashScreen();
      case AppScreen.welcome:
        return const WelcomeScreen();
      case AppScreen.connectionRequired:
        return const ConnectionRequiredScreen();
      case AppScreen.mainMenu:
        return const MainMenuScreen();
      case AppScreen.classic:
      case AppScreen.gameplay:
        return const GameplayScreen();
      case AppScreen.worldMap:
        return const WorldMapScreen();
      case AppScreen.levelSelect:
        return const LevelSelectScreen();
      case AppScreen.settings:
      case AppScreen.profile:
        // Profile content lives inside Settings — keep enum for old navigation.
        return const SettingsScreen();
      case AppScreen.daily:
        return const DailyScreen();
      case AppScreen.privacy:
        return const PrivacyScreen();
      case AppScreen.campaignVictory:
        return const CampaignVictoryScreen();
    }
  }
}
