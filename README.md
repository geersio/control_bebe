# MiBebé

App Flutter para el seguimiento del bebé: peso, alimentación (pecho/biberón) y pañales.

## Características

- **Peso**: Registro de peso con gráfica de evolución y comparación con percentiles OMS
- **Alimentación**: Cronómetro de lactancia (pecho izquierdo/derecho) y registro de biberón
- **Pañales**: Control de cambios (mojado, sucio, ambos) con actualizaciones optimistas
- **Home**: Panel resumen con tarjetas reordenables, carga paralela de datos
- **Autenticación**: Login/registro con Firebase Auth (Google, Apple, email)
- **Familias**: Compartir perfil del bebé mediante QR para acceso multi-dispositivo
- **Ajustes**: Perfil del bebé, compartir familia, cerrar sesión

## Stack

- Flutter 3.x
- Riverpod (estado)
- Firebase Auth, Firestore (móvil) / SharedPreferences (web)
- fl_chart (gráficos)
- Material 3

## Requisitos

- Flutter SDK >= 3.11.0
- Dart >= 3.11.0
- Cuenta Firebase (para auth y Firestore)

## Configuración

1. Configura Firebase en el proyecto (ver `FIREBASE_SETUP.md`)
2. Para Google Sign-In en web: `docs/CONFIGURACION_GOOGLE_SIGNIN.md`
3. Para Apple Sign-In: configura `Info.plist` según la documentación

## Ejecutar

```bash
flutter pub get
flutter run
```

## Plataformas

- iOS, Android, Web, Windows
