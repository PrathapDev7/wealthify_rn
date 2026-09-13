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
        child: const AlignApp(),
      ),
    );
    // A non-zero pump duration is required: the splash's flutter_animate
    // widgets schedule zero-delay timers that only fire when the fake clock
    // advances, and a zero-duration pump leaves them pending at teardown.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ALIGN'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
