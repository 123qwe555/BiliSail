import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'apple_motion.dart';

/// How far the picture travels and how much it grows during a reveal.
typedef FullScreenFlight = ({double scale, Offset travel});

/// Grows the fullscreen player out of the inline player's slot, and back into
/// it on the way out.
///
/// The player surface is a native texture that can only exist once, so a
/// shared-element flight between two widgets is impossible: the inline surface
/// is unmounted and the fullscreen surface mounts. What makes the swap
/// invisible is that the incoming surface starts exactly where the outgoing one
/// was, which is what [FullScreenFlight] computes: the *picture* inside the
/// slot, mapped onto the *picture* inside the viewport, so the first frame of
/// the fullscreen route shows the same pixels in the same place.
///
/// The flight is applied as a composited paint transform instead of a
/// [Transform] widget. Layout, hit testing and geometry reporting stay at the
/// final size for the whole flight: the player never re-negotiates its surface
/// size with the native decoder, and nothing above it (controls, danmaku,
/// gestures) sees a moving target. Only the composition of the picture moves.
///
/// No platform check is involved anywhere: the same widget runs on Android,
/// iOS, Windows and the web renderer, and it re-derives its geometry from the
/// layout on every build, so window resizes, split-screen and orientation
/// changes are handled by construction.
final class FullScreenReveal extends StatefulWidget {
  const FullScreenReveal({
    super.key,
    required this.child,
    this.from,
    this.videoSize,
    this.duration = const Duration(milliseconds: 300),
  });

  final Widget child;

  /// The inline player's rectangle in global coordinates before entering
  /// fullscreen. When null the child is returned untouched: displays that
  /// rotate into fullscreen are already animated by the operating system, and
  /// a second motion on top of a rotation reads as a glitch.
  final Rect? from;

  /// The picture's intrinsic size, so the flight follows the picture rather
  /// than the letterbox around it.
  final Size? videoSize;

  final Duration duration;

  /// The picture's rectangle inside [box] under `BoxFit.contain`, which is how
  /// the player lays its own surface out.
  static Size pictureSize(Size video, Size box) {
    if (video.width <= 0 ||
        video.height <= 0 ||
        box.width <= 0 ||
        box.height <= 0 ||
        !box.width.isFinite ||
        !box.height.isFinite) {
      return box;
    }
    final ratio = video.width / video.height;
    return ratio > box.width / box.height
        ? Size(box.width, box.width / ratio)
        : Size(box.height * ratio, box.height);
  }

  /// Maps the picture's final rectangle onto the slot it is leaving.
  ///
  /// [scale] is the growth left to perform (1 means "already full size") and
  /// [travel] is how far the centre still has to move. Both are expressed
  /// against the fullscreen box, so the first frame lands the picture exactly
  /// on [from].
  static FullScreenFlight resolve({
    required Rect from,
    required Size video,
    required Size box,
  }) {
    final screen = pictureSize(video, box);
    final slot = pictureSize(video, from.size);
    final scale = screen.width <= 0
        ? 1.0
        : (slot.width / screen.width).clamp(0.08, 1.0);
    return (scale: scale, travel: from.center - (Offset.zero & box).center);
  }

  @override
  State<FullScreenReveal> createState() => FullScreenRevealState();
}

final class FullScreenRevealState extends State<FullScreenReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    // Without a source rectangle there is nothing to animate, so the flight is
    // born finished and the child is painted at its final geometry.
    value: widget.from == null ? 1 : 0,
  );

  late final CurvedAnimation _flight = CurvedAnimation(
    parent: _controller,
    curve: AppleMotion.entrance,
  );

  bool get _animated => widget.from != null;

  @override
  void initState() {
    super.initState();
    if (_animated) _controller.forward();
  }

  @override
  void dispose() {
    _flight.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.from;
    if (from == null) return widget.child;
    final video = widget.videoSize ?? const Size(16, 9);
    // The fullscreen route fills the view, so the viewport is the destination.
    // Reading it from the media query rather than from a [LayoutBuilder] keeps
    // the child in the build phase, where the player surface expects to mount.
    final box = MediaQuery.maybeSizeOf(context) ?? Size.zero;
    if (box.width <= 0 || box.height <= 0) return widget.child;
    final flight = FullScreenReveal.resolve(from: from, video: video, box: box);
    return AnimatedBuilder(
      animation: _flight,
      child: widget.child,
      builder: (context, child) {
        final eased = _flight.value;
        return _FlightPaint(
          scale: 1 + (flight.scale - 1) * (1 - eased),
          travel: flight.travel * (1 - eased),
          child: child,
        );
      },
    );
  }
}

