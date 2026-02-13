import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/theme_extensions.dart';

/// Shared interaction profiles for in-dive action controls.
enum ButtonActionProfile { singleTap, pressAndRepeat, holdToConfirm }

class _GlobalPointerLock {
  static int? _activePointer;

  static bool tryAcquire(int pointer) {
    if (_activePointer == null) {
      _activePointer = pointer;
      return true;
    }
    return _activePointer == pointer;
  }

  static bool owns(int pointer) => _activePointer == pointer;

  static void release(int pointer) {
    if (_activePointer == pointer) {
      _activePointer = null;
    }
  }
}

/// Hardened in-dive action button.
class UnderwaterActionButton extends StatefulWidget {
  final double size;
  final Color color;
  final IconData? icon;
  final String? text;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final VoidCallback? onTapCancel;
  final bool showProgress;
  final double progressValue;
  final bool enabled;
  final ButtonActionProfile actionProfile;
  final Duration stablePressDuration;
  final double slopTolerance;
  final Duration cooldownDuration;
  final Duration repeatInitialDelay;
  final Duration repeatInterval;
  final Duration holdDuration;
  final ValueChanged<double>? onHoldProgress;
  final VoidCallback? onHoldCancelled;
  final ValueChanged<bool>? onInteractionStateChanged;

  const UnderwaterActionButton({
    super.key,
    required this.size,
    required this.color,
    this.icon,
    this.text,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.showProgress = false,
    this.progressValue = 0.0,
    this.enabled = true,
    this.actionProfile = ButtonActionProfile.singleTap,
    this.stablePressDuration = const Duration(milliseconds: 50),
    this.slopTolerance = 40.0,
    this.cooldownDuration = const Duration(milliseconds: 100),
    this.repeatInitialDelay = const Duration(milliseconds: 500),
    this.repeatInterval = const Duration(milliseconds: 120),
    this.holdDuration = const Duration(seconds: 6),
    this.onHoldProgress,
    this.onHoldCancelled,
    this.onInteractionStateChanged,
  }) : assert(icon != null || text != null, 'Must provide either icon or text');

  @override
  State<UnderwaterActionButton> createState() => _UnderwaterActionButtonState();
}

class _UnderwaterActionButtonState extends State<UnderwaterActionButton> {
  int? _activePointer;
  Offset? _tapDownPosition;
  bool _isPressed = false;
  bool _isRepeating = false;
  bool _holdCompleted = false;
  bool _stablePressMet = false;
  bool _cooldownActive = false;

  Timer? _stablePressTimer;
  Timer? _cooldownTimer;
  Timer? _repeatStartTimer;
  Timer? _repeatTimer;
  Timer? _holdTimer;
  Timer? _holdProgressTimer;

  bool get _isInteractionActive => _activePointer != null;

  @override
  void dispose() {
    _cancelAllTimers();
    _releasePointerLock();
    super.dispose();
  }

  void _cancelAllTimers() {
    _stablePressTimer?.cancel();
    _stablePressTimer = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _repeatStartTimer?.cancel();
    _repeatStartTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdProgressTimer?.cancel();
    _holdProgressTimer = null;
  }

  void _cancelInteractionTimers() {
    _stablePressTimer?.cancel();
    _stablePressTimer = null;
    _repeatStartTimer?.cancel();
    _repeatStartTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdProgressTimer?.cancel();
    _holdProgressTimer = null;
  }

  void _releasePointerLock() {
    if (_activePointer != null) {
      _GlobalPointerLock.release(_activePointer!);
      _activePointer = null;
    }
  }

  bool _isCooldownActive() => _cooldownActive;

  void _startCooldown() {
    _cooldownActive = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(widget.cooldownDuration, () {
      _cooldownActive = false;
    });
  }

  bool _tryActivate({bool bypassCooldown = false}) {
    if (!widget.enabled || widget.onTap == null) return false;
    if (!bypassCooldown && _isCooldownActive()) return false;

    widget.onTap!.call();
    _startCooldown();
    return true;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    if (_isInteractionActive) return;
    if (_isCooldownActive()) return;
    if (!_GlobalPointerLock.tryAcquire(event.pointer)) return;

    _activePointer = event.pointer;
    _tapDownPosition = event.localPosition;
    _holdCompleted = false;
    _isRepeating = false;
    _stablePressMet = widget.stablePressDuration == Duration.zero;

    _stablePressTimer = Timer(widget.stablePressDuration, () {
      _stablePressMet = true;
    });

    setState(() {
      _isPressed = true;
    });
    widget.onInteractionStateChanged?.call(true);
    widget.onTapDown?.call(
      TapDownDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
      ),
    );

