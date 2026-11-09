import 'package:bilisail/shared/ui/video_tap_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    VideoTapGate.enabled = true;
    VideoTapGate.reset();
  });

  tearDown(() {
    VideoTapGate.enabled = false;
    VideoTapGate.reset();
  });

  test('the first tap opens and an immediate repeat is swallowed', () {
    expect(VideoTapGate.shouldOpen(), isTrue);
    expect(VideoTapGate.shouldOpen(), isFalse);
    expect(VideoTapGate.shouldOpen(), isFalse);
  });

  test('the window reopens after a reset', () {
    expect(VideoTapGate.shouldOpen(), isTrue);
    expect(VideoTapGate.shouldOpen(), isFalse);
    VideoTapGate.reset();
    expect(VideoTapGate.shouldOpen(), isTrue);
  });

  test('a disabled gate lets every tap through', () {
    VideoTapGate.enabled = false;
    expect(VideoTapGate.shouldOpen(), isTrue);
    expect(VideoTapGate.shouldOpen(), isTrue);
  });
}
