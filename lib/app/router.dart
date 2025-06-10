import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matchmaker/features/home/presentation/pages/main_screen.dart';
import 'package:matchmaker/features/auth/presentation/pages/login_page.dart';
import 'package:matchmaker/features/auth/presentation/pages/register_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      name: 'main',
      builder: (BuildContext context, GoRouterState state) => const MainScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (BuildContext context, GoRouterState state) => const RegisterPage(),
    ),
  ],
);
