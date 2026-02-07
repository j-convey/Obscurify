import 'package:flutter/material.dart';

class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Features'),
      ),
      body: const Center(
        child: Text(
          'AI Page',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
