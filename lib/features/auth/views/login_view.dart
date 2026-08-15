import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/unauth_entry.dart';
import '../../../core/firebase/firebase_service.dart';

class LoginView extends ConsumerStatefulWidget {
  /// true cuando [AuthWrapper] muestra login como destino raíz (tras logout).
  final bool asUnauthRoot;

  const LoginView({super.key, this.asUnauthRoot = false});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  static const double _primaryActionHeight = 45;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showEmailFields = false;
  AuthMethod? _lastAuthMethod;

  /// Solo entrada anónima para QR: no usa [_isLoading] para no bloquear toda la tarjeta ni el botón principal.
  bool _guestQrLoading = false;
  String? _errorMessage;

  bool get _anyAuthBusy => _isLoading || _guestQrLoading;

  void _onFocusChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _loadLastAuthMethod();
  }

  Future<void> _loadLastAuthMethod() async {
    final method = await AuthService.getLastAuthMethod();
    if (mounted) setState(() => _lastAuthMethod = method);
  }

  void _showEmailLogin() {
    setState(() => _showEmailFields = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) _navigateToApp();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = _mapAuthError(e.code, l10n);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.loginErrorGeneric;
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred != null && mounted) {
        _navigateToApp();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = _mapAuthError(e.code, l10n);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.loginErrorGoogle;
        _isLoading = false;
      });
    }
  }

  Future<void> _signInAsGuestForQr() async {
    if (!FirebaseService.isAvailable) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.loginGuestNeedsFirebase;
      });
      return;
    }
    setState(() {
      _guestQrLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _guestQrLoading = false;
        _errorMessage = switch (e.code) {
          'operation-not-allowed' => l10n.loginGuestNotAllowed,
          _ => l10n.loginGuestFailed,
        };
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _guestQrLoading = false;
        _errorMessage = l10n.loginGuestFailed;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cred = await AuthService.signInWithApple();
      if (cred != null && mounted) {
        _navigateToApp();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = _mapAuthError(e.code, l10n);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.loginErrorApple;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewProfile() async {
    if (widget.asUnauthRoot) {
      await ref.read(unauthEntryProvider.notifier).startNewProfile();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    await ref.read(unauthEntryProvider.notifier).startNewProfile();
  }

  Future<void> _navigateToApp() async {
    if (!mounted) return;
    // Mantener [AuthWrapper] como ruta raíz (escucha auth). Onboarding / inicio lo decide AppInitializer.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _mapAuthError(String code, AppLocalizations l10n) {
    return switch (code) {
      'user-not-found' => l10n.authErrorUserNotFound,
      'wrong-password' => l10n.authErrorWrongPassword,
      'invalid-email' => l10n.authErrorInvalidEmail,
      'user-disabled' => l10n.authErrorUserDisabled,
      'invalid-credential' => l10n.authErrorInvalidCredential,
      'operation-not-allowed' => l10n.authErrorOperationNotAllowed,
      _ => l10n.loginErrorGeneric,
    };
  }

  String _mapPasswordResetError(String code, AppLocalizations l10n) {
    return switch (code) {
      'invalid-email' => l10n.resetErrorInvalidEmail,
      'user-not-found' => l10n.resetErrorUserNotFound,
      'user-disabled' => l10n.resetErrorUserDisabled,
      'operation-not-allowed' => l10n.resetErrorOpNotAllowed,
      _ => l10n.resetErrorGeneric,
    };
  }

  Future<void> _openForgotPasswordDialog() async {
    if (!FirebaseService.isAvailable) return;

    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    String? dialogError;
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final l10n = AppLocalizations.of(dialogCtx)!;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
              ),
              title: Text(l10n.loginForgotPasswordTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.loginForgotPasswordBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: l10n.loginEmailHint,
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.of(dialogCtx).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            setDialogState(() {
                              dialogError = l10n.loginResetInvalidEmail;
                            });
                            return;
                          }
                          setDialogState(() {
                            sending = true;
                            dialogError = null;
                          });
                          try {
                            await AuthService.sendPasswordResetEmail(email);
                            if (!dialogCtx.mounted) return;
                            Navigator.of(dialogCtx).pop();
                            if (!mounted) return;
                            final rootL10n = AppLocalizations.of(context)!;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(rootL10n.loginResetCheckEmail),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              sending = false;
                              dialogError = _mapPasswordResetError(
                                e.code,
                                l10n,
                              );
                            });
                          } catch (_) {
                            setDialogState(() {
                              sending = false;
                              dialogError = l10n.loginResetSendFail;
                            });
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.commonSend),
                ),
              ],
            );
          },
        );
      },
    );

    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F0F8)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppTheme.screenEdgePadding,
                  right: AppTheme.screenEdgePadding,
                  bottom: AppTheme.safeBottomPadding(context),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (canPop)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                              color: AppTheme.textDark,
                            ),
                          ),
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        _buildCard(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginWelcomeBackTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginWelcomeBackSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
        ),
        if (_lastAuthMethod != null) ...[
          const SizedBox(height: 18),
          Align(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.loginLastAuthMethod(_authMethodLabel(_lastAuthMethod!)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        border: Border.all(color: AppTheme.cardOutline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _authButton(
              onPressed: _anyAuthBusy ? null : _signInWithApple,
              background: Colors.black,
              foreground: Colors.white,
              icon: const Icon(Icons.apple, size: 24, color: Colors.white),
              label: l10n.loginContinueApple,
            ),
            const SizedBox(height: 12),
            _authButton(
              onPressed: _anyAuthBusy ? null : _signInWithGoogle,
              background: Colors.white,
              foreground: Colors.black87,
              border: true,
              icon: SvgPicture.asset(
                'assets/images/google_logo.svg',
                width: 20,
                height: 20,
              ),
              label: l10n.loginContinueGoogle,
            ),
            const SizedBox(height: 12),
            _authButton(
              onPressed: _anyAuthBusy ? null : _showEmailLogin,
              background: AppTheme.primaryBlue,
              foreground: Colors.white,
              icon: const Icon(
                Icons.email_outlined,
                size: 22,
                color: Colors.white,
              ),
              label: l10n.loginContinueEmail,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _showEmailFields
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildEmailFields(context),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _anyAuthBusy ? null : _signInAsGuestForQr,
              icon: _guestQrLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_2_rounded, size: 22),
              label: Text(l10n.loginGuestQr),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: _anyAuthBusy ? null : _createNewProfile,
              child: Text(
                l10n.loginCreateNewProfile,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _authMethodLabel(AuthMethod method) {
    return switch (method) {
      AuthMethod.apple => 'Apple',
      AuthMethod.google => 'Google',
      AuthMethod.email => 'email',
    };
  }

  Widget _authButton({
    required VoidCallback? onPressed,
    required Color background,
    required Color foreground,
    required Widget icon,
    required String label,
    bool border = false,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.55),
          elevation: 0,
          side: border
              ? const BorderSide(color: Color(0xFFE0E0E0))
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined),
            hintText: _emailFocusNode.hasFocus ? null : l10n.loginEmailHint,
          ),
          validator: (value) {
            if (!_showEmailFields) return null;
            if (value == null || value.trim().isEmpty) {
              return l10n.loginValidatorEmailEmpty;
            }
            if (!value.contains('@')) return l10n.loginValidatorEmailInvalid;
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outlined),
            hintText: _passwordFocusNode.hasFocus
                ? null
                : l10n.loginPasswordHint,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (!_showEmailFields) return null;
            if (value == null || value.isEmpty) {
              return l10n.loginValidatorPasswordEmpty;
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (!_anyAuthBusy) _signInWithEmail();
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _anyAuthBusy ? null : _openForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.loginForgotLink,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _primaryActionHeight,
          child: ElevatedButton(
            onPressed: _anyAuthBusy ? null : _signInWithEmail,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.loginSignIn,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
