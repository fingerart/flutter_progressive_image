import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' hide BytesReceivedCallback;
import 'package:flutter/widgets.dart';

import 'image_loader.dart';
import 'progressive_converter.dart';
import 'progressive_image.dart' as image_provider;
import 'progressive_image.dart';

/// ProgressiveImage provider
class ProgressiveImage extends ImageProvider<image_provider.ProgressiveImage>
    implements image_provider.ProgressiveImage {
  const ProgressiveImage(
    this.url, {
    this.scale = 1.0,
    this.headers,
    this.imageLoader = const DefaultProgressiveImageIOLoader(),
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

  Stream<ui.Codec> _loadAsync(
    image_provider.ProgressiveImage key,
    StreamController<ImageChunkEvent> chunkEvents, {
    ImageDecoderCallback? decode,
  }) async* {
    assert(key == this);

    onBytesReceived(int cumulative, int? total) {
      chunkEvents.add(ImageChunkEvent(
        cumulativeBytesLoaded: cumulative,
        expectedTotalBytes: total,
      ));
    }

    try {
      yield* imageLoader
          .load(key, onBytesReceived)
          .transform(const ProgressiveConverter())
          .asyncMap((event) => emitCodec(event, decode!));
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
          scale == other.scale &&
          headers == other.headers &&
          imageLoader == other.imageLoader;

  @override
  int get hashCode =>
      url.hashCode ^ scale.hashCode ^ headers.hashCode ^ imageLoader.hashCode;
}

class DefaultProgressiveImageIOLoader extends ProgressiveImageLoader {
  const DefaultProgressiveImageIOLoader();

  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  @override
  Stream<List<int>> load(
    image_provider.ProgressiveImage key,
    BytesReceivedCallback onBytesReceived,
  ) async* {
    final Uri resolved = Uri.base.resolve(key.url);

    final HttpClientRequest request = await _httpClient.getUrl(resolved);

    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      // The network may be only temporarily unavailable, or the file will be
      // added on the server later. Avoid having future calls to resolve
      // fail to check the network again.
      await response.drain<List<int>>(<int>[]);
      throw NetworkImageLoadException(
          statusCode: response.statusCode, uri: resolved);
    }

    int? expectedContentLength = response.contentLength;
    if (expectedContentLength == -1) {
      expectedContentLength = null;
    }
    Stream<List<int>> stream = response;
    switch (response.compressionState) {
      case HttpClientResponseCompressionState.compressed:
        // We need to un-compress the bytes as they come in.
        stream = gzip.decoder.bind(response);
      case HttpClientResponseCompressionState.decompressed:
        // response.contentLength will not match our bytes stream, so we declare
        // that we don't know the expected content length.
        expectedContentLength = null;
      case HttpClientResponseCompressionState.notCompressed:
        // Fall-through.
        break;
    }

    int bytesReceived = 0;
    yield* stream.map((chunk) {
      bytesReceived += chunk.length;
      try {
        onBytesReceived(bytesReceived, expectedContentLength);
      } catch (_) {}
      return chunk;
    });
  }
}
