import 'package:flutter/material.dart';

/// Adapts effect cost to the panel's refresh rate.
///
/// Flutter drives animations from the vsync signal, so they already run at the
/// panel rate — 60 Hz on an older tablet, 120 Hz on a current one. What limits
/// the *achieved* frame rate is the per-frame cost: on a 120 Hz panel the
/// budget drops from 16.7 ms to 8.3 ms, and an effect that merely filled the
/// old budget now halves the frame rate and looks *worse* than on 60 Hz.
///
/// Effects whose cost is dominated by GPU work (a full-screen backdrop blur)
/// therefore scale their radius with the available budget instead of assuming
/// 60 Hz.
final class AppleRenderProfile {
  const AppleRenderProfile({
    required this.refreshRate,
    required this.blurSigma,
  });

  /// Panel refresh rate in Hz; falls back to 60 when the platform is silent.
  final double refreshRate;

  /// Blur radius that still fits the frame budget at [refreshRate].
  final double blurSigma;

  double get frameBudgetMs => 1000 / refreshRate;

  static AppleRenderProfile of(BuildContext context) {
    var hz = View.maybeOf(context)?.display.refreshRate ?? 60;
    if (!hz.isFinite || hz <= 0) hz = 60;
    // Tiers rather than a formula: each one keeps a full-screen backdrop blur
    // inside roughly half of the frame budget, which is what it takes to hold
    // the target rate while a video texture is also being composited.
    final sigma = switch (hz) {
      >= 144 => 8.0,
      >= 110 => 11.0,
      >= 80 => 14.0,
      _ => 18.0,
    };
    return AppleRenderProfile(refreshRate: hz, blurSigma: sigma);
  }
}

/// iOS-inspired motion tokens.
///
/// Apple transitions are short, decelerating and occasionally springy: they
/// never bounce dramatically, they just settle a touch past their target.
/// Keeping the numbers in one place lets dialogs, sheets, toasts, buttons and
/// page routes share the same feel.
abstract final class AppleMotion {
  /// Press feedback and state toggles.
  static const Duration quick = Duration(milliseconds: 180);

  /// Dialogs, toasts and control entrances.
  static const Duration standard = Duration(milliseconds: 320);

  /// Sheets and page-sized transitions.
  static const Duration gentle = Duration(milliseconds: 420);

  /// A gentle overshoot. Used for entrances so a surface settles with a small
  /// spring instead of stopping dead at 1.0.
  static const Curve spring = Cubic(0.22, 1.14, 0.36, 1.0);

  /// Strong deceleration for surfaces sliding into place.
  static const Curve entrance = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Symmetric ease for persistent state changes.
  static const Curve standardCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Accelerating exit; iOS dismissals leave faster than they arrive.
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);

  static const double pressScale = 0.945;
  static const double entranceScale = 0.9;

  /// Drop-in [AnimationStyle] for `DialogRoute` / `showDialog`.
  static const AnimationStyle dialog = AnimationStyle(
    curve: spring,
    duration: standard,
    reverseCurve: exit,
    reverseDuration: quick,
  );

  /// Drop-in style for `showModalBottomSheet(sheetAnimationStyle:)`.
  static const AnimationStyle sheet = AnimationStyle(
    curve: entrance,
    duration: gentle,
    reverseCurve: exit,
    reverseDuration: standard,
  );
}

/// Adds an iOS-style press response to any control without stealing its taps.
///
/// It uses a raw [Listener] rather than a [GestureDetector], so it never enters
/// a gesture arena and cannot compete with the child's own InkWell / button.
/// Both [Transform] and [Opacity] are paint-only: layout size is unchanged.
final class ApplePressable extends StatefulWidget {
  const ApplePressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = AppleMotion.pressScale,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<ApplePressable> createState() => _ApplePressableState();
}

final class _ApplePressableState extends State<ApplePressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || !widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
    onPointerUp: (_) => _setPressed(false),
    onPointerCancel: (_) => _setPressed(false),
    child: AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: _pressed ? AppleMotion.quick : AppleMotion.standard,
      curve: _pressed ? AppleMotion.standardCurve : AppleMotion.spring,
      child: widget.child,
    ),
  );
}

/// A springy fade + lift + scale entrance for surfaces appearing on demand.
///
/// Paint-only transforms keep the child's measured size intact, which matters
/// for the dense information rows used throughout the app.
final class AppleAppear extends StatelessWidget {
  const AppleAppear({
    super.key,
    required this.child,
    this.fromScale = AppleMotion.entranceScale,
    this.offsetY = 12,
    this.duration = AppleMotion.standard,
  });

  final Widget child;
  final double fromScale;
  final double offsetY;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: duration,
    curve: AppleMotion.spring,
    builder: (context, value, child) => Opacity(
      // The spring curve overshoots; opacity must stay within [0, 1].
      opacity: value.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, offsetY * (1 - value)),
        child: Transform.scale(
          scale: fromScale + (1 - fromScale) * value,
          child: child,
        ),
      ),
    ),
    child: child,
  );
}

/// A reusable transition builder for [AnimatedSwitcher] so state swaps across
/// the app share the same spring instead of ad-hoc curves.
Widget appleSwitcherTransition(Widget child, Animation<double> animation) =>
    FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppleMotion.entrance),
      child: ScaleTransition(
        scale: Tween<double>(begin: AppleMotion.entranceScale, end: 1).animate(
          CurvedAnimation(parent: animation, curve: AppleMotion.spring),
        ),
        child: child,
      ),
    );

/// Plays a soft fade + lift + scale whenever a workspace view becomes current.
///
/// Workspace pages are kept alive and swapped with [Offstage], not pushed as
/// Navigator routes, so route-level page transitions never run for them. This
/// widget gives every such reveal — opening a video in particular — the same
/// settling motion without changing the child's measured layout.
final class ApplePageEnter extends StatefulWidget {
  const ApplePageEnter({
    super.key,
    required this.active,
    required this.child,
    this.duration = AppleMotion.gentle,
  });

  final bool active;
  final Widget child;
  final Duration duration;

  @override
  State<ApplePageEnter> createState() => _ApplePageEnterState();
}

final class _ApplePageEnterState extends State<ApplePageEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: AppleMotion.entrance,
  );

  @override
  void initState() {
    super.initState();
    // A freshly mounted view is the one being opened: play the entrance.
    // Views built ahead of time (previews / retained tabs) stay fully opaque
    // so they never flash when the predictive-back transition reveals them.
    if (widget.active) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(ApplePageEnter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    child: widget.child,
    builder: (context, child) {
      final t = _animation.value;
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: Transform.scale(scale: 0.978 + 0.022 * t, child: child),
        ),
      );
    },
  );
}
