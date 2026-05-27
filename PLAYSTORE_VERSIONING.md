# Guía de Versionamiento para Publicación en Google Play Store (Págame)

Este documento detalla el procedimiento estándar y los pasos obligatorios para incrementar y sincronizar la versión de la aplicación **Págame** cuando se vaya a generar un nuevo compilado (AAB/APK) para su distribución comercial en Google Play Console.

---

## 📌 Estructura de Versión en Flutter

La versión de una aplicación de Flutter se define en el archivo [pubspec.yaml](file:///c:/OneDrive/DESARROLLOS/pagame-app/pubspec.yaml) utilizando la clave `version`. Sigue el formato estándar:

```yaml
version: [versionName]+[versionCode]
```

* **`versionName`** (ej. `1.0.0`): Es el nombre de la versión comercial visible para los usuarios en la tienda de aplicaciones. Sigue el versionamiento semántico (`Mayor.Menor.Parche`).
* **`versionCode`** (ej. `1`): Es un número entero incremental utilizado internamente por Google Play para determinar qué versión es más reciente. **Cada subida a Play Store debe tener un build number estrictamente superior al anterior** (ej. `1`, `2`, `3`, etc.).

---

## 🛠️ Procedimiento de Actualización de Versión

Cuando se decida realizar la publicación de una nueva actualización en Play Store, se deberán realizar los siguientes **dos (2) pasos obligatorios**:

### Paso 1: Actualizar `pubspec.yaml`
Modifica el valor `version` en [pubspec.yaml](file:///c:/OneDrive/DESARROLLOS/pagame-app/pubspec.yaml).
* **Ejemplo**: Si la versión actual es `1.0.0+1` y vas a lanzar una actualización:
  * Cambia a: `version: 1.1.0+2` (incrementando tanto el número comercial como el número de compilación interno).

```yaml
# pubspec.yaml
version: 1.1.0+2
```

### Paso 2: Sincronizar el Header de la UI en Flutter
Para mantener la transparencia con el usuario final, el indicador visual de versión en la esquina superior derecha de la pantalla principal debe actualizarse para coincidir con la versión de la tienda.
* Abre el archivo [categories_screen.dart](file:///c:/OneDrive/DESARROLLOS/pagame-app/lib/screens/categories/categories_screen.dart) y localiza el widget `_MainHeader` (alrededor de la línea 530).
* Modifica la cadena de texto `'v1.0'` por el nuevo valor correspondiente.

```dart
// lib/screens/categories/categories_screen.dart -> _MainHeader
Positioned(
  top: 16,
  right: 20,
  child: Text(
    'v1.1', // <-- Cambiar aquí al mismo versionName comercial
    style: TextStyle(
      color: Colors.white.withOpacity(0.55),
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  ),
)
```

---

## 📦 Comando de Compilación para Play Store (AAB)

Para subir la aplicación a Google Play Store, no se debe subir un APK, sino un paquete **Android App Bundle (AAB)** que está optimizado para la Play Store.
Ejecuta el siguiente comando en la terminal para compilar el paquete firmado:

```powershell
flutter build appbundle --release --no-tree-shake-icons
```

El archivo `.aab` generado se encontrará en la siguiente ruta listo para cargarse en Google Play Console:
`build\app\outputs\bundle\release\app-release.aab`
