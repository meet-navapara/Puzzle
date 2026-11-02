import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../core/app_config.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/external_link.dart';
import '../widgets/google_mark.dart';

/// The login screen: first thing a new player sees. Google or guest, both one tap.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);
    final signingIn = app.auth.status == AuthStatus.signingIn;

    return GardenBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            const Center(child: BrandLogo(size: 100)),
                            const SizedBox(height: 16),
                            Text(
                              AppConfig.appName,
                              textAlign: TextAlign.center,
                              style: PetalText.display(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Plant colorful blocks, bloom full rows and columns, '
                              'and grow through ${CampaignCatalog.totalLevels} garden levels.',
                              textAlign: TextAlign.center,
                              style: PetalText.body(context),
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            if (app.auth.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  app.auth.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: PetalText.supporting(context)
                                      .copyWith(color: surfaces.danger),
                                ),
                              ),
                            _GoogleButton(
                              signingIn: signingIn,
                              onPressed: () => app.signInGoogle(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Keeps your progress safe across devices',
                              textAlign: TextAlign.center,
                              style: PetalText.caption(context),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: signingIn
                                  ? null
                                  : () => app.continueAsGuest(),
                              child: const Text('Play as Guest'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Progress stays on this device. Link Google any time in Settings.',
                              textAlign: TextAlign.center,
                              style: PetalText.caption(context),
                            ),
                            const SizedBox(height: 20),
                            const _LegalLine(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Follows Google's sign-in button rules: standard mark on white or near-black.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.signingIn, required this.onPressed});

  final bool signingIn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF131314) : Colors.white;
    final foreground = dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    final border = dark ? const Color(0xFF8E918F) : const Color(0xFF747775);
    return ElevatedButton(
      onPressed: signingIn ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        disabledBackgroundColor: background,
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        side: BorderSide(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (signingIn)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          else
            const GoogleMark(),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              signingIn ? 'Signing in…' : 'Continue with Google',
              overflow: TextOverflow.ellipsis,
              style: PetalText.button(context)
                  .copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful so the tap recognizers on the links are disposed with the widget.
class _LegalLine extends StatefulWidget {
  const _LegalLine();

  @override
  State<_LegalLine> createState() => _LegalLineState();
}

class _LegalLineState extends State<_LegalLine> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => openExternalLink(context, AppConfig.termsUrl);
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => openExternalLink(context, AppConfig.privacyPolicyUrl);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final base = PetalText.caption(context);
    final link = base.copyWith(
      color: surfaces.accent,
      fontWeight: FontWeight.w700,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(text: 'Terms', style: link, recognizer: _terms),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
