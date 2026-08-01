import 'package:flutter/material.dart';

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Academy'), backgroundColor: Colors.indigo),
      body: Center(child: Text('IT Courses Coming Soon!')),
    );
  }
}
