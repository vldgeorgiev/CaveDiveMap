import 'dart:math';

/// 2D vector for PCA plane projections
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  /// Zero vector
  static const zero = Vector2(0, 0);

  /// Compute magnitude (length) of vector
  double get magnitude => sqrt(x * x + y * y);

  /// Dot product with another vector
  double dot(Vector2 other) =>
      x * other.x + y * other.y;

  /// Vector addition
  Vector2 operator +(Vector2 other) =>
      Vector2(x + other.x, y + other.y);

  /// Vector subtraction
  Vector2 operator -(Vector2 other) =>
      Vector2(x - other.x, y - other.y);

  /// Scalar multiplication
  Vector2 operator *(double scalar) =>
      Vector2(x * scalar, y * scalar);

  /// Scalar division
  Vector2 operator /(double scalar) =>
      Vector2(x / scalar, y / scalar);

  /// Normalize to unit vector
  Vector2 normalize() {
    final mag = magnitude;
    if (mag == 0) return Vector2.zero;
    return this / mag;
  }

  @override
  String toString() => 'Vector2($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2 &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
