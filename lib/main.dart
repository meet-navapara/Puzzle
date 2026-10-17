import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'core/firebase_bootstrap.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final firebaseOk = await FirebaseBootstrap.ensureInitialized();

  // ignore: avoid_print
  print(
    'PetalGrid starting (firebaseEnabled=${AppConfig.firebaseEnabled}, '
    'firebaseReady=$firebaseOk, adsEnabled=${AppConfig.adsEnabled}, '
    'adsUseTestIds=${AppConfig.adsUseTestIds})',
  );

  final appState = AppState();
  runApp(
    ChangeNotifierProvider.value(value: appState, child: const PetalGridApp()),
  );
  try {
    await appState.bootstrap();
  } catch (e, st) {
    // ignore: avoid_print
    print('bootstrap failed: $e\n$st');
  }
}