/// Paints its child under a scale/translate without touching layout.
final class _FlightPaint extends SingleChildRenderObjectWidget {
  const _FlightPaint({required this.scale, required this.travel, super.child});

  final double scale;
  final Offset travel;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFlightPaint(scale, travel);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFlightPaint renderObject,
  ) => renderObject.update(scale: scale, travel: travel);
}

final class _RenderFlightPaint extends RenderProxyBox {
  _RenderFlightPaint(this._scale, this._travel);

  double _scale;
  Offset _travel;

  void update({required double scale, required Offset travel}) {
    if (scale == _scale && travel == _travel) return;
    _scale = scale;
    _travel = travel;
    markNeedsPaint();
  }

  /// Deliberately not overridden: layout, hit testing and [localToGlobal] all
  /// report the final geometry, so the flight cannot move anything except the
  /// pixels it paints.
  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1 && _travel == Offset.zero) {
      super.paint(context, offset);
      return;
    }
    final centre = size.center(Offset.zero);
    final matrix = Matrix4.identity()
      ..setEntry(0, 0, _scale)
      ..setEntry(1, 1, _scale)
      ..setEntry(0, 3, centre.dx + _travel.dx - centre.dx * _scale)
      ..setEntry(1, 3, centre.dy + _travel.dy - centre.dy * _scale);
    context.pushTransform(
      needsCompositing,
      offset,
      matrix,
      (context, offset) => child.paint(context, offset),
    );
  }
}

/// Lands the inline player after fullscreen closes: the picture is painted at
/// fullscreen size for one frame and collapses into its slot from there.
///
/// The reverse of [FullScreenReveal] cannot live inside the fullscreen route,
/// because finishing it there would mean holding navigation back for the length
/// of the animation — the route would stay pushed, the orientation and the
/// system bars would stay unrestored, and the browsing layout underneath would
/// be a lie for a quarter of a second. Landing on the incoming surface instead
/// keeps every piece of state exactly where it belongs and still shows one
/// continuous motion.
final class FullScreenLanding extends StatefulWidget {
  const FullScreenLanding({
    super.key,
    required this.child,
    required this.startScale,
    required this.startTravel,
    this.generation = 1,
    this.duration = const Duration(milliseconds: 240),
  });

  final Widget child;

  /// Bumped by the caller for every new landing. The wrapper deliberately
  /// outlives the animation — replacing it with the bare child would rebuild
  /// the player surface — so the flight is restarted by generation instead.
  final int generation;

  /// Appearance of the frame that just left the screen. [FullScreenReveal]'s
  /// flight inverted: the box the child fills is the slot, so the picture needs
  /// dividing up rather than down.
  final double startScale;
  final Offset startTravel;

  final Duration duration;

  /// The inverse of a resolved reveal, for callers that only kept the flight.
  static (double scale, Offset travel) invert(FullScreenFlight flight) =>
      (1 / flight.scale, -flight.travel / flight.scale);

  @override
  State<FullScreenLanding> createState() => _FullScreenLandingState();
}

final class _FullScreenLandingState extends State<FullScreenLanding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final CurvedAnimation _flight = CurvedAnimation(
    parent: _controller,
    curve: AppleMotion.standardCurve,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(FullScreenLanding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flight.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _flight,
    child: widget.child,
    builder: (context, child) {
      final eased = _flight.value;
      return _FlightPaint(
        scale: widget.startScale + (1 - widget.startScale) * eased,
        travel: widget.startTravel * (1 - eased),
        child: child,
      );
    },
  );
}
