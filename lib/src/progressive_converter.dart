import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

const _jpegFileFormat = <int>[0xFF, 0xD8, 0xFF];
const _jpegSOS = <int>[0xFF, 0xDA];
const _jpegEnd = <int>[0xFF, 0xD9];

typedef DetectResult = (int state, List<int>? detectAt);

class ProgressiveConverter extends Converter<List<int>, Uint8List> {
  const ProgressiveConverter();

  @override
  Uint8List convert(List<int> input) {
    return Uint8List.fromList(input);
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<Uint8List> sink) {
    return ProgressiveConverterSink(sink);
  }
}

class ProgressiveConverterSink extends ByteConversionSinkBase {
  final Sink<Uint8List> _target;
  bool? _isJpeg;
  List<List<int>>? _chunks = <List<int>>[];
  int _contentLength = 0;
  int _sosState = 0;
  int _sosCounter = 0;

  ProgressiveConverterSink(this._target);

  @override
  void add(List<int> chunk) {
    _chunks!.add(chunk);
    _contentLength += chunk.length;

    // detect jpeg
    if (_isJpeg == null) {
      var (_, detects) = detectMagicFlag(
        _jpegFileFormat,
        chunk,
        detectAll: false,
      );
      _isJpeg = detects != null;
    }

    if (_isJpeg != true) return;

    // jpeg progressive frame
    var (sosState, detects) = detectMagicFlag(
      _jpegSOS,
      chunk,
      state: _sosState,
    );
    _sosState = sosState;
    if (detects?.isNotEmpty == true) {
      for (var offset in detects!) {
        if (_sosCounter > 0) {
          _emit(_contentLength - (chunk.length - offset), true);
        }
        _sosCounter++;
      }
    }
  }

  @override
  void close() {
    _emit(_contentLength, false);
    _chunks = null;
    _target.close();
  }

  void _emit(int len, bool appendEnd) {
    if (_chunks?.isNotEmpty != true) return;

    final bytes = Uint8List(appendEnd ? len + 2 : len);
    int offset = 0, remainder = 0, chunkLen = 0;
    for (final List<int> chunk in _chunks!) {
      remainder = len - offset;
      if (remainder > 1) {
        chunkLen = min(remainder, chunk.length);
        bytes.setRange(offset, offset + chunkLen, chunk);
        offset += chunkLen;
      } else {
        break;
      }
    }
    if (appendEnd) {
      bytes.setRange(offset, offset + 2, _jpegEnd);
    }
    _target.add(bytes);
  }

  @visibleForTesting
  DetectResult detectMagicFlag(
    List<int> flag,
    List<int> source, {
    int state = 0,
    bool detectAll = true,
  }) {
    assert(state <= flag.length - 1);

    List<int>? detects;
    late int fLen, remaind;

    loop:
    for (int i = 0; i < source.length; i++, state = 0) {
      remaind = source.length - i;
      fLen = remaind >= flag.length ? flag.length : remaind;
      for (int fIndex = 0; fIndex < fLen; fIndex++) {
        if (source[i + fIndex] != flag[fIndex + state]) {
          fLen = 0;
          break;
        }

        if (fIndex + state == flag.length - 1) {
          detects ??= <int>[];
          detects.add(i);

          if (detectAll) {
            continue loop;
          } else {
            break loop;
          }
        }
      }
    }
    return (fLen % flag.length, detects);
  }
}
