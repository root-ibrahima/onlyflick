import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:matchmaker/app/router.dart';
import 'package:matchmaker/features/auth/auth_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuth(),
      child: const OnlyFlickApp(),
    ),
  );
}

class OnlyFlickApp extends StatelessWidget {
  const OnlyFlickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OnlyFlick',
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    );
  }
}
