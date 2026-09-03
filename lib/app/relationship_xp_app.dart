import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../theme/app_theme.dart';

class RelationshipXpApp extends StatelessWidget {
  const RelationshipXpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relationship XP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
