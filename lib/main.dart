import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase is intentionally gated. Enable after adding platform config files
  // and setting AppConfig.firebaseEnabled = true.
  // ignore: avoid_print
  print(
    'PetalGrid starting (firebaseEnabled=${AppConfig.firebaseEnabled}, '
    'adsEnabled=${AppConfig.adsEnabled})',
  );

  final appState = AppState();
  runApp(
    ChangeNotifierProvider.value(value: appState, child: const PetalGridApp()),
  );
  await appState.bootstrap();
}
