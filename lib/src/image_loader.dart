import 'dart:async';

import '../flutter_progressive_image.dart';

/// Image bytes received callback
typedef BytesReceivedCallback = void Function(int cumulative, int? total);

/// Progressive image bytes loader
abstract class ProgressiveImageLoader {
  const ProgressiveImageLoader();

  /// Load image bytes
  ///
  /// [key] ProgressiveImage's key
  /// [onBytesReceived] bytes received callback
  Stream<List<int>> load(
    ProgressiveImage key,
    BytesReceivedCallback onBytesReceived,
  );
}
