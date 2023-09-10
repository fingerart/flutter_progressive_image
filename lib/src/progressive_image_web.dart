import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' hide BytesReceivedCallback;
import 'package:flutter/widgets.dart';
import 'package:flutter_progressive_image/src/progressive_converter.dart';

import 'image_loader.dart';
import 'progressive_image.dart' as image_provider;
import 'progressive_image.dart';

class ProgressiveImage extends ImageProvider<image_provider.ProgressiveImage>
    implements image_provider.ProgressiveImage {
  const ProgressiveImage(
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
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

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
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return image_provider.ProgressiveImageStreamCompleter(
      frameEvents: _loadAsync(key, chunkEvents, decode: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
    );
  }

  Stream<ui.Codec> _loadAsync(
    image_provider.ProgressiveImage key,
    StreamController<ImageChunkEvent> chunkEvents, {
    ImageDecoderCallback? decode,
    DecoderBufferCallback? decodeBufferDeprecated,
    DecoderCallback? decodeDeprecated,
  }) async* {
    final Uri resolved = Uri.base.resolve(key.url);

    onBytesReceived(int cumulative, int? total) {
      chunkEvents.add(ImageChunkEvent(
        cumulativeBytesLoaded: cumulative,
        expectedTotalBytes: total,
      ));
    }

    final bool containsNetworkImageHeaders = key.headers?.isNotEmpty ?? false;

    // We use a different method when headers are set because the
    // `ui.webOnlyInstantiateImageCodecFromUrl` method is not capable of handling headers.
    if (isCanvasKit || containsNetworkImageHeaders) {
      yield* imageLoader
          .load(key, onBytesReceived)
          .transform(const ProgressiveConverter())
          .asyncMap((event) => emitCodec(
                Uint8List.fromList(event),
                decode,
                decodeBufferDeprecated,
                decodeDeprecated,
              ));
      return;
    }

    // This API only exists in the web engine implementation and is not
    // contained in the analyzer summary for Flutter.
    // ignore: undefined_function, avoid_dynamic_calls
    yield* (ui.webOnlyInstantiateImageCodecFromUrl(
      resolved,
      chunkCallback: onBytesReceived,
    ) as Future<ui.Codec>)
        .asStream();
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
    final resp = await HttpRequest.request(
      key.url,
      responseType: 'arraybuffer',
      requestHeaders: key.headers,
      onProgress: (e) => onBytesReceived(e.loaded ?? 0, e.total),
    );

    yield (resp.response as ByteBuffer).asUint8List();
  }
}
