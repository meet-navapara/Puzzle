import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';
import '../widgets/brand_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);
    final signingIn = app.auth.status == AuthStatus.signingIn;
    final googleAvailable = AppConfig.firebaseEnabled;

    return GardenBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
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
                'Plant colorful blocks, bloom full rows and columns, and grow through fifty garden trials.',
                textAlign: TextAlign.center,
                style: PetalText.body(context),
              ),
              const Spacer(),
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
              ElevatedButton(
                onPressed: signingIn ? null : () => app.continueAsGuest(),
                child: const Text('Play as Guest'),
              ),
              if (googleAvailable) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: signingIn ? null : () => app.signInGoogle(),
                  icon: signingIn
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: surfaces.accent,
                          ),
                        )
                      : const _GoogleMark(),
                  label: Text(
                    signingIn ? 'Signing in…' : 'Continue with Google',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                googleAvailable
                    ? 'Guest progress is stored on this device. Clearing app data or uninstalling may erase it. Link Google later from Settings to sync.'
                    : 'Guest progress is stored on this device. Google Sign-In will appear here once Firebase is enabled for release.',
                textAlign: TextAlign.center,
                style: PetalText.caption(context),
              ),
              TextButton(
                onPressed: () => app.go(AppScreen.privacy),
                child: const Text('Privacy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Google "G" mark for the sign-in button (avoids door/login icons).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
