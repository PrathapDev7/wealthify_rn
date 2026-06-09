// Dev tool: downloads the Wealthify icon/logo glyphs from S3 into assets/,
// using the manifest the RN app generated (legacy_rn/assets/Constants/remoteAssets.js).
// Run from the project root:  dart run tool/download_assets.dart
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final manifestFile = File('legacy_rn/assets/Constants/remoteAssets.js');
  if (!manifestFile.existsSync()) {
    stderr.writeln('manifest not found: ${manifestFile.path}');
    exit(1);
  }
  final text = manifestFile.readAsStringSync();
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  final Map<String, dynamic> map = jsonDecode(text.substring(start, end + 1));

  // Only the bundles the Flutter app needs (skip raw lottie frame PNGs).
  bool wanted(String p) =>
      p.startsWith('assets/wealthify/') ||
      p.startsWith('assets/img/logo/') ||
      p.startsWith('assets/icons/') ||
      p.startsWith('assets/images/');

  final entries = map.entries.where((e) => wanted(e.key)).toList();
  final client = HttpClient();
  var ok = 0, skip = 0, fail = 0;
  for (final e in entries) {
    final rel = e.key; // already starts with assets/
    final uri = (e.value as Map)['uri'] as String;
    final out = File(rel);
    if (out.existsSync() && out.lengthSync() > 0) {
      skip++;
      continue;
    }
    out.parent.createSync(recursive: true);
    try {
      final req = await client.getUrl(Uri.parse(uri));
      req.headers.set('ngrok-skip-browser-warning', 'true');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        await resp.pipe(out.openWrite());
        ok++;
      } else {
        fail++;
        stderr.writeln('FAIL ${resp.statusCode}  $uri');
      }
    } catch (err) {
      fail++;
      stderr.writeln('ERR  $uri  $err');
    }
  }
  client.close();
  stdout.writeln('assets: $ok downloaded, $skip skipped, $fail failed '
      '(of ${entries.length} wanted / ${map.length} total)');
}
