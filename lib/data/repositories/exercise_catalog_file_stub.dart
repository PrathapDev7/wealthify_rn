/// The no-filesystem half of [ExerciseCatalogCache]'s disk mirror, used where
/// `dart:io` does not exist — web. Reading always misses, writing is a no-op,
/// so the catalog is simply fetched once per session there.
///
/// Selected by the conditional import in `exercise_catalog_cache.dart`; the
/// real implementation is `exercise_catalog_file_io.dart`.
library;

Future<String?> readCatalogFile(String name) async => null;

Future<void> writeCatalogFile(String name, String contents) async {}
