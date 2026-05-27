import 'package:flutter/material.dart';
import 'package:pagame/app.dart';
import 'package:pagame/utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationHelper.init();
  } catch (e) {
    debugPrint('Error inicializando notificaciones: $e');
  }
  runApp(const PagameApp());
}
