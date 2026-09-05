import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// [ExerciseCatalogCache]'s disk mirror on the platforms that have a
/// filesystem. A JSON file in the app-support directory rather than
/// shared_preferences: the catalog is ~1 MB, and prefs are read into memory on
/// every launch whether the picker is opened or not.
///
/// Both sides swallow their failures — a cache that cannot be read or written
/// costs a refetch, which is what the app did before it existed.
Future<String?> readCatalogFile(String name) async {
  try {
    final file = File('${(await getApplicationSupportDirectory()).path}/$name');
    return await file.exists() ? await file.readAsString() : null;
  } catch (_) {
    return null;
  }
}

Future<void> writeCatalogFile(String name, String contents) async {
  try {
    final dir = await getApplicationSupportDirectory();
    await File('${dir.path}/$name').writeAsString(contents);
  } catch (_) {
    // Read-only or full storage: the next launch just pulls again.
  }
}
