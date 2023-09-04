import 'dart:async';

import 'package:flutter/foundation.dart' hide BytesReceivedCallback;
import 'package:flutter/widgets.dart';

import 'image_loader.dart';
import 'progressive_image.dart' as image_provider;

class ProgressiveImage extends ImageProvider<image_provider.ProgressiveImage>
    implements image_provider.ProgressiveImage {
  ProgressiveImage(
    this.url, {
    this.scale = 1.0,
    this.headers,
    this.imageLoader = const DefaultProgressiveImageWebLoader(),
  });

  @override
  final String url;

  @override
  final double scale;

  @override
  final Map<String, String>? headers;

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
      other is ProgressiveImage &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          scale == other.scale &&
          headers == other.headers &&
          imageLoader == other.imageLoader;

  @override
  int get hashCode =>
      url.hashCode ^ scale.hashCode ^ headers.hashCode ^ imageLoader.hashCode;
}


class DefaultProgressiveImageWebLoader extends ProgressiveImageLoader {
  const DefaultProgressiveImageWebLoader();

  @override
  Stream<List<int>> load(
      image_provider.ProgressiveImage key,
      BytesReceivedCallback onBytesReceived,
      ) async* {

    final Uri resolved = Uri.base.resolve(key.url);

    final bool containsNetworkImageHeaders = key.headers?.isNotEmpty ?? false;

    /*int bytesReceived = 0;
    yield* stream.map((chunk) {
      bytesReceived += chunk.length;
      try {
        onBytesReceived(bytesReceived, expectedContentLength);
      } catch (_) {}
      return chunk;
    });*/
  }
}
