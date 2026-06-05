import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pagame/screens/categories/categories_screen.dart';
import 'package:pagame/theme/app_colors.dart';
import 'package:pagame/theme/app_theme.dart';
import 'package:pagame/utils/database_helper.dart';
import 'package:pagame/widgets/common/security_guard.dart';

class PagameApp extends StatefulWidget {
  const PagameApp({super.key});

  static PagameAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<PagameAppState>();

  @override
  State<PagameApp> createState() => PagameAppState();
}

class PagameAppState extends State<PagameApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final mode = await DatabaseHelper.instance.getConfig('dark_mode');
      if (mounted) {
        setState(() {
          AppColors.isDark = mode == '1';
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error cargando tema: $e');
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  void toggleTheme(bool dark) {
    setState(() {
      AppColors.isDark = dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        locale: Locale('es', 'ES'),
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pagame',
      theme: AppColors.isDark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      home: const SecurityGuard(
        child: CategoriesScreen(),
      ),
    );
  }
}
