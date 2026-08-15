# Icono de la app

La fuente oficial del icono es `assets/images/Mibebé_icon_1024px.png`.
`flutter_launcher_icons` genera desde ella todos los tamaños necesarios para
Android e iOS.
La variante `Mibebe_icon_ios_1024px.png` es la copia opaca requerida por Apple.
La variante `Mibebe_splash_1024px.png` añade margen para mostrar el icono más
pequeño en las pantallas de inicio.

## Requisitos de Apple para el icono iOS

| Formato | Tamaño mínimo | Notas |
|---------|---------------|-------|
| 1024×1024 px | Obligatorio | Base para generar todos los tamaños |
| PNG | Sin transparencia | iOS usa fondo sólido si hay transparencia |
| Cuadrado | Sin bordes redondeados | iOS aplica la máscara automáticamente |

## Cómo actualizarlo

1. Sustituye `assets/images/Mibebé_icon_1024px.png` por el nuevo icono,
   conservando el nombre y un tamaño de **1024×1024 píxeles**.
2. Ejecuta:
   ```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```
3. Reinstala la app en el dispositivo.

### Herramientas para redimensionar

- **Figma / Canva**: exportar a 1024×1024.
- **Photoshop / GIMP**: Image → Image Size.
- **Online**: [resizeimage.net](https://resizeimage.net) (asegúrate de no perder calidad).

