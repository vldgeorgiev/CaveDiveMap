import 'dart:collection';

/// Fixed-size circular buffer (FIFO queue)
class CircularBuffer<T> {
  final Queue<T> _queue = Queue<T>();
  final int _maxSize;

  CircularBuffer(this._maxSize) {
    if (_maxSize <= 0) {
      throw ArgumentError('maxSize must be positive');
    }
  }

  /// Add item to buffer, removing oldest if at capacity
  void add(T item) {
    _queue.addLast(item);
    if (_queue.length > _maxSize) {
      _queue.removeFirst();
    }
  }

  /// Check if buffer is full
  bool get isFull => _queue.length >= _maxSize;

  /// Get current buffer length
  int get length => _queue.length;

  /// Get maximum buffer size
  int get maxSize => _maxSize;

  /// Check if buffer is empty
  bool get isEmpty => _queue.isEmpty;

  /// Check if buffer is not empty
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Convert to list
  List<T> toList() => _queue.toList();

  /// Get first element (oldest)
  T get first => _queue.first;

  /// Get last element (newest)
  T get last => _queue.last;

  /// Clear all elements
  void clear() => _queue.clear();

  /// Get element at index (0 = oldest)
  T operator [](int index) => _queue.elementAt(index);

  @override
  String toString() => 'CircularBuffer(${_queue.length}/$_maxSize)';
}
