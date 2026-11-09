import 'dart:async';
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

import '../../core/presentation/public_image_variant.dart';
import 'apple_design.dart';
import 'apple_motion.dart';
import 'app_network_image.dart';

const List<int> _coverWidthBuckets = [96, 160, 240, 320, 480, 640, 960, 1280];

/// Flight timings.
///
/// Fixed durations rather than fixed frame counts are what make the motion
/// frame-rate independent: the controllers are time based, so a 120 Hz panel
/// simply samples the same curve more often. Opening is deliberately the longer
/// of the two — the card is being lifted out of a grid — while closing is a
/// short put-back, which is how the iPad client feels.
const Duration _openDuration = Duration(milliseconds: 460);
const Duration _closeDuration = Duration(milliseconds: 320);

/// The reveal curve: a decisive lift that spends most of its time settling.
///
/// Tuned against the iPad client rather than against a generic ease-out. There
/// is no overshoot on purpose — a picture that bounces past its slot shows its
/// own edges for a frame, and video has nothing to hide them with.
const Curve _openCurve = Cubic(0.19, 0.78, 0.16, 1.0);

/// The dismissal curve: softer at the start, so the picture is *put back*
/// rather than snapped away.
const Curve _closeCurve = Cubic(0.36, 0.04, 0.24, 1.0);

/// Scrim tracks. The blur peaks early and leaves before the dim does, which is
/// what keeps the destination readable in the last third of the flight instead
/// of popping into focus out of grey.
const double _openBlurRampIn = 0.10;
const double _openBlurFall = 0.52;
const double _openDimRampIn = 0.08;
const double _openDimFall = 0.68;
const double _openDim = 0.30;

const double _closeBlurRampIn = 0.06;
const double _closeBlurFall = 0.38;
const double _closeDimRampIn = 0.05;
const double _closeDimFall = 0.55;
const double _closeDim = 0.22;

double _smoothstep(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Eased 0..1 ramp across [start]..[end] of a flight.
double _span(double progress, double start, double end) {
  if (progress <= start) return 0;
  if (progress >= end) return 1;
  return Curves.easeInOut.transform((progress - start) / (end - start));
}

/// Eased 0..1 ramp across the last [start]..1 window — used for the corner
/// radius, which squares off only as the picture lands.
double _tail(double progress, double start) => _span(progress, start, 1);

/// Blur strength envelope for a flight, in 0..1.
///
/// The veil ramps in almost instantly, holds while the card travels, then
/// dissolves so the destination page ends up perfectly sharp.
double _veilEnvelope(
  double progress, {
  required double rampIn,
  required double fallStart,
}) {
  if (progress <= 0) return 0;
  if (progress < rampIn) return _smoothstep(progress / rampIn);
  if (progress < fallStart) return 1;
  return 1 - _smoothstep((progress - fallStart) / (1 - fallStart));
}

/// The card and the flight must request the same CDN bucket, otherwise the
/// flying copy misses the decoded image the card already cached.
int _coverBucket(double logicalWidth, double devicePixelRatio) {
  final physicalWidth = logicalWidth * devicePixelRatio;
  return _coverWidthBuckets.firstWhere(
    (candidate) => candidate >= physicalWidth,
    orElse: () => _coverWidthBuckets.last,
  );
}

String _thumbnailUrl(String cover, int bucket) {
  final source = Uri.tryParse(cover);
  return source == null
      ? cover
      : publicImageThumbnail(source, width: bucket).toString();
}

/// A frosted-glass veil drawn behind a flying card: it blurs whatever is
/// painted underneath (the page that is leaving) and lays a soft dim over it,
/// which is what makes the iOS-like spring read as a depth transition instead
/// of a plain resize.
///
/// The blur radius is quantised and the resulting [ImageFilter] instances are
/// reused. Rebuilding a filter every frame would hand the engine a brand new
/// blur pipeline 120 times a second, which is the single most expensive thing
/// this transition can do on a high-refresh display.
final class _BlurVeil extends StatelessWidget {
  const _BlurVeil({required this.sigma, required this.dim});

  final double sigma;
  final double dim;

  static final Map<int, ImageFilter> _filters = <int, ImageFilter>{};

  static ImageFilter _filter(double sigma) {
    // Half-point steps: visually indistinguishable, but they collapse a
    // continuously changing radius into a handful of cached filters.
    final key = (sigma * 2).round();
    return _filters.putIfAbsent(
      key,
      () => ImageFilter.blur(sigmaX: key / 2, sigmaY: key / 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (sigma > 0.05)
          BackdropFilter(
            filter: _filter(sigma),
            child: const SizedBox.expand(),
          ),
        if (dim > 0.002) ColoredBox(color: Colors.black.withValues(alpha: dim)),
      ],
    );
  }
}

/// The cover artwork used by both flights.
///
/// Wrapped in a [RepaintBoundary] so that scaling and moving the card only
/// updates a transform matrix instead of re-rasterising the decoded image.
final class _CoverLayer extends StatelessWidget {
  const _CoverLayer({required this.url, required this.cacheWidth});

  final String url;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(
      color: Colors.black,
      child: AppNetworkImage(
        url: url,
        cacheWidth: cacheWidth,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      ),
    ),
  );
}

