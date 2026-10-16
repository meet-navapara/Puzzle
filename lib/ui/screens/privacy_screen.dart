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
    final guest = app.auth.isGuest;

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
              '• Ads use Google Mobile Ads (test units while developing; production IDs later).\n'
              '• We do not request contacts, precise location, or microphone.\n'
              '• Audience: general casual puzzle players (not designed for children).',
              style: PetalText.supporting(context)
                  .copyWith(color: surfaces.onPanel, height: 1.45),
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
            TextButton(
              onPressed: () => _open(AppConfig.accountDeletionUrl, context),
              child: const Text('Account deletion help (web)'),
            ),
            TextButton(
              onPressed: () => _mailSupport(context),
              child: Text('Email ${AppConfig.supportEmail}'),
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
            const SizedBox(height: 20),
            Text('Your data', style: PetalText.section(context)),
            const SizedBox(height: 8),
            if (!guest)
              TextButton(
                onPressed: () => _confirmDeleteAccount(context, app),
                child: Text(
                  'Delete account & cloud data',
                  style: PetalText.button(context).copyWith(
                    color: surfaces.danger,
                    fontSize: 14,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => _confirmClearLocal(context, app),
                child: Text(
                  'Clear local data on this device',
                  style: PetalText.button(context).copyWith(
                    color: surfaces.danger,
                    fontSize: 14,
                  ),
                ),
              ),
            Text(
              guest
                  ? 'Guest mode: this only wipes progress stored on this phone.'
                  : 'You will confirm Google Sign-In, then your Auth user, cloud save, and local data are removed.',
              style: PetalText.caption(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _mailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=PetalGrid support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete account?', style: PetalText.section(ctx)),
        content: Text(
          'Google Sign-In will open so we can verify it is you. Then we delete '
          'your Firebase account, cloud save, and reset local data on this device. '
          'This cannot be undone.',
          style: PetalText.body(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final wiped = await app.deleteAccountAndData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wiped
              ? (app.statusMessage ?? 'Account deleted.')
              : (app.statusMessage ?? 'Account deletion failed.'),
        ),
      ),
    );
  }

  Future<void> _confirmClearLocal(BuildContext context, AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear local data?', style: PetalText.section(ctx)),
        content: Text(
          'Resets progress and settings on this device only. No cloud account is affected.',
          style: PetalText.body(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await app.clearLocalDataOnly();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(app.statusMessage ?? 'Local data cleared.')),
    );
  }
}
