import 'dart:typed_data';

import 'package:flutter_progressive_image/src/progressive_converter.dart';
import 'package:flutter_test/flutter_test.dart';

final sample = Uint8List.fromList(<int>[
  0xff,
  0xd8,
  0xff,
  0xe2,
  0x0c,
  0x58,
  0x49,
  0x43,
  0x43,
  0x5f,
  0xff,
  0xda,
  0x23,
  0x51,
  0xff,
  0xff,
  0xda,
  0xe2,
  0x0c,
  0x58,
  0x49,
  0x43,
  0x43,
  0x5f,
  0xff,
  0xd9
]);

class _TestSink extends Sink<Uint8List> {
  @override
  void add(Uint8List data) {}

  @override
  void close() {}
}

void main() {
  test('detectMagicFlag test', () {
    var jpegFormatFlag = <int>[0xFF, 0xD8];
    var jpegSosFlag = <int>[0xFF, 0xDA];
    var sink = ProgressiveConverterSink(_TestSink());

    // 检测文件起始格式
    var (state, detects) =
    sink.detectMagicFlag(jpegFormatFlag, sample, detectAll: false);
    expect(state, equals(0));
    expect(detects, equals(const [0]));

    // 模拟多chunk
    (state, detects) = sink.detectMagicFlag(
      jpegFormatFlag,
      Uint8List.fromList(<int>[0xff]),
      detectAll: false,
    );
    expect(state, equals(1));
    expect(detects, null);

    (state, detects) = sink.detectMagicFlag(
      jpegFormatFlag,
      Uint8List.fromList(<int>[0xd8, 0xff]),
      state: state,
      detectAll: false,
    );
    expect(state, equals(0));
    expect(detects, equals(const [0]));

    // 检测SOS
    (state, detects) = sink.detectMagicFlag(jpegSosFlag, sample);
    expect(state, equals(0));
    expect(detects, equals(const [10, 15]));

    (state, detects) = sink.detectMagicFlag([0xFF, 0x88, 0x99], sample);
    expect(state, equals(0));
    expect(detects, null);
  });
}