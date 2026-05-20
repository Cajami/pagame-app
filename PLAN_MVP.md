# Plan Págame MVP (Android Flutter)

## Objetivo
Construir un MVP local-first de Págame con la jerarquía:

Categoría > Servicio > Año > Mes > Pago

Incluye pagos únicos y recurrentes, adjuntos (imagen/PDF), recordatorios por vencimiento y bloqueo con autenticación del sistema Android (huella o credencial del dispositivo).

## Fases

1. Bootstrap técnico del proyecto Flutter y arquitectura base.
2. Modelo de dominio y persistencia local.
3. Casos de uso (CRUD, recurrencia, estados).
4. Seguridad de acceso (lock con auth del sistema).
5. Recordatorios y lógica de vencimiento.
6. UX principal por pantallas.
7. Base técnica para sincronización futura (Google Drive primero).
8. Validación funcional final.

## Decisiones cerradas

- MVP incluye: pagos únicos, pagos recurrentes mensuales, adjuntos múltiples, recordatorios, estado vencido, lock de app.
- Jerarquía: Categoría > Servicio > Año > Mes > Pago.
- No hay categorías predefinidas (el usuario crea todo), excepto la categoría operativa "Pago único" para ese tipo de registro.
- Adjuntos v1: imágenes y PDF.
- Recordatorios: 3 días antes, 1 día antes y mismo día.
- Hora de aviso: global, configurable por usuario.
- Vencido: al finalizar el día (23:59).
- Moneda: por servicio (PEN por defecto), editable por pago, soporte PEN/USD/EUR.
- Seguridad: autenticación del sistema Android, fallback a credencial del dispositivo.
- Intentos de desbloqueo: controlados por Android.
- Futuro sync: Google Drive prioritario; resolución de conflictos preguntando al usuario.

## Estrategia de ejecución

Desarrollo pantalla por pantalla:

1. Implementar pantalla.
2. Probar pantalla (widget test y validación funcional del flujo).
3. Ajustar.
4. Recién avanzar a la siguiente.

## Verificaciones clave

1. Crear categorías/servicios y validar orden descendente por años/meses.
2. Registrar pago con adjuntos múltiples y borrar solo la copia interna.
3. Validar recurrencia mensual por día fijo con periodo autogenerado + editable.
4. Validar recordatorios (3 días, 1 día, mismo día) y transición a vencido.
5. Validar lock al abrir app y tras 5 minutos de inactividad.
