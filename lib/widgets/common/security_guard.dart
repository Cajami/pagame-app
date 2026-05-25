import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/widgets/common/app_background.dart';

class SecurityGuard extends StatefulWidget {
  const SecurityGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SecurityGuard> createState() => _SecurityGuardState();
}

class _SecurityGuardState extends State<SecurityGuard> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isChecking = true;
  bool _isAuthenticating = false; // Flag to prevent concurrent biometric prompts

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _isChecking = true;
    });

    try {
      // Check if hardware is capable of local authentication
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Device doesn't have secure lock, bypass security gracefully
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
          _isAuthenticating = false;
        });
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Identifícate para ingresar a Págame',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern/Password fallback
          useErrorDialogs: true,
        ),
      );

      setState(() {
        _isAuthenticated = didAuthenticate;
        _isChecking = false;
      });
    } on PlatformException catch (e) {
      debugPrint('Security check failed: $e');
      setState(() {
        _isAuthenticated = false;
        _isChecking = false;
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo
                    Image.asset(
                      'assets/images/logo_pagame3.png',
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'Págame',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Security Lock Icon
                    Container(
                      height: 110,
                      width: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF18C1B5), Color(0xFF0E5165)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x2618C1B5),
                            blurRadius: 26,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Aplicación Bloqueada',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Por motivos de privacidad y seguridad, debes desbloquear el acceso usando tu huella, PIN o patrón de seguridad.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.inkSoft,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (_isChecking)
                      const CircularProgressIndicator(color: AppColors.accent)
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _authenticate,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: const Text('Desbloquear aplicación'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
