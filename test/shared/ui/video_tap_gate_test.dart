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
    expect(VideoTapGate.shouldOpen('a'), isTrue);
    expect(VideoTapGate.shouldOpen('a'), isFalse);
    expect(VideoTapGate.shouldOpen('a'), isFalse);
  });

  test('a different card is not blocked by the previous one', () {
    expect(VideoTapGate.shouldOpen('a'), isTrue);
    expect(VideoTapGate.shouldOpen('b'), isTrue);
    expect(VideoTapGate.shouldOpen('b'), isFalse);
    expect(VideoTapGate.shouldOpen('a'), isTrue);
  });

  test('the window reopens after a reset', () {
    expect(VideoTapGate.shouldOpen('a'), isTrue);
    expect(VideoTapGate.shouldOpen('a'), isFalse);
    VideoTapGate.reset();
    expect(VideoTapGate.shouldOpen('a'), isTrue);
  });

  test('a disabled gate lets every tap through', () {
    VideoTapGate.enabled = false;
    expect(VideoTapGate.shouldOpen('a'), isTrue);
    expect(VideoTapGate.shouldOpen('a'), isTrue);
  });
}
