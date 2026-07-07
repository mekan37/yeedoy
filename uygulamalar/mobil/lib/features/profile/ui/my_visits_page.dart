import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Page that shows businesses the user has visited
class MyVisitsPage extends StatelessWidget {
  const MyVisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ziyaretlerim'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ziyaret geçmişin burada görünecek',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
