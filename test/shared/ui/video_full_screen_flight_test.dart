import 'package:bilisail/shared/ui/video_open_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fullscreen flights live in the root overlay, so these tests only check
/// that they are dispatched, painted and then taken back down. The visual
/// geometry is verified on a device: widget tests cannot paint a real cover.
const _cover = 'https://i0.hdslb.com/bfs/archive/cover.jpg';
const _card = Rect.fromLTWH(24, 640, 320, 180);

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (inner) {
          context = inner;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );
  return context;
}

/// Runs the flight to completion: past the tail of the transition the entry
/// must be gone again, otherwise the overlay would keep a blurred layer alive
/// for the rest of the session.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

void main() {
  testWidgets('open flight paints a veil and releases the overlay', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    expect(find.byType(BackdropFilter), findsNothing);

    VideoOpenOrigin.playFullScreenOpen(context, from: _card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(BackdropFilter), findsOneWidget);
    // The travelling card is blank: no artwork is painted on the way out.
    expect(find.byType(Image), findsNothing);

    await _settle(tester);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('open flight ignores an empty source rectangle', (tester) async {
    final context = await _pumpHost(tester);
    VideoOpenOrigin.playFullScreenOpen(context, from: Rect.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('close flight collapses back and releases the overlay', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    const viewport = Rect.fromLTWH(0, 0, 800, 600);
    VideoOpenOrigin.playFullScreenClose(
      context,
      from: viewport,
      to: _card,
      cover: _cover,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(BackdropFilter), findsOneWidget);

    await _settle(tester);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('close flight ignores a cover it cannot draw', (tester) async {
    final context = await _pumpHost(tester);
    const viewport = Rect.fromLTWH(0, 0, 800, 600);
    VideoOpenOrigin.playFullScreenClose(
      context,
      from: viewport,
      to: _card,
      cover: '',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
