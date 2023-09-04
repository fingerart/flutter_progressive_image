import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_progressive_image/image_loader.dart';

import 'progressive_converter.dart';
import 'progressive_image.dart' as image_provider;

/// ProgressiveImage provider
class ProgressiveImage extends ImageProvider<image_provider.ProgressiveImage>
    implements image_provider.ProgressiveImage {
  ProgressiveImage(
    this.url, {
    this.scale = 1.0,
    this.imageLoader = const DefaultProgressiveImageLoader(),
  });

  @override
  final String url;

  @override
  final double scale;

  @override
  final ProgressiveImageLoader imageLoader;

  @override
  Future<image_provider.ProgressiveImage> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter load(
      image_provider.ProgressiveImage key, DecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return image_provider.ProgressiveImageStreamCompleter(
      frameEvents: _loadAsync(key, chunkEvents, decodeDeprecated: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
    );
  }

  @override
  ImageStreamCompleter loadBuffer(
    image_provider.ProgressiveImage key,
    DecoderBufferCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return image_provider.ProgressiveImageStreamCompleter(
      frameEvents: _loadAsync(key, chunkEvents, decodeBufferDeprecated: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
    );
  }

  @override
  ImageStreamCompleter loadImage(
    image_provider.ProgressiveImage key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return image_provider.ProgressiveImageStreamCompleter(
      frameEvents: _loadAsync(key, chunkEvents, decode: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
    );
  }

  Stream<image_provider.ProgressiveFrame> _loadAsync(
    image_provider.ProgressiveImage key,
    StreamController<ImageChunkEvent> chunkEvents, {
    ImageDecoderCallback? decode,
    DecoderBufferCallback? decodeBufferDeprecated,
    DecoderCallback? decodeDeprecated,
  }) async* {
    assert(key == this);

    onBytesReceived(int cumulative, int? total) {
      print('$cumulative/$total');
      chunkEvents.add(ImageChunkEvent(
        cumulativeBytesLoaded: cumulative,
        expectedTotalBytes: total,
      ));
    }

    try {
      yield* imageLoader
          .load(key, onBytesReceived)
          .transform(const ProgressiveConverter())
          .asyncMap((event) {
        return _emitCodec(
            event, decode, decodeBufferDeprecated, decodeDeprecated);
      });
    } catch (_) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressiveImage &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          scale == other.scale;

  @override
  int get hashCode => url.hashCode ^ scale.hashCode;
}

Future<image_provider.ProgressiveFrame> _emitCodec(
  Uint8List bytes,
  ImageDecoderCallback? decode,
  DecoderBufferCallback? decodeBufferDeprecated,
  DecoderCallback? decodeDeprecated,
) async {
  if (decode != null) {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  } else if (decodeBufferDeprecated != null) {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decodeBufferDeprecated(buffer);
  } else {
    assert(decodeDeprecated != null);
    return decodeDeprecated!(bytes);
  }
}
