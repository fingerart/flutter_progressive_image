import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_progressive_image/image_loader.dart';
import 'package:flutter_progressive_image/progressive_image.dart'
    as image_provider;

class ProgressiveImage extends ImageProvider<image_provider.ProgressiveImage>
    implements image_provider.ProgressiveImage {
  ProgressiveImage(this.url, {this.scale = 1.0});

  @override
  final String url;

  @override
  final double scale;

  @override
  Future<image_provider.ProgressiveImage> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter load(
      image_provider.ProgressiveImage key, DecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return image_provider.ProgressiveImageStreamCompleter(
      frameEvents: _loadAsync(chunkEvents, decodeDeprecated: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
    );
  }

  @override
  ImageStreamCompleter loadBuffer(
    image_provider.ProgressiveImage key,
    DecoderBufferCallback decode,
  ) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return image_provider.ProgressiveImageStreamCompleter(
      frameEvents: _loadAsync(chunkEvents, decodeBufferDeprecated: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
    );
  }

  @override
  ImageStreamCompleter loadImage(
    image_provider.ProgressiveImage key,
    ImageDecoderCallback decode,
  ) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return image_provider.ProgressiveImageStreamCompleter(
      frameEvents: _loadAsync(chunkEvents, decode: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
    );
  }

  Stream<image_provider.ProgressiveFrame> _loadAsync(
    StreamController<ImageChunkEvent> chunkEvents, {
    ImageDecoderCallback? decode,
    DecoderBufferCallback? decodeBufferDeprecated,
    DecoderCallback? decodeDeprecated,
  }) async* {
    final bytes = Uint8List(0);
    const isEnd = false;

    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressiveImage && runtimeType == other.runtimeType;

  @override
  // TODO: implement imageLoader
  ProgressiveImageLoader get imageLoader => throw UnimplementedError();
}
