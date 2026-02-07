import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('はじめに', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('電話番号を入力してください', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            const TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '090-0000-0000',
                prefixIcon: Icon(Icons.phone, size: 30),
              ),
              style: TextStyle(fontSize: 24, letterSpacing: 2),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.go('/home');
              },
              child: const Text('ログインする'),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  '利用規約に同意して進む',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
