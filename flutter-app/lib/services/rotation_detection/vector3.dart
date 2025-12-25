import 'dart:math';

/// 3D vector for magnetometer data
class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  /// Zero vector
  static const zero = Vector3(0, 0, 0);

  /// Compute magnitude (length) of vector
  double get magnitude =>
      sqrt(x * x + y * y + z * z);

  /// Dot product with another vector
  double dot(Vector3 other) =>
      x * other.x + y * other.y + z * other.z;

  /// Vector addition
  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  /// Vector subtraction
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  /// Scalar multiplication
  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);

  /// Scalar division
  Vector3 operator /(double scalar) =>
      Vector3(x / scalar, y / scalar, z / scalar);

  /// Normalize to unit vector
  Vector3 normalize() {
    final mag = magnitude;
    if (mag == 0) return Vector3.zero;
    return this / mag;
  }

  @override
  String toString() => 'Vector3($x, $y, $z)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector3 &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}
