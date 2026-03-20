import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/db/isar_service.dart';
import '../../../features/onboarding/views/onboarding_view.dart';
import '../../../features/home/views/main_navigation.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        final needsOnboarding = await IsarService.needsOnboarding();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => needsOnboarding
                ? const OnboardingView()
                : const MainNavigation(),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e.code);
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error registro: $e\n$st');
      setState(() {
        _errorMessage = 'Error al registrarse. Comprueba tu conexión y que el registro por email esté habilitado en Firebase.';
        _isLoading = false;
      });
    }
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'email-already-in-use' => 'Ya existe una cuenta con este correo. Usa "Inicia sesión" en su lugar.',
      'invalid-email' => 'Correo electrónico no válido',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres',
      'operation-not-allowed' => 'Registro por email no habilitado. Actívalo en Firebase Console > Authentication > Sign-in method',
      'network-request-failed' => 'Error de conexión. Comprueba tu internet.',
      'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
      'invalid-credential' => 'Credenciales inválidas',
      _ => 'Error: $code. Revisa Firebase Console.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Registro'),
      ),
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
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenEdgePadding,
              24,
              AppTheme.screenEdgePadding,
              24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Crea tu cuenta',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Introduce tus datos para registrarte',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    hint: 'tu@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Introduce tu correo';
                      if (!v.contains('@')) return 'Correo no válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    hint: 'Mínimo 6 caracteres',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Introduce una contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Confirmar contraseña',
                    controller: _confirmPasswordController,
                    hint: 'Repite la contraseña',
                    obscureText: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) return 'Las contraseñas no coinciden';
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
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
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
                          : const Text('Registrarse', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Inicia sesión',
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
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
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
