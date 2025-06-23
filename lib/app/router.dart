import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:matchmaker/features/home/presentation/pages/main_screen.dart';
import 'package:matchmaker/features/auth/presentation/pages/login_page.dart';
import 'package:matchmaker/features/auth/presentation/pages/register_page.dart';
import 'package:matchmaker/features/auth/auth_provider.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  
  // Gestion de la redirection selon l'état d'authentification
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final isAuthRoute = ['/login', '/register'].contains(state.uri.toString());
    
    // Si l'utilisateur est connecté et essaie d'accéder aux pages d'auth
    if (authProvider.isAuthenticated && isAuthRoute) {
      return '/';
    }
    
    // Si l'utilisateur n'est pas connecté et essaie d'accéder aux pages protégées
    if (!authProvider.isAuthenticated && !isAuthRoute) {
      return '/login';
    }
    
    // Pas de redirection nécessaire
    return null;
  },
  
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