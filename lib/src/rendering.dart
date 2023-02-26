import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const double kPadding = 2.0;
const double kPopupHorizontalOffset = 0.0;
const double kPopupVerticalOffset = 4.0;

class Popup extends SingleChildRenderObjectWidget {
  const Popup({
    super.key,
    required super.child,
    required this.localPosition,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.textDirection,
    required this.scrollX,
    required this.scrollY,
  });

  final Offset localPosition;
  final double horizontalOffset;
  final double verticalOffset;
  final TextDirection textDirection;
  final double scrollX;
  final double scrollY;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPopup(
      position: localPosition,
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      scrollOffset: Offset(scrollX, scrollY),
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPopup renderObject) {
    renderObject
      ..position = localPosition
      ..horizontalOffset = horizontalOffset
      ..verticalOffset = verticalOffset
      ..scrollOffset = Offset(scrollX, scrollY)
      ..textDirection = textDirection;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DoubleProperty('horizontalOffset', horizontalOffset));
    properties.add(DoubleProperty('verticalOffset', verticalOffset));
  }
}

class RenderPopup extends RenderShiftedBox {
  RenderPopup({
    required Offset position,
    required double horizontalOffset,
    required double verticalOffset,
    required Offset scrollOffset,
    required TextDirection textDirection,
  }) : super(null) {
    this.position = position;
    this.horizontalOffset = horizontalOffset;
    this.verticalOffset = verticalOffset;
    this.scrollOffset = scrollOffset;
    this.textDirection = textDirection;
  }

  Offset? _position;
  double? _horizontalOffset;
  double? _verticalOffset;
  Offset? _scrollOffset;
  TextDirection? _textDirection;

  set position(Offset position) {
    if (_position != position) {
      _position = position;
      markNeedsLayout();
    }
  }

  set horizontalOffset(double horizontalOffset) {
    if (_horizontalOffset != horizontalOffset) {
      _horizontalOffset = horizontalOffset;
      markNeedsLayout();
    }
  }

  set verticalOffset(double verticalOffset) {
    if (_verticalOffset != verticalOffset) {
      _verticalOffset = verticalOffset;
      markNeedsLayout();
    }
  }

  set scrollOffset(Offset scrollOffset) {
    if (_scrollOffset != scrollOffset) {
      _scrollOffset = scrollOffset;
      markNeedsLayout();
    }
  }

  set textDirection(TextDirection? textDirection) {
    if (_textDirection != textDirection) {
      _textDirection = textDirection;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;

    final innerConstraints = constraints.deflate(
      const EdgeInsets.all(kPadding),
    );
    child!.layout(innerConstraints.loosen(), parentUsesSize: true);

    size = constraints.constrain(child!.size);
    _decideChildOffset(maxW, maxH);
  }

  void _decideChildOffset(double maxW, double maxH) {
    final childW = child!.size.width;
    final childH = child!.size.height;
    final posX = _position!.dx;
    final posY = _position!.dy;
    final hOffset = _horizontalOffset!;
    final vOffset = _verticalOffset!;

    var x = _textDirection == TextDirection.ltr
        ? posX + hOffset + childW > maxW
            ? maxW - childW
            : posX + hOffset
        : posX - hOffset - childW < 0.0
            ? 0.0
            : posX - hOffset - childW;

    var y = posY < maxH / 2
        ? posY + vOffset + childH > maxH
            ? maxH - childH
            : posY + vOffset
        : posY - vOffset - childH < 0.0
            ? 0.0
            : posY - vOffset - childH;

    if (maxW != double.infinity) {
      if (x < kPadding) {
        x = kPadding;
      } else if (x + childW > maxW - kPadding) {
        x = maxW - kPadding - childW;
      }
    }

    if (maxH != double.infinity) {
      if (y < kPadding) {
        y = kPadding;
      } else if (y + childH > maxH - kPadding) {
        y = maxH - kPadding - childH;
      }
    }

    final childParentData = child!.parentData! as BoxParentData;
    childParentData.offset = Offset(x, y) + _scrollOffset!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('position', _position));
    properties.add(DoubleProperty('horizontalOffset', _horizontalOffset));
    properties.add(DoubleProperty('verticalOffset', _verticalOffset));
  }
}
