# 🛒 ZonaMarket
**Este proyecto se encuentra actualmente en desarrollo y no está terminado.**

Aplicación móvil de marketplace desarrollada en Flutter que permite a los usuarios comprar y vender productos desde Android, iOS y Web.

---

## 🧰 Tecnologías

- **Flutter** (Dart)
- **Android**, **iOS** y **Web**
- Conexión a [ZonaMarket API](https://github.com/Mangel-CC/API-MarketPlace)

---

## 📁 Estructura del proyecto

```
zonamarket/
├── android/          # Configuración nativa Android
├── ios/              # Configuración nativa iOS
├── web/              # Configuración para Web
├── lib/              # Código fuente principal de Flutter
├── test/             # Pruebas
├── pubspec.yaml      # Dependencias del proyecto
└── pubspec.lock
```

---

## ⚙️ Instalación y configuración

### Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x o superior
- Dart SDK (incluido con Flutter)
- Android Studio / Xcode (para compilar en móvil)
- Un navegador moderno (para web)

### 1. Clonar el repositorio

```bash
git clone https://github.com/Mangel-CC/ZonaMarket.git
cd zonamarket
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Verificar configuración

```bash
flutter doctor
```

Asegúrate de que no haya errores críticos antes de correr la app.

### 4. Correr la aplicación

**Android:**
```bash
flutter run
```

**iOS:**
```bash
flutter run -d ios
```

**Web:**
```bash
flutter run -d chrome
```

---

## 📦 Build para producción

### Android (APK)

```bash
flutter build apk --release
```

El archivo se genera en `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle para Play Store)

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

> Requiere una Mac con Xcode y una cuenta de desarrollador de Apple.

### Web

```bash
flutter build web --release
```

Los archivos se generan en `build/web/` y pueden desplegarse en cualquier servidor web estático.

---

## 🌐 API

Esta app consume la [ZonaMarket API](https://github.com/Mangel-CC/API-MarketPlace). Asegúrate de tener la API corriendo antes de usar la app.

---

## 📄 Licencia

MIT