/// Coordinates "animate first, then play".
///
/// Opening a video resolves media the moment the page exists, but the picture
/// must not start moving before the card has landed: a video already playing
/// underneath the cover is exactly the thing this transition is supposed to
/// hide. The gate is the single place that knows whether a flight is still in
/// the air, so nothing has to guess from the animation's side.
///
/// Two holds exist because a card tap can become a fullscreen takeover: the
/// card flight hands over to the fullscreen flight, and playback waits for
/// both. A watchdog drops every hold after [watchdog] so a release that never
/// arrives — a page torn down mid-flight, an overlay removed by a route
/// teardown — can never leave the video paused for good.
abstract final class VideoOpenGate {
  /// How long a hold may survive without being released.
  static const Duration watchdog = Duration(milliseconds: 1500);

  static final Object _cardFlight = Object();
  static final Object _fullScreenFlight = Object();
  static final Set<Object> _holds = <Object>{};
  static Completer<void>? _settled;
  static Timer? _watchdog;

  /// True while at least one flight still owes the screen a landing.
  static bool get busy => _holds.isNotEmpty;

  /// Completes when every outstanding flight has landed, been abandoned, or
  /// timed out. Never completes twice and never throws.
  ///
  /// The watchdog is armed here rather than when the flight starts: a timer is
  /// only worth paying for once somebody is actually waiting on it.
  static Future<void> get settled {
    final settled = _settled;
    if (settled == null) return Future<void>.value();
    _watchdog ??= Timer(watchdog, () {
      _holds.clear();
      _finish();
    });
    return settled.future;
  }

  /// Starts a new card flight. A second tap replaces the first one rather than
  /// queueing behind it, which is also why the holds are reset here.
  static void beginCardFlight() {
    _holds
      ..clear()
      ..add(_cardFlight);
    _renew();
  }

  /// A card flight that continues into fullscreen keeps playback waiting.
  static void holdFullScreenFlight() {
    if (_holds.isEmpty || _settled == null) {
      _renew();
    }
    _holds.add(_fullScreenFlight);
  }

  static void releaseCardFlight() => _release(_cardFlight);

  static void releaseFullScreenFlight() => _release(_fullScreenFlight);

  /// Drops every hold without a landing: the page that owned the flight is
  /// gone, so there is nothing left to wait for.
  static void abandon() {
    _holds.clear();
    _finish();
  }

  static void _release(Object hold) {
    final removed = _holds.remove(hold);
    if (!removed) return;
    if (_holds.isEmpty) _finish();
  }

  /// Replaces the pending gate with a fresh one, releasing anyone waiting on
  /// the old one: a second tap must not leave the first page's playback
  /// hanging on a future that will never complete.
  static void _renew() {
    final previous = _settled;
    _settled = Completer<void>();
    if (previous != null && !previous.isCompleted) previous.complete();
  }

  static void _finish() {
    _watchdog?.cancel();
    _watchdog = null;
    final settled = _settled;
    _settled = null;
    if (settled != null && !settled.isCompleted) settled.complete();
  }
}

