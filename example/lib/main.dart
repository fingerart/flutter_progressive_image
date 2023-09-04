import 'package:flutter/material.dart';
import 'package:flutter_progressive_image/progressive_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final url =
      'https://raw.githubusercontent.com/HabibSlim/JPEGDecoder/master/images/progressive/color/vertical_prog.jpg';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Image(
            image: ProgressiveImage(
              url,
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
