// Run before building for Google Play:  dart run tool/release_check.dart
//
// Fails on anything that would get the upload rejected or ship broken. These are
// all things the compiler can't catch: test ads, debug signing, a missing
// Firebase fingerprint. Exit code 0 means ready to build.
import 'dart:io';

const _googleTestPublisher = 'ca-app-pub-3940256099942544';

final _problems = <String>[];
final _notes = <String>[];

void _check(bool ok, String what, String fix) {
  stdout.writeln('${ok ? '[ ok ]' : '[FAIL]'} $what');
  if (!ok) _problems.add('$what\n       -> $fix');
}

String _read(String path) {
  final f = File(path);
  return f.existsSync() ? f.readAsStringSync() : '';
}

void main() {
  final config = _read('lib/core/app_config.dart');
  final manifest = _read('android/app/src/main/AndroidManifest.xml');

  const setIds =
      'Run: dart run tool/set_admob_ids.dart <app id> <rewarded> <interstitial> [app open]';
  _check(
    config.contains('adsUseTestIds = false'),
    'App uses real ads (adsUseTestIds = false)',
    setIds,
  );
  _check(
    !config.contains('OWNER_SUPPLY'),
    'All AdMob ad unit IDs are filled in',
    setIds,
  );
  _check(
    !manifest.contains(_googleTestPublisher),
    'AndroidManifest has the real AdMob app ID',
    '$setIds  (a wrong value here crashes the app on launch)',
  );
  final adsTxt = _read('public/app-ads.txt');
  _check(
    adsTxt.contains('google.com, pub-') && !adsTxt.contains('3940256099942544'),
    'public/app-ads.txt names your AdMob account',
    '$setIds  then: firebase deploy --only hosting',
  );

  final keyFile = File('android/key.properties');
  var signingOk = false;
  if (keyFile.existsSync()) {
    final props = {
      for (final line in keyFile.readAsLinesSync())
        if (line.contains('='))
          line.substring(0, line.indexOf('=')).trim(): line
              .substring(line.indexOf('=') + 1)
              .trim(),
    };
    final store = props['storeFile'] ?? '';
    final storePath = File('android/$store');
    final abs = File(store);
    signingOk =
        ['keyAlias', 'keyPassword', 'storePassword'].every(
          (k) => (props[k] ?? '').isNotEmpty && !props[k]!.contains('YOUR_'),
        ) &&
        store.isNotEmpty &&
        (storePath.existsSync() || abs.existsSync());
  }
  _check(
    signingOk,
    'Release signing is set up (android/key.properties and keystore)',
    'Copy android/key.properties.example to android/key.properties and fill it in. '
        'Without it the build is debug-signed and Play rejects it.',
  );

  final services = _read('android/app/google-services.json');
  _check(
    services.isNotEmpty,
    'android/app/google-services.json is present',
    'Download it from Firebase Console -> Project settings -> Android app.',
  );
  if (services.isNotEmpty) {
    final hashes = RegExp(r'"certificate_hash"\s*:\s*"([0-9a-fA-F]+)"')
        .allMatches(services)
        .map((m) => m[1]!.toLowerCase())
        .toSet();
    final hasDebugOnly = hashes.length <= 1;
    _check(
      !hasDebugOnly,
      'Firebase knows more than one app fingerprint (debug + release)',
      'Add your upload key and Play App Signing SHA-1s in Firebase, then '
          're-download google-services.json. Otherwise "Continue with Google" '
          'fails for every Play Store user.',
    );
  }

  final gradle = _read('android/app/build.gradle.kts');
  _check(
    gradle.contains('flutter.targetSdkVersion'),
    'Target SDK comes from Flutter (currently 36, Play requires 36+)',
    'Set targetSdk to 36 or higher in android/app/build.gradle.kts.',
  );

  final pubspec = _read('pubspec.yaml');
  final version = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(pubspec)?[1];
  _notes.add(
    'Version $version. Each upload needs a higher number after the "+".',
  );
  _notes.add(
    'Also make sure public/ is deployed: firebase deploy --only hosting,firestore:rules',
  );

  stdout.writeln('');
  for (final n in _notes) {
    stdout.writeln('note: $n');
  }
  stdout.writeln('');
  if (_problems.isEmpty) {
    stdout.writeln('Ready: flutter build appbundle --release');
    return;
  }
  stdout.writeln('NOT READY. ${_problems.length} thing(s) to fix:\n');
  for (final p in _problems) {
    stdout.writeln(' - $p\n');
  }
  exitCode = 1;
}
