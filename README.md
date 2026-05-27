# Págame

Págame es una aplicación móvil que desarrollé para registrar pagos recurrentes y únicos, adjuntar comprobantes físicos y gestionar recordatorios de fechas de vencimiento.

## 📱 Descarga e Instala en tu Android (Prueba Rápida)

¡Ya puedes probar la versión de producción directamente en tu teléfono Android! Preparé el instalador APK optimizado y listo para usar:

1. **Descarga el archivo APK**:
   👉 [**Descargar Págame APK (Última Versión)**](release/pagame.apk?raw=true)
   *(O navega a la carpeta [release/pagame.apk](release/pagame.apk) y haz clic en el botón "Download")*

2. **Instalación en tu móvil**:
   * Descarga el archivo `.apk` directamente en tu celular Android.
   * Abre el archivo descargado. Android te mostrará una advertencia de seguridad estándar sobre *"Instalar aplicaciones de fuentes desconocidas"*.
   * Simplemente ve a la configuración de la advertencia, selecciona **"Permitir desde esta fuente"** y presiona **Instalar**.
   * ¡Y listo! La aplicación se instalará en tu pantalla de inicio con todas sus funcionalidades de seguridad local por huella, adjuntos de archivos y copias de seguridad ZIP locales.

---

## ⭐ Características Destacadas (Features)

* **🔐 Seguridad Biométrica Nativa**: Bloqueo inteligente con huella dactilar o PIN del dispositivo para proteger tu privacidad al abrir la aplicación o reanudarla desde segundo plano.
* **📈 Estadísticas Avanzadas e Historial**: Panel analítico con gráfico de dona para distribución de gastos por categoría, e historial interactivo de consumo desplazable (gráfico de barras y tendencia) filtrable por año y moneda.
* **🔔 Recordatorios Offline Dinámicos**: Notificaciones locales automáticas programadas en el sistema operativo, adaptadas a ciclos mensuales (fin de mes) y quincenales (días 10 y 15). Se autocancelan de forma inteligente al registrar el pago del mes actual.
* **📸 Galería Inteligente de Recibos**: Toma fotos directamente desde la cámara, elije archivos de la galería o **reutiliza comprobantes** previamente guardados en otros pagos para ahorrar almacenamiento en tu móvil.
* **💱 Formateador Decimal ATM y Multimoneda**: Registro ágil con teclado inteligente de tipo ATM (base `0.00`) y selector premium de divisas: Soles (`S/`) y Dólares (`$`) con filtrado independiente.
* **🌓 Modo Oscuro Reactivo**: Alternancia instantánea de tema (claro/oscuro) con diseño premium de alta fidelidad que se guarda en la configuración persistente.
* **📂 Copias de Seguridad en un ZIP**: Exporta toda la base de datos SQLite y los recibos físicos en un solo archivo comprimido ZIP para compartir. Importador robusto y retrocompatible con sanitización de columnas obsoletas.
* **🗂️ Ordenamiento Alfabético Inteligente**: Organización reactiva alfabética de categorías y servicios para una navegación fluida, acompañada de iconos dinámicos según el tipo de cobro.

---

## 💾 Almacenamiento Local y Sincronización en la Nube

* **Estado Actual**: Por motivos de privacidad y seguridad, toda tu información, historial de pagos y archivos adjuntos (fotos y PDFs) se guardan de forma **100% local y segura** en el almacenamiento interno de tu propio dispositivo utilizando una base de datos SQLite.
* **Próximamente**: Agregaré la sincronización automática en la nube utilizando Google Drive para que puedas respaldar y restaurar tus datos en múltiples dispositivos sin complicaciones. Por ahora, puedes usar la función de **"Exportar datos y archivos"** desde los Ajustes para generar una copia de seguridad manual en un archivo ZIP.

---

## 🖼️ Capturas de Pantalla / Imágenes

<img width="610" height="1356" alt="WhatsApp Image 2026-05-25 at 07 55 45 (2)" src="https://github.com/user-attachments/assets/c9a44325-97ee-438d-be92-0f2e6db16c1d" />
<img width="610" height="1356" alt="WhatsApp Image 2026-05-25 at 07 55 45 (1)" src="https://github.com/user-attachments/assets/2155a865-7eea-4cae-8a68-08d7ae64f52b" />
<img width="610" height="1356" alt="WhatsApp Image 2026-05-25 at 07 55 45" src="https://github.com/user-attachments/assets/eb87da84-afe0-4054-8998-c32980fb0afe" />
<img width="610" height="1356" alt="WhatsApp Image 2026-05-25 at 07 55 44" src="https://github.com/user-attachments/assets/617eea6a-8810-490e-8ed6-f5ef9c27b927" />

---

## 🚀 Ejecución Rápida (Para Desarrolladores)

Si deseas ejecutar el proyecto en tu entorno local, asegúrate de tener Flutter configurado en tu PATH y ejecuta los siguientes comandos:

* Instalar dependencias:
  ```bash
  flutter pub get
  ```
* Analizar código:
  ```bash
  flutter analyze
  ```
* Ejecutar pruebas unitarias:
  ```bash
  flutter test
  ```
* Ejecutar en modo desarrollo:
  ```bash
  flutter run
  ```