/// Carries the tapped cover's on-screen rectangle to the playback page.
///
/// The workspace swaps pages with Offstage instead of pushing Navigator
/// routes, so Flutter's Hero cannot bridge a card and the player. A generation
/// counter is used instead of a one-shot value: the playback view may already
/// be mounted when a card is tapped, so the transition must react to changes
/// rather than relying on initState alone.
abstract final class VideoOpenOrigin {
  static final ValueNotifier<int> generation = ValueNotifier<int>(0);
  static ({Rect rect, String cover})? _pending;

  // Retained for the reverse (back) flight: the player's last measured slot
  // and the cover rectangle it came from.
  static Rect? playerRect;
  static Rect? lastCardRect;
  static String lastCover = '';

  static void record(Rect rect, String cover) {
    _pending = (rect: rect, cover: cover);
    lastCardRect = rect;
    lastCover = cover;
    VideoOpenGate.beginCardFlight();
    generation.value++;
  }

  static void reportPlayer(Rect rect) => playerRect = rect;

  /// The playback page first shows a "loading details" view, so the player may
  /// mount well after the tap. Keep the origin until it is actually consumed;
  /// every new tap simply overwrites it, so a stale rectangle can never be
  /// reused for a later navigation.
  static ({Rect rect, String cover})? take() {
    final pending = _pending;
    _pending = null;
    return pending;
  }

  /// Plays the open flight all the way to the viewport edges instead of the
  /// inline player slot.
  ///
  /// Owned by the root overlay rather than by a widget, because the inline
  /// player is replaced by the fullscreen route a frame or two later and would
  /// take the animation with it. The flight hands the screen over by fading out
  /// once the fullscreen surface has had time to paint its first frame.
  static void playFullScreenOpen(BuildContext context, {required Rect from}) {
    if (from.width <= 0 || from.height <= 0) return;
    VideoOpenGate.holdFullScreenFlight();
    _insert(context, (onDone) => _FullScreenExpand(from: from, onDone: onDone));
  }

  /// Plays the inverse of [playFullScreenOpen]: the fullscreen surface
  /// collapses back into the inline player slot.
  ///
  /// [from] is the fullscreen viewport measured before the route was popped;
  /// [to] is the slot the player occupies once the browsing layout is back.
  static void playFullScreenClose(
    BuildContext context, {
    required Rect from,
    required Rect to,
    required String cover,
  }) {
    if (cover.isEmpty || from.width <= 0 || to.width <= 0) return;
    _insert(
      context,
      (onDone) =>
          _ReverseFlight(from: from, to: to, cover: cover, onDone: onDone),
    );
  }

  static void _insert(
    BuildContext context,
    Widget Function(VoidCallback onDone) build,
  ) {
    final OverlayState overlay;
    try {
      overlay = Overlay.of(context, rootOverlay: true);
    } catch (_) {
      return;
    }
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => build(() {
        try {
          entry.remove();
        } catch (_) {
          // Already removed with the overlay during a teardown.
        }
      }),
    );
    overlay.insert(entry);
  }

  /// Plays the inverse of the open flight when leaving a video: the cover
  /// springs from the player's slot back into the card rectangle while the
  /// workspace swaps pages underneath the overlay.
  static void playReverse(BuildContext context) {
    final from = playerRect;
    final to = lastCardRect;
    final cover = lastCover;
    playerRect = null;
    lastCardRect = null;
    lastCover = '';
    if (from == null || to == null || cover.isEmpty) return;
    final OverlayState overlay;
    try {
      overlay = Overlay.of(context, rootOverlay: true);
    } catch (_) {
      return;
    }
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ReverseFlight(
        from: from,
        to: to,
        cover: cover,
        onDone: () {
          try {
            entry.remove();
          } catch (_) {
            // Already removed with the overlay during a teardown.
          }
        },
      ),
    );
    overlay.insert(entry);
  }
}

