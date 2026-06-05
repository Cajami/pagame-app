# Págame

Págame es una aplicación móvil que desarrollé para registrar pagos recurrentes y únicos, adjuntar comprobantes físicos y gestionar recordatorios de fechas de vencimiento.

## 📱 Descarga e Instalación en Android

¡Págame ya está disponible de forma oficial en la Google Play Store! Puedes instalarla de manera rápida y segura directamente desde la tienda:

<a href="https://play.google.com/store/apps/details?id=com.cajami.pagame">
  <img alt="Disponible en Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/es_badge_web_generic.png" height="75"/>
</a>

---

### 📦 Alternativa de Descarga Directa (APK)
Si prefieres no usar la tienda de Google o tienes un dispositivo sin servicios de Google (como Huawei), puedes descargar e instalar directamente nuestro instalador oficial compilado:

* 👉 [**Descargar Págame APK (Última Versión)**](release/pagame.apk?raw=true)
* *Nota de instalación:* Al abrir el archivo `.apk` descargado, Android te mostrará una advertencia de seguridad estándar sobre la instalación de fuentes desconocidas. Simplemente selecciona "Permitir desde esta fuente" para completar la instalación en tu pantalla de inicio en segundos.

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

<a href="https://github.com/user-attachments/assets/c9a44325-97ee-438d-be92-0f2e6db16c1d" target="_blank">
  <img src="https://github.com/user-attachments/assets/c9a44325-97ee-438d-be92-0f2e6db16c1d" width="250"/>
</a>
<a href="https://github.com/user-attachments/assets/9d3680e8-7392-4f76-a2c4-0f800d290f42" target="_blank">
  <img src="https://github.com/user-attachments/assets/9d3680e8-7392-4f76-a2c4-0f800d290f42" width="250"/>
</a>
<a href="https://github.com/user-attachments/assets/4121c16d-99e1-4398-80ef-11bff62e8e44" target="_blank">
  <img src="https://github.com/user-attachments/assets/4121c16d-99e1-4398-80ef-11bff62e8e44" width="250"/>
</a>
<a href="https://github.com/user-attachments/assets/5a76fe25-dcf1-4ea6-82ab-68218f4150db" target="_blank">
  <img src="https://github.com/user-attachments/assets/5a76fe25-dcf1-4ea6-82ab-68218f4150db" width="250"/>
</a>
<a href="https://github.com/user-attachments/assets/76861025-810b-4451-949f-7d4915bf60fb" target="_blank">
  <img src="https://github.com/user-attachments/assets/76861025-810b-4451-949f-7d4915bf60fb" width="250"/>
</a>

<a href="https://github.com/user-attachments/assets/d383817a-911e-4522-b4a6-2a3ad44b9fd7" target="_blank">
  <img src="https://github.com/user-attachments/assets/d383817a-911e-4522-b4a6-2a3ad44b9fd7" width="250"/>
</a>
<a href="https://github.com/user-attachments/assets/b83f3abd-a9cd-47e8-905c-89f37675c76d" target="_blank">
  <img src="https://github.com/user-attachments/assets/b83f3abd-a9cd-47e8-905c-89f37675c76d" width="250"/>
</a>

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
