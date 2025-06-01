import 'package:flutter/material.dart';

class SubscriptionWidget extends StatefulWidget {
  const SubscriptionWidget({super.key});

  @override
  State<SubscriptionWidget> createState() => _SubscriptionWidgetState();
}

class _SubscriptionWidgetState extends State<SubscriptionWidget> {
  bool isSubscribed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isSubscribed)
          const Text('Contenu Premium')
        else
          const Text('Contenu réservé aux abonnés'),
        const SizedBox(height: 20),
        ElevatedButton(
          key: const Key('subscribeButton'),
          onPressed: () {
            setState(() => isSubscribed = true);
          },
          child: const Text('S’abonner'),
        ),
      ],
    );
  }
}