/// Expands the player from the tapped cover's rectangle into its final slot —
/// the iPad Bilibili "card pops open" reveal.
///
/// Both [Transform] and [ClipRRect] are paint-only, so the player's measured
/// layout never changes and media decoding keeps running throughout. The
/// children are built once and handed to [AnimatedBuilder] as its `child`, so
/// a frame only updates a matrix and a corner radius.
final class VideoOpenPop extends StatefulWidget {
  const VideoOpenPop({super.key, required this.child});

  final Widget child;

  @override
  State<VideoOpenPop> createState() => _VideoOpenPopState();
}

final class _VideoOpenPopState extends State<VideoOpenPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _openDuration,
  );
  late final CurvedAnimation _flight = CurvedAnimation(
    parent: _controller,
    curve: _openCurve,
  );

  /// Keeps the player's element alive when the flight wrappers are dropped.
  ///
  /// The wrappers are removed the moment the card lands, which reparents the
  /// player from inside a [Stack] to being the only child. Without a global
  /// key that is a rebuild, and a rebuilt player is a new native surface — the
  /// one flash this transition exists to avoid.
  final GlobalKey _playerKey = GlobalKey(debugLabel: 'video-open-pop-player');

  Rect? _from;
  Rect? _to;
  int _measureAttempts = 0;
  OverlayEntry? _veil;

  @override
  void initState() {
    super.initState();
    VideoOpenOrigin.generation.addListener(_onOrigin);
    // Drop the transform/clip wrappers the moment the flight settles: a player
    // that lives inside them keeps paying for a clip layer on every video
    // frame for the rest of the session.
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      // The card has landed: this is the moment playback may start.
      VideoOpenGate.releaseCardFlight();
      if (mounted && _from != null) {
        setState(() => _from = null);
      }
    });
    _onOrigin();
    // Report the player's slot even when the page was opened without a card
    // tap, so the reverse flight still has a starting rectangle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      // Opened without a card (deep link, retained page): no flight is coming,
      // so playback must not wait for one.
      if (_from == null) VideoOpenGate.releaseCardFlight();
    });
  }

  void _onOrigin() {
    if (!mounted) return;
    final origin = VideoOpenOrigin.take();
    if (origin == null) return;
    _removeVeil();
    _from = origin.rect;
    _to = null;
    _measureAttempts = 0;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      if (++_measureAttempts < 8) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      } else if (mounted && _from != null) {
        // No slot to fly into: drop the flight rather than holding playback
        // hostage to a page that never laid out.
        _removeVeil();
        VideoOpenGate.releaseCardFlight();
        setState(() => _from = null);
      }
      return;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.width <= 0 || rect.height <= 0) {
      if (++_measureAttempts < 8) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      }
      return;
    }
    VideoOpenOrigin.reportPlayer(rect);
    if (_to == rect) return;
    setState(() => _to = rect);
    if (_from == null || _controller.isAnimating) return;
    _startFlight(_from!, rect);
  }

  void _startFlight(Rect from, Rect to) {
    _controller.forward(from: 0);
    _startVeil(from, to);
  }

  /// The player, always wrapped in the same global key so it survives the
  /// wrappers coming and going around it.
  Widget get _keyedChild => KeyedSubtree(key: _playerKey, child: widget.child);

  /// Frosts the whole screen for the duration of the flight.
  ///
  /// Only the backdrop is drawn here: the thing that travels is the player
  /// itself, still black because playback is held until the card lands. The
  /// poster is deliberately left out — it belongs to the card, and flashing it
  /// full-bleed in between reads as a second, unrelated image.
  void _startVeil(Rect from, Rect to) {
    _removeVeil();
    final OverlayState overlay;
    try {
      overlay = Overlay.of(context, rootOverlay: true);
    } catch (_) {
      return;
    }
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _OpenVeil(
        from: from,
        to: to,
        onDone: () {
          if (identical(_veil, entry)) _veil = null;
          try {
            entry.remove();
          } catch (_) {
            // Already removed with the overlay during a teardown.
          }
        },
      ),
    );
    _veil = entry;
    overlay.insert(entry);
  }

  void _removeVeil() {
    final veil = _veil;
    _veil = null;
    if (veil == null) return;
    try {
      veil.remove();
    } catch (_) {
      // Ignore double removals.
    }
  }

  @override
  void dispose() {
    VideoOpenOrigin.generation.removeListener(_onOrigin);
    // A page that disappears mid-flight owes playback nothing.
    VideoOpenGate.releaseCardFlight();
    _removeVeil();
    _flight.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = _from;
    final to = _to;
    if (from == null) {
      if (_controller.isAnimating) _controller.stop();
      return _keyedChild;
    }
    // Measurement has not landed yet: keep the player invisible rather than
    // flashing it at its final position before the flight starts.
    if (to == null) {
      return Opacity(opacity: 0, child: _keyedChild);
    }
    final startScale = (from.width / to.width).clamp(0.15, 1.0);
    final dx = from.center.dx - to.center.dx;
    final dy = from.center.dy - to.center.dy;
    // The rising shape is filled in black, not with the picture: a decoder
    // that publishes its first frame early would otherwise show the video
    // already running inside a card-sized box. The fill is dropped in the same
    // frame the flight ends and the gate lets playback start.
    final surface = Stack(
      fit: StackFit.expand,
      children: [
        _keyedChild,
        const IgnorePointer(child: ColoredBox(color: Colors.black)),
      ],
    );
    return AnimatedBuilder(
      animation: _flight,
      child: surface,
      builder: (context, child) {
        final t = _flight.value;
        final progress = _controller.value;
        // Uniform scale, centre to centre: the first frame lands exactly on the
        // card and the last frame is the player at rest, so neither end can jump
        // regardless of how different the two rectangles are.
        final scale = lerpDouble(startScale, 1, t) ?? 1;
        final radius =
            lerpDouble(AppleRadius.card, 0, _tail(progress, 0.45)) ?? 0;
        return Transform.translate(
          offset: Offset(dx * (1 - t), dy * (1 - t)),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// The open flight's backdrop: a full-screen frosted veil that deepens as the
/// picture grows and then clears, handing the screen over to the player.
///
/// It carries no artwork. The card's poster used to be repainted here so the
/// flight read as one object, but the travelling thing is now the black player
/// itself, and a full-bleed poster in between looked like a second, unrelated
/// image flashing before the video.
final class _OpenVeil extends StatefulWidget {
  const _OpenVeil({required this.from, required this.to, required this.onDone});

  final Rect from;
  final Rect to;
  final VoidCallback onDone;

  @override
  State<_OpenVeil> createState() => _OpenVeilState();
}

final class _OpenVeilState extends State<_OpenVeil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _openDuration,
  );
  late final CurvedAnimation _flight = CurvedAnimation(
    parent: _controller,
    curve: _openCurve,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _flight.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppleRenderProfile.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final blur = _veilEnvelope(
          progress,
          rampIn: _openBlurRampIn,
          fallStart: _openBlurFall,
        );
        final dim = _veilEnvelope(
          progress,
          rampIn: _openDimRampIn,
          fallStart: _openDimFall,
        );
        if (blur <= 0.002 && dim <= 0.002) return const SizedBox.shrink();
        return Positioned.fill(
          child: IgnorePointer(
            child: _BlurVeil(
              sigma: profile.blurSigma * blur,
              dim: _openDim * dim,
            ),
          ),
        );
      },
    );
  }
}

