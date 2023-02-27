part of 'popup_area.dart';

class _PopupOverlay extends StatefulWidget {
  const _PopupOverlay({
    required super.key,
    required this.child,
    required this.controller,
    required this.builder,
    required this.localPosition,
    required this.maxWidth,
    required this.maxHeight,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.hitTestBehavior,
    required this.barrierDismissible,
    required this.barrierColor,
    required this.autoCloseWait,
    required this.openDuration,
    required this.closeDuration,
    required this.removeOverlay,
  });

  final Widget child;
  final PopupController controller;
  final PositionedPopupBuilder builder;
  final Offset localPosition;
  final double maxWidth;
  final double maxHeight;
  final double horizontalOffset;
  final double verticalOffset;
  final HitTestBehavior? hitTestBehavior;
  final bool barrierDismissible;
  final Color barrierColor;
  final Duration openDuration;
  final Duration closeDuration;
  final Duration? autoCloseWait;
  final VoidCallback removeOverlay;

  @override
  State<_PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<_PopupOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final double _initialScrollX =
      widget.controller._scrollOffsetNotifier.value.dx;
  late final double _initialScrollY =
      widget.controller._scrollOffsetNotifier.value.dy;

  @override
  void initState() {
    super.initState();

    widget.controller
      .._status = _PopupStatus.open
      .._overlayState = this;

    _animationController = AnimationController(
      vsync: this,
      duration: widget.openDuration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          widget.removeOverlay();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _cancelClosingAnimation() {
    if (!mounted) {
      return;
    }

    widget.controller.cancelCloseTimer();

    _animationController
      ..duration = widget.openDuration
      ..forward();
  }

  void _close() {
    if (!mounted) {
      return;
    }

    _animationController.stop();

    if (widget.controller._status != _PopupStatus.closed) {
      widget.controller.cancelCloseTimer();
      widget.removeOverlay();
    }
  }

  void _closeWithAnimation() {
    if (!mounted) {
      return;
    }

    widget.controller.cancelCloseTimer();
    widget.controller._status = _PopupStatus.closing;

    _animationController
      ..duration = widget.closeDuration
      ..reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.barrierDismissible &&
              widget.hitTestBehavior == HitTestBehavior.deferToChild
          ? HitTestBehavior.translucent
          : widget.hitTestBehavior,
      onTap: widget.barrierDismissible ? _close : null,
      child: ValueListenableBuilder(
        valueListenable: widget.controller._scrollOffsetNotifier,
        builder: (context, offset, _) {
          return Popup(
            localPosition: widget.localPosition,
            horizontalOffset: widget.horizontalOffset,
            verticalOffset: widget.verticalOffset,
            scrollX: _initialScrollX - offset.dx,
            scrollY: _initialScrollY - offset.dy,
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth,
                maxHeight: widget.maxHeight,
              ),
              child: GestureDetector(
                onTap: () {},
                child: MouseRegion(
                  onEnter: (_) {
                    // In custom_text, which is a package that this package
                    // was initially created for, the onGesture handler is
                    // called one microsecond after an event. If the
                    // closing timer is started there and the timer is
                    // cancelled here, the cancel must be executed later.
                    // The delay here is for ensuring it.
                    Future.delayed(
                      const Duration(microseconds: 2),
                      _cancelClosingAnimation,
                    );
                  },
                  onExit: (_) {
                    if (widget.autoCloseWait != null) {
                      Future.delayed(const Duration(microseconds: 2), () {
                        widget.controller.startCloseTimer(
                          widget.autoCloseWait ?? Duration.zero,
                        );
                      });
                    }
                  },
                  child: widget.builder(
                    context,
                    _animationController.view,
                    widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
