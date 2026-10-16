import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_config.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);

    return GardenBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final prev = app.previousScreen;
                    if (prev == AppScreen.welcome ||
                        prev == AppScreen.settings) {
                      app.go(prev!);
                    } else {
                      app.go(AppScreen.mainMenu);
                    }
                  },
                  icon: Icon(Icons.arrow_back_rounded, color: surfaces.onPanel),
                ),
                Expanded(
                  child: Text(
                    'Privacy & Legal',
                    style: PetalText.screenTitle(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'PetalGrid collects only what is needed for gameplay saves, optional Google Sign-In, cloud sync, and advertising SDKs when enabled.',
              style: PetalText.body(context),
            ),
            const SizedBox(height: 12),
            Text(
              '• Guest mode stores progress locally on-device.\n'
              '• Google Sign-In uses Firebase Authentication (account email/UID).\n'
              '• Cloud saves use Cloud Firestore under your UID.\n'
              '• Ads use Google Mobile Ads (test IDs in development).\n'
              '• We do not request contacts, precise location, or microphone.',
              style: PetalText.supporting(context)
                  .copyWith(color: surfaces.onPanel, height: 1.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Audience: general casual puzzle players. Before release, the owner must decide Families/Kids category implications and configure consent (UMP) for applicable regions.',
              style: PetalText.caption(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _open(AppConfig.privacyPolicyUrl, context),
              child: const Text('Open privacy policy'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _open(AppConfig.termsUrl, context),
              child: const Text('Terms of service'),
            ),
            TextButton(
              onPressed: () => _open(AppConfig.supportUrl, context),
              child: const Text('Support'),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: surfaces.panel,
                borderRadius: BorderRadius.circular(PetalRadius.lg),
                border: Border.all(color: surfaces.panelBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'I understand the privacy summary',
                      style: PetalText.body(context),
                    ),
                  ),
                  Switch(
                    value: app.save?.settings.privacyAccepted ?? false,
                    activeThumbColor: surfaces.accent,
                    onChanged: app.save == null
                        ? null
                        : (v) => app.updateSettings(
                            app.save!.settings.copyWith(privacyAccepted: v),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Replace OWNER_SUPPLY_* URLs in AppConfig before store submission.',
              style: PetalText.caption(context)
                  .copyWith(color: surfaces.danger),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url, BuildContext context) async {
    if (url.startsWith('OWNER_SUPPLY')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner must supply a real hosted URL in AppConfig.'),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