/// The inverse flight drawn in the root overlay while the workspace swaps
/// pages: the cover springs from the player slot back into the card rect.
final class _ReverseFlight extends StatefulWidget {
  const _ReverseFlight({
    required this.from,
    required this.to,
    required this.cover,
    required this.onDone,
  });

  final Rect from;
  final Rect to;
  final String cover;
  final VoidCallback onDone;

  @override
  State<_ReverseFlight> createState() => _ReverseFlightState();
}

final class _ReverseFlightState extends State<_ReverseFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _closeDuration,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: _closeCurve,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reuse the exact CDN thumbnail the card requested so the image is
    // already decoded and cached when the reverse flight starts.
    final profile = AppleRenderProfile.of(context);
    final bucket = _coverBucket(
      widget.to.width,
      MediaQuery.maybeDevicePixelRatioOf(context) ?? 2,
    );
    final from = widget.from;
    final to = widget.to;
    // The exact inverse of the open flight: same uniform scale about the moving
    // centre, so a card that was opened and closed again lands on the same
    // pixels it started from.
    final endScale = (to.width / from.width).clamp(0.08, 1.0);
    return AnimatedBuilder(
      animation: _controller,
      child: _CoverLayer(
        url: _thumbnailUrl(widget.cover, bucket),
        cacheWidth: bucket,
      ),
      builder: (context, card) {
        final progress = _controller.value;
        final t = _animation.value;
        // The blur peaks as the player collapses and clears before the card
        // lands, so the grid is already in focus when the artwork arrives.
        final blur = _veilEnvelope(
          progress,
          rampIn: _closeBlurRampIn,
          fallStart: _closeBlurFall,
        );
        final dim = _veilEnvelope(
          progress,
          rampIn: _closeDimRampIn,
          fallStart: _closeDimFall,
        );
        final scale = lerpDouble(1, endScale, t) ?? 1;
        final centre = Offset.lerp(from.center, to.center, t) ?? to.center;
        final rect = Rect.fromCenter(
          center: centre,
          width: from.width * scale,
          height: from.height * scale,
        );
        final radius =
            lerpDouble(0, AppleRadius.card, _tail(progress, 0.55)) ?? 0;
        // Fade in over the first frames: cutting straight from a live frame to
        // a poster is the one hard edge a dismissal tends to show.
        final opacity =
            _span(progress, 0, 0.08) * (1 - _span(progress, 0.82, 1));
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (blur > 0.002 || dim > 0.002)
                  _BlurVeil(
                    sigma: profile.blurSigma * blur,
                    dim: _closeDim * dim,
                  ),
                Positioned.fromRect(
                  rect: rect,
                  child: Opacity(
                    opacity: opacity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: card,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Grows a blank, black card from the tapped thumbnail all the way to the
/// viewport edges — the "one continuous push into fullscreen" reveal.
///
/// It is deliberately empty: the picture has not started yet, and the poster
/// belongs to the card behind it. What travels is the dark shape the player is
/// about to fill, which is why the flight hands over to the live surface
/// without any image popping in on the way.
///
/// The destination is read from the overlay's own size on every layout rather
/// than baked in at launch time, so a display rotation part-way through the
/// flight still lands exactly on the new viewport. Only the start rectangle is
/// fixed, because that is where the user's finger actually was.
final class _FullScreenExpand extends StatefulWidget {
  const _FullScreenExpand({required this.from, required this.onDone});

  final Rect from;
  final VoidCallback onDone;

  @override
  State<_FullScreenExpand> createState() => _FullScreenExpandState();
}

final class _FullScreenExpandState extends State<_FullScreenExpand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _openDuration,
  );
  late final CurvedAnimation _flight = CurvedAnimation(
    parent: _controller,
    curve: _openCurve,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // The screen belongs to the player now: playback may start.
        VideoOpenGate.releaseFullScreenFlight();
        widget.onDone();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    // Landed or torn down with its overlay, this flight no longer holds the
    // video back.
    VideoOpenGate.releaseFullScreenFlight();
    _flight.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppleRenderProfile.of(context);
    final from = widget.from;
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final to = Offset.zero & constraints.biggest;
            if (to.width <= 0 || to.height <= 0) {
              return const SizedBox.shrink();
            }
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _flight.value;
                final envelope = _veilEnvelope(
                  t,
                  rampIn: 0.16,
                  fallStart: 0.62,
                );
                final rect = Rect.lerp(from, to, t) ?? to;
                final radius = lerpDouble(AppleRadius.card, 0, t) ?? 0;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (envelope > 0.002)
                      _BlurVeil(
                        // A fullscreen takeover sits closer to the viewer than
                        // a card pop, so it reads as a deeper layer: more blur,
                        // and a dim that ends on the player's own black.
                        sigma: profile.blurSigma * 1.25 * envelope,
                        dim: 0.42 * envelope,
                      ),
                    // A blank card rather than artwork: it is the shape the
                    // video is about to fill, not a second image of it.
                    Positioned.fromRect(
                      rect: rect,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: const ColoredBox(color: Colors.black),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
