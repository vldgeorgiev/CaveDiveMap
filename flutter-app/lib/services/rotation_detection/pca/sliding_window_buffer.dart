import '../circular_buffer.dart';
import '../vector3.dart';

/// Sliding window buffer for PCA computation
/// Maintains fixed-duration window of baseline-subtracted samples
class SlidingWindowBuffer {
  final CircularBuffer<Vector3> _buffer;
  final int _samplingRateHz;
  final double _windowSizeSeconds;

  /// Create buffer with specified window size and sampling rate
  ///
  /// Example: windowSizeSeconds=1.0, samplingRateHz=100.0
  /// → buffer holds 100 samples (last 1 second of data)
  SlidingWindowBuffer({
    double windowSizeSeconds = 1.0,
    double samplingRateHz = 100.0,
  })  : _windowSizeSeconds = windowSizeSeconds,
        _samplingRateHz = samplingRateHz.round(),
        _buffer = CircularBuffer<Vector3>(
            (windowSizeSeconds * samplingRateHz).round());

  /// Add new sample to buffer (timestamp parameter ignored for now)
  void add(Vector3 sample, int timestamp) {
    _buffer.add(sample);
  }

  /// Check if buffer is full (ready for PCA)
  bool get isFull => _buffer.isFull;

  /// Get all samples in buffer
  List<Vector3> get samples => _buffer.toList();

  /// Get current number of samples
  int get length => _buffer.length;

  /// Get maximum buffer capacity
  int get capacity => _buffer.maxSize;

  /// Get window size in seconds
  double get windowSizeSeconds => _windowSizeSeconds;

  /// Get sampling rate
  int get samplingRateHz => _samplingRateHz;

  /// Clear all samples
  void clear() => _buffer.clear();

  @override
  String toString() =>
      'SlidingWindowBuffer(${_buffer.length}/${_buffer.maxSize} samples, '
      '${_windowSizeSeconds}s @ ${_samplingRateHz}Hz)';
}
