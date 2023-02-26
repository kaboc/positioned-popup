import 'dart:async';

import 'package:flutter/material.dart';

import 'rendering.dart';

part 'controller.dart';
part 'overlay.dart';

typedef PositionedPopupBuilder = Widget Function(
  BuildContext,
  Animation<double>,
  Widget,
);

class PopupArea extends StatefulWidget {
  const PopupArea({super.key, required this.child});

  final Widget child;

  @override
  State<PopupArea> createState() => PopupAreaState();

  static PopupAreaState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<PopupAreaState>();
  }

  static PopupAreaState of(BuildContext context) {
    return maybeOf(context)!;
  }
}

class PopupAreaState extends State<PopupArea> {
  PopupController? _controller;
  List<Widget>? _overlayList;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_overlayList != null) ..._overlayList!,
        ],
      ),
    );
  }

  void _removeOverlay() {
    setState(() => _overlayList = null);

    _controller?._popupKey = null;

    if (_controller?._isInternal ?? false) {
      _controller?.dispose();
    } else {
      _controller?._reset();
    }
    _controller = null;
  }

  void open({
    required Widget child,
    required Offset position,
    PopupController? controller,
    PositionedPopupBuilder? builder,
    Key? popupKey,
    double maxWidth = double.infinity,
    double maxHeight = double.infinity,
    double horizontalOffset = kPopupHorizontalOffset,
    double verticalOffset = kPopupVerticalOffset,
    HitTestBehavior? hitTestBehavior = HitTestBehavior.translucent,
    bool barrierDismissible = true,
    Color barrierColor = Colors.transparent,
    bool forceReopen = false,
    Duration openDuration = const Duration(milliseconds: 300),
    Duration closeDuration = const Duration(milliseconds: 300),
    Duration openWait = Duration.zero,
    Duration? autoCloseWait,
  }) {
    final existingController = _controller;

    if (!forceReopen) {
      final isSameStillOpen = _overlayList != null &&
          existingController != null &&
          existingController._status != _PopupStatus.closed &&
          popupKey != null &&
          popupKey == existingController._popupKey;

      if (isSameStillOpen) {
        existingController._overlayState?._cancelClosingAnimation();
        return;
      }
    }

    _removeOverlay();

    _controller = controller ?? PopupController._internal();

    // This must be kept separated from the above assignment, otherwise
    // it causes an issue where popups don't appear in some cases.
    _controller!
      .._popupKey = popupKey
      .._startOpenTimer(openWait, () {
        setState(() {
          if (_controller == null) {
            return;
          }

          final box = context.findRenderObject() as RenderBox?;
          final localPositionInArea = box?.globalToLocal(position) ?? position;

          _overlayList = [
            if (barrierColor != Colors.transparent)
              IgnorePointer(
                child: ColoredBox(color: barrierColor),
              ),
            _PopupOverlay(
              // This key is for making sure not to reuse _PopupOverlayState.
              key: ValueKey(DateTime.now()),
              controller: _controller!,
              localPosition: localPositionInArea,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              horizontalOffset: horizontalOffset,
              verticalOffset: verticalOffset,
              hitTestBehavior: hitTestBehavior,
              barrierDismissible: barrierDismissible,
              barrierColor: barrierColor,
              openDuration: openDuration,
              closeDuration: closeDuration,
              autoCloseWait: autoCloseWait,
              removeOverlay: _removeOverlay,
              builder: builder ??
                  (context, animation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              child: child,
            ),
          ];
        });
      });
  }
}
