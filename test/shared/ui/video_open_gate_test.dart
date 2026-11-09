import 'dart:async';

import 'package:bilisail/shared/ui/video_open_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gate decides when a video is allowed to start. Every case below is a way
/// the animation can fail to report back, and none of them may leave playback
/// waiting forever.
const _card = Rect.fromLTWH(40, 420, 320, 180);
const _cover = 'https://i0.hdslb.com/bfs/archive/cover.jpg';

void main() {
  setUp(VideoOpenGate.abandon);
  tearDown(VideoOpenGate.abandon);

  test('an armed flight holds playback until it lands', () async {
    expect(VideoOpenGate.busy, isFalse);

    VideoOpenGate.beginCardFlight();
    var settled = false;
    unawaited(VideoOpenGate.settled.then((_) => settled = true));
    expect(VideoOpenGate.busy, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(settled, isFalse, reason: 'must not resolve before the landing');

    VideoOpenGate.releaseCardFlight();
    await Future<void>.delayed(Duration.zero);
    expect(VideoOpenGate.busy, isFalse);
    expect(settled, isTrue);
  });

  test('a card flight that becomes fullscreen waits for both', () async {
    VideoOpenGate.beginCardFlight();
    VideoOpenGate.holdFullScreenFlight();

    VideoOpenGate.releaseCardFlight();
    var settled = false;
    unawaited(VideoOpenGate.settled.then((_) => settled = true));
    await Future<void>.delayed(Duration.zero);
    expect(settled, isFalse, reason: 'the fullscreen takeover still runs');

    VideoOpenGate.releaseFullScreenFlight();
    await Future<void>.delayed(Duration.zero);
    expect(settled, isTrue);
  });

  test('a release that never arrives cannot stall playback', () async {
    VideoOpenGate.beginCardFlight();
    var settled = false;
    unawaited(VideoOpenGate.settled.then((_) => settled = true));

    await Future<void>.delayed(
      VideoOpenGate.watchdog + const Duration(milliseconds: 50),
    );
    expect(settled, isTrue);
    expect(VideoOpenGate.busy, isFalse);
  });

  test(
    'a second tap releases the first gate instead of orphaning it',
    () async {
      VideoOpenGate.beginCardFlight();
      final first = VideoOpenGate.settled;
      var firstDone = false;
      unawaited(first.then((_) => firstDone = true));

      VideoOpenGate.beginCardFlight();
      await Future<void>.delayed(Duration.zero);
      expect(firstDone, isTrue, reason: 'the abandoned page must not hang');
      expect(VideoOpenGate.busy, isTrue, reason: 'the new flight still holds');
    },
  );

  test('abandon drops every hold', () async {
    VideoOpenGate.beginCardFlight();
    VideoOpenGate.holdFullScreenFlight();
    VideoOpenGate.abandon();
    expect(VideoOpenGate.busy, isFalse);
    await VideoOpenGate.settled;
  });

  testWidgets('the card flight releases the gate when it lands', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: VideoOpenPop(child: SizedBox.expand())),
    );
    await tester.pump();

    VideoOpenOrigin.record(_card, _cover);
    expect(VideoOpenGate.busy, isTrue);

    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    // The flying cover loads over HTTP, which the test binding rejects.
    while (tester.takeException() != null) {}
    expect(VideoOpenGate.busy, isFalse);
    await VideoOpenOrigin.take();
  });

  testWidgets('a page that goes away mid-flight releases the gate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: VideoOpenPop(child: SizedBox.expand())),
    );
    await tester.pump();

    VideoOpenOrigin.record(_card, _cover);
    await tester.pump(const Duration(milliseconds: 16));
    expect(VideoOpenGate.busy, isTrue);

    // The page is replaced before the flight can land.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));
    await tester.pump();
    // The flying cover loads over HTTP, which the test binding rejects.
    while (tester.takeException() != null) {}
    expect(VideoOpenGate.busy, isFalse);
    await VideoOpenOrigin.take();
  });
}
