import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_progressive_image/progressive_image.dart';

typedef BytesReceivedCallback = void Function(int cumulative, int? total);

abstract class ProgressiveImageLoader {
  const ProgressiveImageLoader();

  Stream<List<int>> load(
      ProgressiveImage key, BytesReceivedCallback onBytesReceived);
}

class DefaultProgressiveImageLoader extends ProgressiveImageLoader {
  const DefaultProgressiveImageLoader();

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
      ProgressiveImage key, BytesReceivedCallback onBytesReceived) async* {
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
    // yield* gzip.decoder.bind();
  }
}
