import 'package:go_router/go_router.dart';
import 'package:matchmaker/features/home/presentation/pages/home_page.dart';
import 'package:matchmaker/features/start/presentation/pages/start_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/start',
      name: 'start',
      builder: (context, state) => const StartPage(),
    ),
  ],
);
