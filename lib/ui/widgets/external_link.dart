import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web or mail link outside the app, and says so if nothing can handle
/// it rather than leaving the button looking broken.
Future<void> openExternalLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger?.showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}
