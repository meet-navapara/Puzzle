import 'package:block_garden/app.dart';
import 'package:block_garden/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PetalGrid shows brand on splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const PetalGridApp(),
      ),
    );
    await tester.pump();
    expect(find.text('PetalGrid'), findsWidgets);
    // Do not pumpAndSettle — connectivity polling + animate keep the frame busy.
  });
}
