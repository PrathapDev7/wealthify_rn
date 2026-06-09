import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wealthify/core/providers.dart';
import 'package:wealthify/core/storage/prefs.dart';
import 'package:wealthify/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await Prefs.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const WealthifyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Wealthify'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
