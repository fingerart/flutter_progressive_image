import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'image_loader.dart';
import 'progressive_image_io.dart'
    if (dart.library.js_util) 'progressive_image_web.dart' as progressive_image;

typedef ProgressiveFrame = ui.Codec;

abstract class ProgressiveImage extends ImageProvider<ProgressiveImage> {
  double get scale;

  String get url;

  ProgressiveImageLoader get imageLoader;

  Map<String, String>? get headers;

  factory ProgressiveImage(
    String url, {
    double scale,
    Map<String, String>? headers,
    ProgressiveImageLoader imageLoader,
  }) = progressive_image.ProgressiveImage;
}

class ProgressiveImageStreamCompleter extends ImageStreamCompleter {
  final double scale;
  StreamSubscription? _frameSubscription;
  StreamSubscription? _chunkSubscription;

  ProgressiveFrame? _currentCodec;
  ui.FrameInfo? _currentFrame;
  bool _hasEmitFrame = false;

  ProgressiveImageStreamCompleter({
    required Stream<ProgressiveFrame> frameEvents,
    Stream<ImageChunkEvent>? chunkEvents,
    required this.scale,
  }) {
    _frameSubscription = frameEvents.listen(
      _progressiveImageHandle,
      onError: (Object e, StackTrace st) {
        reportError(
          context: ErrorDescription('loading an image'),
          exception: e,
          stack: st,
          silent: true,
        );
      },
    );

    if (chunkEvents != null) {
      _chunkSubscription = chunkEvents.listen(
        reportImageChunkEvent,
        onError: (Object e, StackTrace st) {
          reportError(
            context: ErrorDescription('loading an image'),
            exception: e,
            stack: st,
            silent: true,
          );
        },
      );
    }
  }

  void _progressiveImageHandle(ProgressiveFrame frame) {
    _currentCodec = frame;
    assert(_currentCodec != null);

    if (hasListeners) {
      _decodeNextFrameAndSchedule();
    }
  }

  Future<void> _decodeNextFrameAndSchedule() async {
    _currentFrame?.image.dispose();
    _currentFrame = null;
    try {
      _currentFrame = await _currentCodec!.getNextFrame();
    } catch (e, st) {
      reportError(
        context: ErrorDescription('resolving an image frame'),
        exception: e,
        stack: st,
        silent: true,
      );
      return;
    }

    // Only supports single frame images
    _emitFrame(ImageInfo(
      image: _currentFrame!.image.clone(),
      scale: scale,
    ));
    _currentFrame?.image.dispose();
    _currentFrame = null;
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _hasEmitFrame = true;
  }

  @override
  void addListener(ImageStreamListener listener) {
    if (!hasListeners && _currentCodec != null && !_hasEmitFrame) {
      _decodeNextFrameAndSchedule();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _dispose();
    }
  }

  void _dispose() {
    _chunkSubscription?.onData(null);
    _chunkSubscription?.cancel();
    _chunkSubscription = null;

    _frameSubscription?.onData(null);
    _frameSubscription?.cancel();
    _frameSubscription = null;
  }
}
