import 'package:flutter/material.dart';

/// One motion policy for both the in-app preference and the platform setting.
class AppMotion {
  const AppMotion._();

  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 280);

  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration duration(BuildContext context, Duration normal) =>
      isReduced(context) ? Duration.zero : normal;

  static AnimationStyle style(
    BuildContext context, {
    Duration duration = standard,
    Duration reverseDuration = fast,
  }) => isReduced(context)
      ? AnimationStyle.noAnimation
      : AnimationStyle(
          duration: duration,
          reverseDuration: reverseDuration,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

  static Route<T> pageRoute<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    final reduced = isReduced(context);
    return PageRouteBuilder<T>(
      transitionDuration: reduced ? Duration.zero : page,
      reverseTransitionDuration: reduced ? Duration.zero : standard,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduced) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.018),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// A restrained transition for meaningful content changes.
class MotionSwitcher extends StatelessWidget {
  const MotionSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.standard,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
  });

  final Widget child;
  final Duration duration;
  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, duration),
      reverseDuration: AppMotion.duration(context, AppMotion.fast),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: layoutBuilder,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Keeps tab state alive while giving tab changes a quiet cross-fade.
class MotionIndexedStack extends StatelessWidget {
  const MotionIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.standard);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: ExcludeSemantics(
              excluding: i != index,
              child: AnimatedOpacity(
                opacity: i == index ? 1 : 0,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: Offstage(
                  offstage: i != index,
                  child: TickerMode(enabled: i == index, child: children[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
