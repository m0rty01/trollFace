import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/call');
                },
                child: const Text('Start Call'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Friends', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: CircleAvatar(radius: 28, child: Text('F${i+1}')),
                )),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Calls', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, i) => ListTile(
                  leading: const Icon(Icons.call),
                  title: Text('Friend ${i+1}'),
                  subtitle: const Text('Yesterday'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 