import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';

/// Escaneo de QR para unirse a una familia existente (onboarding o invitado en login).
class FamilyQrJoinScreen extends StatefulWidget {
  final Future<void> Function(String familyId) onScanned;
  final VoidCallback onBack;
  final String hintText;

  const FamilyQrJoinScreen({
    super.key,
    required this.onScanned,
    required this.onBack,
    this.hintText = 'Apunta la cámara al código QR del bebé',
  });

  @override
  State<FamilyQrJoinScreen> createState() => _FamilyQrJoinScreenState();
}

class _FamilyQrJoinScreenState extends State<FamilyQrJoinScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _processing = false;
  String? _error;

  static String _joinFailureDescription(Object error) {
    final technical = _technicalErrorText(error);
    final summary = _joinFailureSummary(error);
    if (technical == summary) return summary;
    return '$summary\n\nDetalle: $technical';
  }

  static String _joinFailureSummary(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permiso denegado en Firebase (reglas de Firestore o sesión).';
        case 'unavailable':
          return 'Firebase no está disponible. Revisa la conexión a internet.';
        case 'not-found':
        case 'not_found':
          return 'Recurso no encontrado en Firebase.';
        default:
          return 'Error de Firebase (${error.code}).';
      }
    }
    if (error is StateError) {
      final m = error.message;
      if (m.contains('no encontrada')) {
        return 'Familia no encontrada. Comprueba que el QR sea correcto.';
      }
      return 'Error al procesar el código del QR.';
    }
    if (error is UnsupportedError) {
      return 'Unirse por QR no está disponible (hace falta Firebase en este dispositivo).';
    }
    return 'No se pudo unir a la familia.';
  }

  static String _technicalErrorText(Object error) {
    if (error is FirebaseException) {
      final msg = error.message;
      if (msg != null && msg.isNotEmpty) return '${error.code}: $msg';
      return error.code;
    }
    return error.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await widget.onScanned(code);
    } catch (e, st) {
      debugPrint('[QR join] $e\n$st');
      if (mounted) {
        setState(() {
          _processing = false;
          _error = _joinFailureDescription(e);
        });
      }
    }
  }

  void _onDetectError(Object error, StackTrace stackTrace) {
    debugPrint('[QR decode] $error\n$stackTrace');
    if (!mounted) return;
    setState(() {
      _processing = false;
      _error =
          'Fallo al leer o decodificar el código.\n\nDetalle: ${error.toString()}';
    });
  }

  Widget _cameraErrorWidget(BuildContext context, MobileScannerException error) {
    final detail = error.errorDetails?.message;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                error.errorCode.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (detail != null && detail.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Código interno: ${error.errorCode.name}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Escanear código QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            onDetectError: _onDetectError,
            errorBuilder: _cameraErrorWidget,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: 40,
            left: AppTheme.screenEdgePadding,
            right: AppTheme.screenEdgePadding,
            child: Column(
              children: [
                Text(
                  widget.hintText,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                    ),
                    child: SelectableText(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
                if (_processing) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
