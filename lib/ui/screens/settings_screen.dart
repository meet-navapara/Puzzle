import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/firebase_bootstrap.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.save!.settings;
    final surfaces = PetalSurfaces.of(context);
    final guest = app.auth.isGuest;
    final email = app.auth.user?.email;

    return GardenBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => app.go(AppScreen.mainMenu),
                  icon: Icon(Icons.arrow_back_rounded, color: surfaces.onPanel),
                ),
                Expanded(
                  child: Text(
                    'Settings',
                    style: PetalText.screenTitle(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PetalSpace.md),
            Text('Account', style: PetalText.section(context)),
            const SizedBox(height: PetalSpace.sm),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaces.panel,
                borderRadius: BorderRadius.circular(PetalRadius.xl),
                border: Border.all(color: surfaces.panelBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: surfaces.accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      guest
                          ? Icons.person_outline_rounded
                          : Icons.verified_user_rounded,
                      color: surfaces.accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guest ? 'Guest gardener' : (email ?? 'Signed in'),
                          style: PetalText.section(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          guest
                              ? 'ID ${app.save?.guestId ?? "—"}'
                              : 'UID ${app.auth.uid}',
                          style: PetalText.caption(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: PetalSpace.sm),
            _SettingsCard(
              children: [
                _InfoRow(
                  label: 'Campaign',
                  value:
                      '${app.save!.campaign.completedCount}/50 · ${app.save!.campaign.petals} petals',
                ),
                Divider(height: 1, color: surfaces.panelBorder),
                _InfoRow(
                  label: 'Classic best',
                  value: '${app.save!.classicBest}',
                ),
              ],
            ),
            const SizedBox(height: PetalSpace.sm),
            if (guest && AppConfig.firebaseEnabled && FirebaseBootstrap.ready)
              ElevatedButton.icon(
                onPressed: app.auth.status == AuthStatus.signingIn
                    ? null
                    : () => app.signInGoogle(),
                icon: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4285F4),
                      height: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                label: const Text('Link Google & sync'),
              ),
            if (!guest) ...[
              OutlinedButton.icon(
                onPressed: () async {
                  await app.signOutLocal();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Signed out. Local guest data kept on device.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
              TextButton(
                onPressed: () => _confirmDelete(context, app),
                child: Text(
                  'Delete account & cloud data',
                  style: PetalText.button(context).copyWith(
                    color: surfaces.danger,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            if (guest)
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
            const SizedBox(height: PetalSpace.lg),
            Text('Garden lessons', style: PetalText.section(context)),
            const SizedBox(height: PetalSpace.sm),
            Text(
              'Replay a lesson any time. You perform each highlighted step yourself.',
              style: PetalText.supporting(context),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => app.replayTutorial(1),
              icon: const Icon(Icons.school_rounded),
              label: const Text('Replay level 1 lesson'),
            ),
            if (app.save!.campaign.progressOf(2).unlocked) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => app.replayTutorial(2),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Replay level 2 lesson'),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: app.replayClassicLesson,
              icon: const Icon(Icons.spa_rounded),
              label: const Text('Replay Classic lesson'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: app.replayDailyLesson,
              icon: const Icon(Icons.water_drop_rounded),
              label: const Text('Replay Daily Dew lesson'),
            ),
            const SizedBox(height: PetalSpace.lg),
            Text('Appearance', style: PetalText.section(context)),
            const SizedBox(height: PetalSpace.sm),
            SegmentedButton<AppThemePreference>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return surfaces.accent.withValues(alpha: 0.22);
                  }
                  return surfaces.panel;
                }),
                foregroundColor: WidgetStatePropertyAll(surfaces.onPanel),
                side: WidgetStatePropertyAll(
                  BorderSide(color: surfaces.panelBorder),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: AppThemePreference.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
                ButtonSegment(
                  value: AppThemePreference.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment(
                  value: AppThemePreference.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_rounded),
                ),
              ],
              selected: {s.themePreference},
              onSelectionChanged: (set) {
                app.updateSettings(s.copyWith(themePreference: set.first));
              },
            ),
            const SizedBox(height: PetalSpace.lg),
            Text('Audio & feel', style: PetalText.section(context)),
            const SizedBox(height: PetalSpace.sm),
            _SettingsCard(
              children: [
                _SwitchRow(
                  title: 'Sound effects',
                  value: s.soundEnabled,
                  onChanged: (v) =>
                      app.updateSettings(s.copyWith(soundEnabled: v)),
                ),
                _SwitchRow(
                  title: 'Music',
                  subtitle: app.audio.hasMusicAsset
                      ? 'Loops while you garden'
                      : 'Add music_loop.wav (or .ogg) under assets/audio',
                  value: s.musicEnabled,
                  onChanged: (v) =>
                      app.updateSettings(s.copyWith(musicEnabled: v)),
                ),
                _SwitchRow(
                  title: 'Haptics',
                  value: s.hapticsEnabled,
                  onChanged: (v) =>
                      app.updateSettings(s.copyWith(hapticsEnabled: v)),
                ),
                _SwitchRow(
                  title: 'Reduced effects',
                  subtitle: 'Fewer particles and motion',
                  value: s.reducedEffects,
                  onChanged: (v) =>
                      app.updateSettings(s.copyWith(reducedEffects: v)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sound volume', style: PetalText.body(context)),
                      Slider(
                        value: s.soundVolume,
                        activeColor: surfaces.accent,
                        inactiveColor: surfaces.panelBorder,
                        onChanged: (v) =>
                            app.updateSettings(s.copyWith(soundVolume: v)),
                      ),
                      Text('Music volume', style: PetalText.body(context)),
                      Slider(
                        value: s.musicVolume,
                        activeColor: surfaces.accent,
                        inactiveColor: surfaces.panelBorder,
                        onChanged: (v) =>
                            app.updateSettings(s.copyWith(musicVolume: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: PetalSpace.md),
            _SettingsCard(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => app.go(AppScreen.privacy),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Privacy',
                              style: PetalText.body(context),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: surfaces.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PetalSpace.lg),
            Text(
              'Petals come from campaign clears and Daily Dew. Spend 10 petals in-run for an extra bloom charge. Internet is required to enter play modes; local saves stay intact during brief disconnects.',
              style: PetalText.supporting(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete account?', style: PetalText.section(ctx)),
        content: Text(
          'Google Sign-In will open to verify it is you. Then we delete your '
          'Firebase account, cloud save, and reset local data on this device. '
          'This cannot be undone.\n\n'
          'Web help: ${AppConfig.accountDeletionUrl}',
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
              : (app.statusMessage ??
                    'Account deletion failed. Local data kept.'),
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
          'Resets progress and settings on this device only.',
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Container(
      decoration: BoxDecoration(
        color: surfaces.panel,
        borderRadius: BorderRadius.circular(PetalRadius.lg),
        border: Border.all(color: surfaces.panelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: PetalText.body(context))),
          Flexible(
            child: Text(
              value,
              style: PetalText.supporting(context),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PetalText.body(context)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: PetalText.caption(context)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: surfaces.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
