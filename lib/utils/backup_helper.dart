import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/utils/notification_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class BackupHelper {
  /// Exports all database tables and physical attachment files to a single ZIP.
  /// Then triggers native sharing to let the user save it.
  static Future<bool> exportBackup() async {
    try {
      // 1. Fetch raw rows from SQLite database
      final dbHelper = DatabaseHelper.instance;
      final categories = await dbHelper.getAllCategoriesRaw();
      final services = await dbHelper.getAllServicesRaw();
      final years = await dbHelper.getAllYearsRaw();
      final months = await dbHelper.getAllMonthsRaw();
      final payments = await dbHelper.getAllPaymentsRaw();

      // 2. Build the backup JSON
      final data = {
        'categorias': categories,
        'servicios': services,
        'anios': years,
        'meses': months,
        'pagos': payments,
      };

      final dataJsonString = jsonEncode(data);
      final dataBytes = utf8.encode(dataJsonString);

      // 3. Create a ZIP Archive
      final archive = Archive();
      archive.addFile(ArchiveFile('data.json', dataBytes.length, dataBytes));

      // 4. Gather and pack all active attachment files
      final Set<String> processedFiles = {};
      for (final payment in payments) {
        final adjuntosRaw = payment['adjuntos'] as String?;
        if (adjuntosRaw != null) {
          final List<dynamic> paths = jsonDecode(adjuntosRaw) as List;
          for (final path in paths) {
            final pathStr = path as String;
            if (pathStr.isNotEmpty && !processedFiles.contains(pathStr)) {
              processedFiles.add(pathStr);
              final file = File(pathStr);
              if (await file.exists()) {
                final fileBytes = await file.readAsBytes();
                final fileName = pathStr.split('/').last.split('\\').last;
                archive.addFile(
                  ArchiveFile(
                    'attachments/$fileName',
                    fileBytes.length,
                    fileBytes,
                  ),
                );
              }
            }
          }
        }
      }

      // 5. Encode to ZIP bytes
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        throw Exception('No se pudo generar el archivo ZIP de respaldo.');
      }

      // 6. Save ZIP permanently to temporary app databases directory
      final dbPath = await dbHelper.database.then((db) => db.path);
      final dbDir = Directory(p.dirname(dbPath));
      
      final now = DateTime.now();
      final yearStr = now.year.toString();
      final monthStr = now.month.toString().padLeft(2, '0');
      final dayStr = now.day.toString().padLeft(2, '0');
      final hourStr = now.hour.toString().padLeft(2, '0');
      final minuteStr = now.minute.toString().padLeft(2, '0');
      final formattedDateTime = '$yearStr$monthStr${dayStr}_$hourStr$minuteStr';
      
      final zipName = 'respaldo_pagame_$formattedDateTime.zip';
      final zipPath = p.join(dbDir.path, zipName);
      
      final tempZipFile = File(zipPath);
      if (await tempZipFile.exists()) {
        await tempZipFile.delete();
      }
      await tempZipFile.writeAsBytes(zipBytes);

      // 7. Share the ZIP file natively
      // ignore: deprecated_member_use
      final result = await Share.shareXFiles(
        [XFile(zipPath)],
        text: 'Copia de seguridad Págame App',
      );

      return result.status == ShareResultStatus.success || 
             result.status == ShareResultStatus.dismissed; // On some platforms share status is dismissed but successful
    } catch (e) {
      debugPrint('Backup export failed: $e');
      return false;
    }
  }

  /// Restores a ZIP backup: extracts files locally and imports SQLite rows.
  static Future<String?> importBackup() async {
    try {
      // 1. Pick ZIP file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.single.path == null) {
        return 'Importación cancelada.';
      }

      final zipFile = File(result.files.single.path!);
      final bytes = await zipFile.readAsBytes();

      // 2. Decode the ZIP
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // 3. Find and parse data.json
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) {
        return 'El archivo no contiene un respaldo válido de Págame (falta data.json).';
      }

      final dataContent = utf8.decode(dataFile.content as List<int>);
      final Map<String, dynamic> data = jsonDecode(dataContent);

      // 4. Create local permanent attachments directory
      final dbHelper = DatabaseHelper.instance;
      final dbPath = await dbHelper.database.then((db) => db.path);
      final dbDir = Directory(p.dirname(dbPath));
      final importedAttachmentsDir = Directory(p.join(dbDir.path, 'imported_attachments'));
      if (!await importedAttachmentsDir.exists()) {
        await importedAttachmentsDir.create(recursive: true);
      }

      // 5. Extract and copy attachment files physically
      final Map<String, String> fileNameToNewPath = {};
      for (final file in archive) {
        if (file.name.startsWith('attachments/') && file.isFile) {
          final fileName = file.name.substring('attachments/'.length);
          final fileData = file.content as List<int>;
          final newPath = p.join(importedAttachmentsDir.path, fileName);
          
          await File(newPath).writeAsBytes(fileData);
          fileNameToNewPath[fileName] = newPath;
        }
      }

      // 6. Write tables to SQLite database
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Insert Categories
        final categories = List<Map<String, dynamic>>.from(data['categorias'] ?? []);
        for (final row in categories) {
          if (row['id'] == null) continue;
          final sanitizedRow = {
            'id': row['id'] as String,
            'name': row['name'] as String? ?? '',
            'icon_codepoint': row['icon_codepoint'] as int? ?? 0,
            'color_value': row['color_value'] as int? ?? 0,
          };
          await txn.insert('categorias', sanitizedRow, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Insert Services
        final services = List<Map<String, dynamic>>.from(data['servicios'] ?? []);
        for (final row in services) {
          if (row['id'] == null) continue;
          final sanitizedRow = {
            'id': row['id'] as String,
            'categoria_id': row['categoria_id'] as String? ?? '',
            'name': row['name'] as String? ?? '',
            'billing_cycle': row['billing_cycle'] as String? ?? 'Fin de mes',
            'reminders_enabled': row['reminders_enabled'] as int? ?? 0,
            'reminder_hour': row['reminder_hour'] as int? ?? 8,
            'reminder_minute': row['reminder_minute'] as int? ?? 0,
            'notify_5_days': row['notify_5_days'] as int? ?? 1,
            'notify_same_day': row['notify_same_day'] as int? ?? 1,
          };
          await txn.insert('servicios', sanitizedRow, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Insert Years
        final years = List<Map<String, dynamic>>.from(data['anios'] ?? []);
        for (final row in years) {
          if (row['id'] == null) continue;
          final sanitizedRow = {
            'id': row['id'] as String,
            'servicio_id': row['servicio_id'] as String? ?? '',
            'anio': row['anio'] as int? ?? DateTime.now().year,
          };
          await txn.insert('anios', sanitizedRow, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Insert Months
        final months = List<Map<String, dynamic>>.from(data['meses'] ?? []);
        for (final row in months) {
          if (row['id'] == null) continue;
          final sanitizedRow = {
            'id': row['id'] as String,
            'anio_id': row['anio_id'] as String? ?? '',
            'mes': row['mes'] as int? ?? 1,
          };
          await txn.insert('meses', sanitizedRow, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // Insert Payments (and update attachments path dynamically)
        final payments = List<Map<String, dynamic>>.from(data['pagos'] ?? []);
        for (final row in payments) {
          if (row['id'] == null) continue;
          
          final adjuntosRaw = row['adjuntos'] as String?;
          List<String> newPaths = [];
          if (adjuntosRaw != null) {
            try {
              final List<dynamic> oldPaths = jsonDecode(adjuntosRaw) as List;
              for (final oldPath in oldPaths) {
                final fileName = (oldPath as String).split('/').last.split('\\').last;
                if (fileNameToNewPath.containsKey(fileName)) {
                  newPaths.add(fileNameToNewPath[fileName]!);
                } else {
                  newPaths.add(oldPath);
                }
              }
            } catch (_) {}
          }

          final sanitizedRow = {
            'id': row['id'] as String,
            'mes_id': row['mes_id'] as String? ?? '',
            'monto': row['monto'] != null ? (row['monto'] as num).toDouble() : null,
            'estado': row['estado'] as String? ?? 'Pagado',
            'fecha_pago': row['fecha_pago'] as String? ?? DateTime.now().toIso8601String(),
            'notas': row['notas'] as String?,
            'adjuntos': jsonEncode(newPaths),
            'moneda': row['moneda'] as String? ?? 'PEN',
          };
          await txn.insert('pagos', sanitizedRow, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      // 7. Reschedule all reminders for imported services dynamically in the OS
      try {
        final allServices = await dbHelper.getAllServices();
        for (final service in allServices) {
          if (service.remindersEnabled) {
            await NotificationHelper.scheduleServiceReminders(service);
          }
        }
      } catch (e) {
        debugPrint('Failed to reschedule reminders after import: $e');
      }

      return null; // Success
    } catch (e) {
      debugPrint('Backup import failed: $e');
      return 'Ocurrió un error al importar el respaldo: $e';
    }
  }
}