    switch (widget.actionProfile) {
      case ButtonActionProfile.singleTap:
        break;
      case ButtonActionProfile.pressAndRepeat:
        _startRepeatTimers();
        break;
      case ButtonActionProfile.holdToConfirm:
        _startHoldTimers();
        break;
    }
  }

  void _startRepeatTimers() {
    _repeatStartTimer = Timer(widget.repeatInitialDelay, () {
      if (!_isInteractionActive) return;
      _isRepeating = true;
      _repeatTimer = Timer.periodic(widget.repeatInterval, (_) {
        if (!_isInteractionActive) return;
        _tryActivate(bypassCooldown: true);
      });
    });
  }

  void _startHoldTimers() {
    int elapsedMs = 0;
    widget.onHoldProgress?.call(0.0);

    _holdProgressTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isInteractionActive) return;
      elapsedMs += 16;
      final progress = (elapsedMs / widget.holdDuration.inMilliseconds).clamp(
        0.0,
        1.0,
      );
      widget.onHoldProgress?.call(progress);
    });

    _holdTimer = Timer(widget.holdDuration, () {
      if (!_isInteractionActive) return;
      _holdCompleted = true;
      widget.onHoldProgress?.call(1.0);
      _tryActivate(bypassCooldown: true);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_GlobalPointerLock.owns(event.pointer)) return;
    if (!_isInteractionActive || _tapDownPosition == null) return;

    final movedDistance = (event.localPosition - _tapDownPosition!).distance;
    if (movedDistance > widget.slopTolerance) {
      _cancelCurrentInteraction(notifyHoldCancel: true);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_GlobalPointerLock.owns(event.pointer)) return;

    final isStablePress = _stablePressMet;

    switch (widget.actionProfile) {
      case ButtonActionProfile.singleTap:
        if (isStablePress) {
          _tryActivate();
          widget.onTapUp?.call(
            TapUpDetails(
              globalPosition: event.position,
              localPosition: event.localPosition,
              kind: event.kind,
            ),
          );
        } else {
          widget.onTapCancel?.call();
        }
        break;
      case ButtonActionProfile.pressAndRepeat:
        if (!_isRepeating && isStablePress) {
          _tryActivate();
          widget.onTapUp?.call(
            TapUpDetails(
              globalPosition: event.position,
              localPosition: event.localPosition,
              kind: event.kind,
            ),
          );
        } else if (!_isRepeating) {
          widget.onTapCancel?.call();
        }
        break;
      case ButtonActionProfile.holdToConfirm:
        if (!_holdCompleted) {
          widget.onTapCancel?.call();
          widget.onHoldCancelled?.call();
        }
        break;
    }

    _finishInteraction(resetHoldProgress: !_holdCompleted);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!_GlobalPointerLock.owns(event.pointer)) return;
    _cancelCurrentInteraction(notifyHoldCancel: true);
  }

  void _cancelCurrentInteraction({required bool notifyHoldCancel}) {
    widget.onTapCancel?.call();
    if (notifyHoldCancel &&
        widget.actionProfile == ButtonActionProfile.holdToConfirm) {
      widget.onHoldCancelled?.call();
    }
    _finishInteraction(resetHoldProgress: true);
  }

  void _finishInteraction({required bool resetHoldProgress}) {
    _cancelInteractionTimers();
    _releasePointerLock();
    _tapDownPosition = null;
    _isRepeating = false;
    _holdCompleted = false;
    _stablePressMet = false;

    if (resetHoldProgress) {
      widget.onHoldProgress?.call(0.0);
    }

    if (mounted) {
      setState(() {
        _isPressed = false;
      });
    }
    widget.onInteractionStateChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    const minTapTarget = 60.0;
    final tapTargetSize = widget.size < minTapTarget
        ? minTapTarget
        : widget.size;
    final borderRadius = BorderRadius.circular(widget.size * 0.24);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Container(
        width: tapTargetSize,
        height: tapTargetSize,
        alignment: Alignment.center,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: _isPressed ? 0.96 : 1.0,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: widget.enabled
                        ? widget.color
                        : widget.color.withOpacity(0.45),
                    boxShadow: AppShadows.buttonShadow,
                  ),
                  child: Center(
                    child: widget.icon != null
                        ? Icon(
                            widget.icon,
                            color: Colors.white,
                            size: widget.size * AppButtonSizes.iconScaleLarge,
                          )
                        : Text(
                            widget.text!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  widget.size * AppButtonSizes.textScaleMedium,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                if (widget.showProgress)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: FractionallySizedBox(
                          widthFactor: widget.progressValue.clamp(0.0, 1.0),
                          child: Container(
                            color: Colors.white.withOpacity(0.24),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
