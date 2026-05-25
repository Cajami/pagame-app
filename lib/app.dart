import 'package:flutter/material.dart';
import 'package:pagame/screens/categories/categories_screen.dart';
import 'package:pagame/theme/app_theme.dart';
import 'package:pagame/widgets/common/security_guard.dart';

class PagameApp extends StatelessWidget {
  const PagameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pagame',
      theme: AppTheme.lightTheme(),
      home: const SecurityGuard(
        child: CategoriesScreen(),
      ),
    );
  }
}
