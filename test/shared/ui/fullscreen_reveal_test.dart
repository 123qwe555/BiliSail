import 'package:bilisail/shared/ui/fullscreen_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The reveal maps the picture onto the slot it is leaving, and does it as a
/// paint transform only. Both halves of that contract are pinned here.
const _video = Size(1920, 1080);
const _fill = ValueKey('fill');

Future<void> _pump(WidgetTester tester, Size surface, {Rect? from}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: FullScreenReveal(
        from: from,
        videoSize: _video,
        child: const SizedBox.expand(
          key: _fill,
          child: ColoredBox(color: Color(0xFF102030)),
        ),
      ),
    ),
  );
}

void main() {
  group('geometry', () {
    test('a 16:9 picture in a square viewport keeps 450 of 800 height', () {
      expect(
        FullScreenReveal.pictureSize(_video, const Size(800, 800)),
        const Size(800, 450),
      );
    });

    test('a portrait viewport letters the picture across the width', () {
      expect(
        FullScreenReveal.pictureSize(_video, const Size(400, 900)),
        const Size(400, 225),
      );
    });

    test('the flight starts on the slot and ends at full size', () {
      final flight = FullScreenReveal.resolve(
        from: const Rect.fromLTWH(100, 100, 200, 112.5),
        video: _video,
        box: const Size(800, 800),
      );
      // The slot is a quarter of the viewport width.
      expect(flight.scale, closeTo(0.25, 0.0001));
      // The centre still has to travel from the slot to the middle of the box.
      expect(flight.travel, const Offset(-200, -243.75));
    });

    test('a slot that already spans the width only travels', () {
      final flight = FullScreenReveal.resolve(
        from: const Rect.fromLTWH(0, 0, 400, 225),
        video: _video,
        box: const Size(400, 900),
      );
      expect(flight.scale, closeTo(1, 0.0001));
      expect(flight.travel, const Offset(0, -337.5));
    });
  });

  testWidgets('without an origin the picture is painted in place', (
    tester,
  ) async {
    await _pump(tester, const Size(800, 800));
    expect(
      tester.getRect(find.byKey(_fill)),
      const Rect.fromLTWH(0, 0, 800, 800),
    );
  });

  testWidgets('the flight never moves the layout', (tester) async {
    const from = Rect.fromLTWH(100, 100, 200, 112.5);
    await _pump(tester, const Size(800, 800), from: from);

    // Only paint is animated: the geometry stays at the final size from the
    // first frame, which is what keeps the native surface from resizing and
    // the controls from having to chase a moving target.
    expect(
      tester.getRect(find.byKey(_fill)),
      const Rect.fromLTWH(0, 0, 800, 800),
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(
      tester.getRect(find.byKey(_fill)),
      const Rect.fromLTWH(0, 0, 800, 800),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getRect(find.byKey(_fill)),
      const Rect.fromLTWH(0, 0, 800, 800),
    );
  });

  testWidgets('a landing starts from the inverted flight', (tester) async {
    const flight = (scale: 0.25, travel: Offset(-200, -243.75));
    final (scale, travel) = FullScreenLanding.invert(flight);
    // The slot box has to be blown up by the same factor the reveal shrank by,
    // and pushed the opposite way.
    expect(scale, closeTo(4, 0.0001));
    expect(travel, const Offset(800, 975));

    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: FullScreenLanding(
          startScale: 4,
          startTravel: Offset(800, 975),
          child: SizedBox.expand(
            key: _fill,
            child: ColoredBox(color: Color(0xFF102030)),
          ),
        ),
      ),
    );
    // Landing is a paint effect as well: the surface keeps its slot geometry
    // from the first frame, so the player never re-negotiates its size.
    expect(
      tester.getRect(find.byKey(_fill)),
      const Rect.fromLTWH(0, 0, 800, 600),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getRect(find.byKey(_fill)),
      const Rect.fromLTWH(0, 0, 800, 600),
    );
  });
}
