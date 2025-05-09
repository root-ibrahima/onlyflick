import 'package:flutter/material.dart';
import 'package:MatchMaker/core/config/theme.dart';
import 'router.dart';

class OnlyFlickApp extends StatelessWidget {
  const OnlyFlickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MatchMaker',
      theme: appTheme,
      darkTheme: appTheme, // Using the same theme for dark mode until a dark theme is defined
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
