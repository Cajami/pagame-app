import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pagame/models/service_item.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Clase utilitaria premium para gestionar las notificaciones locales offline.
/// Emplea el programador nativo del sistema operativo (AlarmManager / UNNotificationRequest)
/// garantizando un consumo del 0% de batería en segundo plano.
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa la base de datos de zonas horarias y el canal de notificaciones locales.
  static Future<void> init() async {
    tz.initializeTimeZones();
    
    // Intenta detectar la zona horaria del dispositivo o usa un valor por defecto seguro (Lima/Bogotá)
    String timeZoneName = 'America/Lima';
    try {
      final localName = DateTime.now().timeZoneName;
      if (localName.contains('/')) {
        timeZoneName = localName;
      }
    } catch (_) {}

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('America/Lima'));
      } catch (_) {}
    }

    // Configuración específica de Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración de inicialización completa
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notificación presionada con payload: ${details.payload}');
      },
    );
  }

  /// Programa una notificación nativa en una fecha y hora específicas.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    
    // No programar en el pasado
    if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Recordatorios de Servicios',
      channelDescription: 'Canal para alertas de vencimientos de servicios',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error programando notificación zonedSchedule (ID: $id): $e');
    }
  }

  /// Cancela de forma determinista todas las alertas asociadas a un mes de pago.
  /// Esto se invoca automáticamente al registrar o modificar un pago del mes.
  static Future<void> cancelMonthlyReminders({
    required String serviceId,
    required int year,
    required int month,
  }) async {
    final baseId = serviceId.hashCode & 0x0FFFFFFF;
    final monthOffset = (year * 12 + month);

    for (int t = 0; t < 3; t++) {
      final id = baseId + ((monthOffset % 100000) * 3) + t;
      await _notificationsPlugin.cancel(id);
      debugPrint('Notificación cancelada por pago registrado: ID $id');
    }
  }

  /// Cancela todas las notificaciones pendientes de los próximos 6 meses para un servicio.
  static Future<void> cancelServiceReminders(ServiceItem service) async {
    final baseId = service.id.hashCode & 0x0FFFFFFF;
    final now = DateTime.now();

    for (int i = 0; i < 6; i++) {
      final targetYear = now.year + (now.month + i - 1) ~/ 12;
      final targetMonth = (now.month + i - 1) % 12 + 1;
      final monthOffset = (targetYear * 12 + targetMonth);

      for (int t = 0; t < 3; t++) {
        final id = baseId + ((monthOffset % 100000) * 3) + t;
        await _notificationsPlugin.cancel(id);
      }
    }
    debugPrint('Todos los recordatorios del servicio ${service.name} fueron cancelados.');
  }

  /// Recalcula y programa todos los recordatorios futuros para un servicio.
  /// Se invoca al guardar o actualizar la configuración de alertas de un servicio.
  static Future<void> scheduleServiceReminders(ServiceItem service) async {
    // 1. Limpiar recordatorios anteriores
    await cancelServiceReminders(service);

    // Si están desactivados, salimos tras limpiar
    if (!service.remindersEnabled) {
      return;
    }

    final now = DateTime.now();
    final baseId = service.id.hashCode & 0x0FFFFFFF;
    final isQuincena = service.billingCycle.toLowerCase().contains('quincena');

    // 2. Programar alertas para los próximos 6 meses
    for (int i = 0; i < 6; i++) {
      final targetYear = now.year + (now.month + i - 1) ~/ 12;
      final targetMonth = (now.month + i - 1) % 12 + 1;

      // Calcular el último día del mes objetivo (DateTime con día 0 del mes siguiente es el último día del mes actual)
      final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
      final monthOffset = (targetYear * 12 + targetMonth);

      // A: Notificación 5 días antes
      if (service.notify5Days) {
        final targetDay = isQuincena ? 10 : (lastDay - 5);
        final date5Days = DateTime(
          targetYear,
          targetMonth,
          targetDay,
          service.reminderHour,
          service.reminderMinute,
        );
        final id5Days = baseId + ((monthOffset % 100000) * 3) + 0;
        await scheduleNotification(
          id: id5Days,
          title: isQuincena ? 'Quincena de ${service.name}' : 'Vencimiento de ${service.name}',
          body: isQuincena
              ? 'Faltan 5 días para la quincena del servicio ${service.name}.'
              : 'Faltan 5 días para que finalice el mes de facturación de ${service.name}.',
          scheduledDate: date5Days,
        );
      }



      // C: Notificación el mismo día
      if (service.notifySameDay) {
        final targetDay = isQuincena ? 15 : lastDay;
        final dateSameDay = DateTime(
          targetYear,
          targetMonth,
          targetDay,
          service.reminderHour,
          service.reminderMinute,
        );
        final idSameDay = baseId + ((monthOffset % 100000) * 3) + 2;
        await scheduleNotification(
          id: idSameDay,
          title: isQuincena ? 'Quincena de ${service.name}' : 'Vencimiento de ${service.name}',
          body: isQuincena
              ? 'Hoy es el día de quincena del servicio ${service.name}. ¡Regístralo ahora!'
              : 'Hoy vence el período de pago de ${service.name}. ¡Regístralo ahora!',
          scheduledDate: dateSameDay,
        );
      }
    }
    
    debugPrint('Recordatorios configurados con éxito para ${service.name}.');
  }
}
