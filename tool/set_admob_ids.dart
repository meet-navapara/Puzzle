// Switches the app from Google's test ads to your real AdMob ads, in every place
// that needs it, so they can't drift apart. Run from the project root:
//
//   dart run tool/set_admob_ids.dart <app id> <rewarded> <interstitial> [app open]
//
// The app-open ID is optional; without it app-open ads stay switched off.
//
// Example (made-up numbers):
//   dart run tool/set_admob_ids.dart ca-app-pub-1234567890123456~1234567890 \
//     ca-app-pub-1234567890123456/1111111111 ca-app-pub-1234567890123456/2222222222 \
//     ca-app-pub-1234567890123456/3333333333
//
// Writes lib/core/app_config.dart, android/app/src/main/AndroidManifest.xml and
// public/app-ads.txt. Add --root <dir> to run against a copy of the project.
import 'dart:io';

final _appId = RegExp(r'^ca-app-pub-(\d{16})~\d{10}$');
final _unitId = RegExp(r'^ca-app-pub-(\d{16})/\d{10}$');

Never _fail(String message) {
  stderr.writeln('Not changed: $message');
  exit(2);
}

void main(List<String> args) {
  var root = '.';
  final ids = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--root' && i + 1 < args.length) {
      root = args[++i];
    } else {
      ids.add(args[i].trim());
    }
  }
  if (ids.length != 3 && ids.length != 4) {
    _fail('expected 3 or 4 IDs: app ID, rewarded, interstitial, [app open].');
  }
  final appId = ids[0], rewarded = ids[1], interstitial = ids[2];
  final appOpen = ids.length == 4 ? ids[3] : '';

  final app = _appId.firstMatch(appId);
  if (app == null) {
    _fail(
      '"$appId" is not an AdMob app ID (ca-app-pub-<16 digits>~<10 digits>).',
    );
  }
  final publisher = app[1]!;
  if (publisher == '3940256099942544') {
    _fail('that is Google\'s test publisher, not your account.');
  }
  for (final (name, id) in [
    ('rewarded', rewarded),
    ('interstitial', interstitial),
    if (appOpen.isNotEmpty) ('app open', appOpen),
  ]) {
    final unit = _unitId.firstMatch(id);
    if (unit == null) {
      _fail(
        'the $name ID "$id" is not an ad unit ID (ca-app-pub-<16 digits>/<10 digits>).',
      );
    }
    if (unit[1] != publisher) {
      _fail(
        'the $name ID belongs to a different AdMob account than the app ID.',
      );
    }
  }
  if ({rewarded, interstitial, appOpen}.length != 3) {
    _fail('each ad format needs its own ad unit.');
  }

  final configFile = File('$root/lib/core/app_config.dart');
  var config = configFile.readAsStringSync();

  // iOS is not released yet; it reuses the Android values until it has its own.
  for (final (name, value) in [
    ('_prodAndroidAppId', appId),
    ('_prodIosAppId', appId),
    ('_prodRewardedAndroid', rewarded),
    ('_prodRewardedIos', rewarded),
    ('_prodInterstitialAndroid', interstitial),
    ('_prodInterstitialIos', interstitial),
    ('_prodAppOpenAndroid', appOpen),
    ('_prodAppOpenIos', appOpen),
  ]) {
    final pattern = RegExp("(static const String $name =\\s*)'[^']*';");
    if (!pattern.hasMatch(config)) {
      _fail('could not find $name in app_config.dart.');
    }
    config = config.replaceFirstMapped(pattern, (m) => "${m[1]}'$value';");
  }
  config = config.replaceFirst(
    'static const bool adsUseTestIds = true;',
    'static const bool adsUseTestIds = false;',
  );
  if (!config.contains("'$rewarded'") ||
      !config.contains('adsUseTestIds = false')) {
    _fail('app_config.dart did not take the new values.');
  }

  final manifestFile = File('$root/android/app/src/main/AndroidManifest.xml');
  final manifestPattern = RegExp(
    r'(android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"\s*android:value=")[^"]*(")',
  );
  final manifest = manifestFile.readAsStringSync();
  if (!manifestPattern.hasMatch(manifest)) {
    _fail('could not find the AdMob APPLICATION_ID in AndroidManifest.xml.');
  }

  // Everything checked: write all three files.
  configFile.writeAsStringSync(config);
  manifestFile.writeAsStringSync(
    manifest.replaceFirstMapped(manifestPattern, (m) => '${m[1]}$appId${m[2]}'),
  );
  final adsTxt = File('$root/public/app-ads.txt');
  adsTxt.writeAsStringSync(
    'google.com, pub-$publisher, DIRECT, f08c47fec0942fa0\n',
  );

  stdout.writeln('Real ads set for publisher pub-$publisher:');
  stdout.writeln(
    '  lib/core/app_config.dart       ad unit IDs, adsUseTestIds = false',
  );
  stdout.writeln('  AndroidManifest.xml            app ID');
  if (appOpen.isEmpty) {
    stdout.writeln('  App-open ads                   off (no ad unit given)');
  }
  stdout.writeln(
    '  public/app-ads.txt             publish with: firebase deploy --only hosting',
  );
  stdout.writeln('Next: dart run tool/release_check.dart');
}
