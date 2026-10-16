import 'package:block_garden/state/app_state.dart';
import 'package:block_garden/ui/screens/daily_screen.dart';
import 'package:block_garden/ui/theme/petal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('daily screen shows compact claim layout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    app.save = await app.localSave.loadOrCreate();
    app.screen = AppScreen.daily;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(theme: PetalTheme.dark(), home: const DailyScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Daily Dew'), findsOneWidget);
    expect(find.textContaining('15 petals'), findsWidgets);
    expect(find.text('Watch & Claim'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
