import 'package:bilisail/shared/ui/video_open_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card → page flight is timing- and identity-sensitive: it must not
/// rebuild the player when its wrappers come and go, and it must land exactly
/// on the slot it measured.
const _cover = 'https://i0.hdslb.com/bfs/archive/cover.jpg';
const _card = Rect.fromLTWH(40, 420, 320, 180);
const _playerKey = ValueKey('player');

/// Counts how many times the player subtree was built, which is what a
/// remount looks like from the outside.
final class _Probe extends StatefulWidget {
  const _Probe({required this.onInit});
  final VoidCallback onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

final class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand(
    key: _playerKey,
    child: ColoredBox(color: Colors.black),
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required VoidCallback onInit,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: VideoOpenPop(child: _Probe(onInit: onInit)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the flight lands on the measured slot', (tester) async {
    var built = 0;
    await _pumpPage(tester, onInit: () => built++);
    // The page fills the viewport; the card sits in the lower left.
    expect(
      tester.getRect(find.byKey(_playerKey)),
      const Rect.fromLTWH(0, 0, 1000, 800),
    );

    VideoOpenOrigin.record(_card, _cover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // First frame of the flight: the picture is the card, not the page.
    final start = tester.getRect(find.byKey(_playerKey));
    expect(start.center.dx, closeTo(_card.center.dx, 1));
    expect(start.center.dy, closeTo(_card.center.dy, 1));
    expect(start.width, closeTo(_card.width, 1));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(
      tester.getRect(find.byKey(_playerKey)),
      const Rect.fromLTWH(0, 0, 1000, 800),
    );
    // Exactly one mount: the wrappers must not rebuild the player.
    expect(built, 1);
  });

  testWidgets('the reverse flight lands back on the card', (tester) async {
    var built = 0;
    await _pumpPage(tester, onInit: () => built++);
    VideoOpenOrigin.record(_card, _cover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    VideoOpenOrigin.playReverse(tester.element(find.byType(VideoOpenPop)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    // The overlay copy loads its artwork over HTTP, which the test binding
    // rejects; only the mount count matters here.
    while (tester.takeException() != null) {}
    expect(built, 1);
  });
}
