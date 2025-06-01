import 'package:flutter/material.dart';
import 'package:matchmaker/features/subscription/presentation/widgets/subscription_widget.dart';

class SubscriptionTestPage extends StatelessWidget {
  const SubscriptionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Abonnement')),
      body: const Center(child: SubscriptionWidget()),
    );
  }
}
