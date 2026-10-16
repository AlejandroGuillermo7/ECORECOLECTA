# EcoRecolecta

Prototipo de app web/móvil (Flutter) para seguir el camión recolector de basura.
Datos simulados. Taller de Investigación 2 · ITO.

## Cómo correrlo
1. Abre esta carpeta en VS Code (File > Open Folder).
2. En la terminal, dentro de la carpeta:

    flutter create --platforms=web,android --project-name ecorecolecta .
    flutter pub get
    flutter run -d chrome --release

(`flutter create .` genera las carpetas web/android sin tocar lib/ ni assets/.
Si pide sobrescribir pubspec.yaml o lib/main.dart, di que NO.)

---
© 2026 Alejandro Guillermo Enríquez Rodríguez. Todos los derechos reservados. Ver LICENSE.
