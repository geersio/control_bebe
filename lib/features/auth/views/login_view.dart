import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_service.dart';
import '../../../features/onboarding/views/onboarding_view.dart';
import '../../../features/home/views/main_navigation.dart';
import '../../../core/db/isar_service.dart';
import 'register_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _onFocusChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
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
      setState(() {
        _errorMessage = _mapAuthError(e.code);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión';
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
      setState(() {
        _errorMessage = _mapAuthError(e.code);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión con Google';
        _isLoading = false;
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
      setState(() {
        _errorMessage = _mapAuthError(e.code);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión con Apple';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToApp() async {
    if (!mounted) return;
    final needsOnboarding = await IsarService.needsOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            needsOnboarding ? const OnboardingView() : const MainNavigation(),
      ),
      (route) => false,
    );
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'No existe una cuenta con este correo',
      'wrong-password' => 'Contraseña incorrecta',
      'invalid-email' => 'Correo electrónico no válido',
      'user-disabled' => 'Esta cuenta ha sido deshabilitada',
      'invalid-credential' => 'Credenciales inválidas',
      'operation-not-allowed' => 'Método de inicio de sesión no habilitado',
      _ => 'Error al iniciar sesión',
    };
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenEdgePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'MiBebé Diario',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para acceder a tus registros',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppTheme.textLight,
                ),
                hintText: _emailFocusNode.hasFocus
                    ? null
                    : 'Tu correo electrónico',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Introduce tu correo';
                if (!v.contains('@')) return 'Correo no válido';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.lock_outlined,
                  color: AppTheme.textLight,
                ),
                hintText: _passwordFocusNode.hasFocus ? null : 'Tu contraseña',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textLight,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Introduce tu contraseña';
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'O CONTINÚA CON',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const FaIcon(
                      FontAwesomeIcons.google,
                      size: 20,
                      color: Color(0xFF4285F4),
                    ),
                    label: const Text(
                      'Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signInWithApple,
                    icon: const Icon(
                      Icons.apple,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Apple',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿No tienes cuenta? ',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterView()),
                  ),
                  child: const Text(
                    'Regístrate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
