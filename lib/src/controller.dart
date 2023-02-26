part of 'popup_area.dart';

const _kAssertionMessage = 'A PopupController was used after being '
    'disposed.\nOnce you have called dispose() on a PopupController, '
    'it can no longer be used.';

enum _PopupStatus { open, closing, closed }

class PopupController {
  PopupController({double scrollX = 0.0, double scrollY = 0.0})
      : _isInternal = false {
    _scrollOffsetNotifier.value = Offset(scrollX, scrollY);
  }

  PopupController._internal() : _isInternal = true;

  final bool _isInternal;
  final _scrollOffsetNotifier = ValueNotifier(Offset.zero);

  _PopupStatus _status = _PopupStatus.closed;
  bool _disposed = false;

  Key? _popupKey;
  _PopupOverlayState? _overlayState;
  Timer? _openTimer;
  Timer? _closeTimer;

  Key? get popupKey => _popupKey;

  set scrollX(double x) {
    _scrollOffsetNotifier.value = Offset(x, _scrollOffsetNotifier.value.dy);
  }

  set scrollY(double y) {
    _scrollOffsetNotifier.value = Offset(_scrollOffsetNotifier.value.dx, y);
  }

  void dispose() {
    assert(!_disposed, _kAssertionMessage);

    _overlayState?._close();

    _reset();
    _scrollOffsetNotifier.dispose();
    _disposed = true;
  }

  void _reset() {
    assert(!_disposed, _kAssertionMessage);

    cancelCloseTimer();
    _status = _PopupStatus.closed;
    _overlayState = null;

    // WARNING: Scroll offset must not be reset.
    // _scrollOffsetNotifier.value = Offset.zero;
  }

  void _startOpenTimer(Duration wait, void Function() callback) {
    _openTimer?.cancel();
    _openTimer = null;

    if (wait == Duration.zero) {
      callback();
    } else {
      _openTimer = Timer(wait, callback);
    }
  }

  void startCloseTimer([Duration wait = Duration.zero]) {
    assert(!_disposed, _kAssertionMessage);

    _openTimer?.cancel();

    if (_status == _PopupStatus.open) {
      _status = _PopupStatus.closing;

      // In the cases where an exit event of the mouse pointer triggers
      // a popup to be closed and the position of the mouse pointer is
      // covered with the popup, no delay here means that an opened popup
      // instantly closes the popup. To prevent it, the duration of two
      // milliseconds is used.
      _closeTimer = Timer(
        wait == Duration.zero ? const Duration(milliseconds: 2) : wait,
        () => _overlayState?._closeWithAnimation(),
      );
    }
  }

  void cancelCloseTimer() {
    assert(!_disposed, _kAssertionMessage);

    _closeTimer?.cancel();
    _closeTimer = null;
    _status = _PopupStatus.open;
  }

  void close() {
    assert(!_disposed, _kAssertionMessage);

    _overlayState?._close();
  }

  void closeWithAnimation() {
    assert(!_disposed, _kAssertionMessage);

    _overlayState?._closeWithAnimation();
  }
}
