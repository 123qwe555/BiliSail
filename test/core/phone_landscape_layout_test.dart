import 'dart:ui' show Size;

import 'package:bilisail/core/platform/window_size_policy.dart';
import 'package:bilisail/shared/ui/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowSizePolicy', () {
    test('a rotated phone is wide-but-short, not a tablet', () {
      const portrait = Size(360, 800);
      const landscape = Size(800, 360);
      expect(WindowSizePolicy.phoneLandscape(portrait), isFalse);
      expect(WindowSizePolicy.phoneLandscape(landscape), isTrue);
    });

    test('tablets, short desktop windows and foldables are excluded', () {
      expect(WindowSizePolicy.phoneLandscape(const Size(1024, 768)), isFalse);
      // Height above the phone-landscape ceiling.
      expect(WindowSizePolicy.phoneLandscape(const Size(900, 500)), isFalse);
      // Shortest side no longer phone-class.
      expect(WindowSizePolicy.phoneLandscape(const Size(1000, 620)), isFalse);
      expect(
        WindowSizePolicy.phoneLandscape(const Size(double.infinity, 360)),
        isFalse,
      );
    });

    test('compactExtent keeps compact layouts on a landscape phone', () {
      const viewport = Size(800, 360);
      expect(
        WindowSizePolicy.compactExtent(
          extent: 760,
          viewport: viewport,
          mobile: true,
        ),
        isTrue,
      );
      // The same window on desktop keeps its previous width-only decision.
      expect(
        WindowSizePolicy.compactExtent(
          extent: 760,
          viewport: viewport,
          mobile: false,
        ),
        isFalse,
      );
      expect(
        WindowSizePolicy.compactViewport(viewport: viewport, mobile: true),
        isTrue,
      );
    });
  });

  group('AppLayout', () {
    Widget host({required TargetPlatform platform, required Size size}) =>
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Theme(
            data: ThemeData(platform: platform),
            child: const SizedBox(key: Key('probe')),
          ),
        );

    BuildContext probe(WidgetTester tester) =>
        tester.element(find.byKey(const Key('probe')));

    testWidgets('portrait phone keeps the compact baseline', (tester) async {
      await tester.pumpWidget(
        host(platform: TargetPlatform.android, size: const Size(360, 800)),
      );
      final context = probe(tester);
      expect(AppLayout.phoneLandscapeOf(context), isFalse);
      expect(AppLayout.compactOf(context), isTrue);
      expect(AppLayout.shortOf(context), isFalse);
      expect(AppLayout.playbackSideBySideOf(context, extent: 360), isFalse);
    });

    testWidgets('landscape phone switches playback to side by side', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(platform: TargetPlatform.android, size: const Size(800, 360)),
      );
      final context = probe(tester);
      expect(AppLayout.phoneLandscapeOf(context), isTrue);
      expect(AppLayout.compactOf(context, extent: 760), isTrue);
      expect(AppLayout.shortOf(context), isTrue);
      expect(AppLayout.playbackSideBySideOf(context, extent: 760), isTrue);
      expect(AppLayout.compactNavigationOf(context), isTrue);
    });

    testWidgets('landscape tablet also puts the info column beside the player', (
      tester,
    ) async {
      // A tablet in landscape (e.g. ~921x576dp) is taller than the phone
      // landscape ceiling but still cannot stack a player + info tabs, so it
      // should use the side-by-side layout and keep the compact baseline.
      await tester.pumpWidget(
        host(platform: TargetPlatform.android, size: const Size(921, 576)),
      );
      final context = probe(tester);
      expect(AppLayout.phoneLandscapeOf(context), isFalse);
      // Tablet landscape stays "expanded" for toolbars/navigation (it is not a
      // short phone viewport), but it still gets the side-by-side player.
      expect(AppLayout.compactOf(context), isFalse);
      expect(AppLayout.playbackSideBySideOf(context, extent: 921), isTrue);
    });

    testWidgets('a short desktop window is not reclassified', (tester) async {
      await tester.pumpWidget(
        host(platform: TargetPlatform.windows, size: const Size(800, 360)),
      );
      final context = probe(tester);
      expect(AppLayout.phoneLandscapeOf(context), isFalse);
      expect(AppLayout.compactOf(context, extent: 760), isFalse);
      expect(AppLayout.shortOf(context), isTrue);
      expect(AppLayout.playbackSideBySideOf(context, extent: 760), isFalse);
    });
  });
}
