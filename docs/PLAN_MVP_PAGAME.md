# Plan MVP - Pagame

Fecha: 2026-05-19

## Objetivo
Construir una app Android Flutter local-first para registrar pagos con adjuntos, recordatorios y bloqueo por autenticacion del sistema del dispositivo.

## Alcance MVP
- Pagos recurrentes mensuales y pagos unicos.
- Jerarquia: Categoria > Servicio > Ano > Mes > Pago.
- Adjuntos por pago: imagenes y PDF (multiples).
- Estados: Pendiente, Pagado, Vencido.
- Recordatorios: 3 dias antes, 1 dia antes y mismo dia.
- Hora global configurable para notificaciones.
- Vencido al finalizar el dia de vencimiento (23:59).
- Bloqueo al abrir y tras 5 minutos de inactividad, con autenticacion del sistema Android (biometria o credencial del dispositivo).
- Moneda por servicio (PEN por defecto) con soporte USD/EUR y edicion por pago.

## Reglas clave
- Categorias no predefinidas (usuario crea todo).
- Pagos unicos en categoria dedicada: Pago unico.
- Monto de pago puede estar vacio; el usuario elige estado al crear.
- Periodo de recurrentes: autogenerado y editable.
- Si se borra un pago, se elimina solo la copia interna del adjunto, no el archivo original del usuario.

## Fases
1. Bootstrap tecnico Flutter + arquitectura base por features.
2. Modelo de dominio y persistencia local.
3. Casos de uso (CRUD y reglas de negocio).
4. Seguridad de acceso.
5. Recordatorios y vencimientos.
6. UI principal MVP pantalla por pantalla.
7. Base de sincronizacion futura (Google Drive primero).

## Estrategia de desarrollo acordada
- Construccion incremental pantalla por pantalla.
- Validacion de cada pantalla antes de pasar a la siguiente.

## Nota de sincronizacion futura
- Prioridad futura: Google Drive.
- Regla de conflicto futura: preguntar al usuario.
