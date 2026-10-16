import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/app_state.dart';
import '../theme/petal_theme.dart';

class ConnectionRequiredScreen extends StatelessWidget {
  const ConnectionRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);

    return GardenBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: surfaces.accentSoft,
              ),
              const SizedBox(height: 16),
              Text(
                'Internet required',
                style: PetalText.screenTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                app.connectivity.lastError ??
                    'PetalGrid needs a working internet connection to enter play modes. Your local save is kept safe.',
                textAlign: TextAlign.center,
                style: PetalText.body(context),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: app.connectivity.isChecking
                    ? null
                    : () => app.retryConnection(),
                child: Text(
                  app.connectivity.isChecking ? 'Checking…' : 'Retry',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _openNetworkSettings(context),
                child: const Text('Open network settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNetworkSettings(BuildContext context) async {
    // Opens this app's system settings page (reachable path to Wi‑Fi/network).
    final candidates = <Uri>[
      if (Platform.isAndroid) Uri.parse('app-settings:'),
      if (Platform.isIOS) Uri.parse('app-settings:'),
      Uri.parse('https://'),
    ];
    for (final uri in candidates) {
      try {
        if (uri.scheme == 'https') continue;
        if (await canLaunchUrl(uri)) {
          final ok = await launchUrl(uri);
          if (ok) return;
        }
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open system Settings → Network manually.'),
        ),
      );
    }
  }
}
