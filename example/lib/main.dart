import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      'https://raw.githubusercontent.com/fingerart/flutter_progressive_image/main/arts/example_progressive_image.jpg';

  double? progress;

  @override
  void initState() {
    super.initState();
    _startListenProgress();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Progressive image example'),
        ),
        body: Column(
          children: [
            const SizedBox(height: 15),
            Expanded(
              child: Image(
                image: NetworkImage(url),
                frameBuilder: _buildFrameBuilder,
                errorBuilder: _buildImageError,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Loading: ${((progress ?? 0) * 100).toInt()}%',
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    debugPrint(error.toString());
    debugPrintStack(stackTrace: stackTrace);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image_not_supported_outlined),
        const SizedBox(height: 5),
        Text(error.toString(), style: const TextStyle(color: Colors.red))
      ],
    );
  }

  Widget _buildFrameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    return frame == null
        ? const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : child;
  }

  void _startListenProgress() {
    var streamListener = ImageStreamListener(
      (image, synchronousCall) {},
      onChunk: (event) {
        if (event.expectedTotalBytes != null) {
          setState(() {
            progress = event.cumulativeBytesLoaded / event.expectedTotalBytes!;
          });
        }
      },
    );
    NetworkImage(url)
        .resolve(ImageConfiguration.empty)
        .addListener(streamListener);
  }
}