Point :: struct {
    x: int;
    y: int;
}

point :: (x: int, y: int) -> Point {
    p: Point = ---;
    p.x = x;
    p.y = y;

    return p;
}

point :: (v: Vector2) -> Point {
    p: Point = ---;
    p.x = roundi(v.x);
    p.y = roundi(v.y);

    return p;
}

vec :: (p: Point) -> Vector2 {
    v: Vector2 = ---;
    v.x = p.x;
    v.y = p.y;

    return v;
}

BoundingPoints :: struct {
    lower: Point;
    upper: Point;
}

bounding :: (lower: Point, upper: Point) -> BoundingPoints {
    bounding: BoundingPoints = ---;
    bounding.lower = lower;
    bounding.upper = upper;

    return bounding;
}

// vector
atan2 :: (v: Vector2) -> float {
    return atan2(v.y, v.x);
}

projectOnto :: (v: Vector2, dest: Vector2) -> Vector2 {
    norm_dest := normalize(dest);
    top := dot(v, norm_dest);
    bottom := dot(norm_dest, norm_dest);

    result := normalize(v);
    result *= top / bottom;

    return result;
}

orthogonal :: (v: Vector2) -> Vector2 {
    r: Vector2 = ---;
    r.x = -v.y;
    r.y = v.x;

    return r;
}

// point
atan2 :: (v: Point) -> float {
    return atan2(cast(float) v.y, cast(float) v.x);
}

// float
radians_between :: (start: float, end: float) -> float {
    // TODO this is bad and probably slow I need to change it later
    if end < start {
        if start - end > PI {
            return PI * 2 - (start - end);
        } else {
            return end - start;
        }
    } else {
        if end - start > PI {
            return (end - start) - PI * 2;
        } else {
            return end - start;
        }
    }
}

// operators
operator + :: (a: Point, b: Point) -> Point {
    r: Point = ---;
    r.x = a.x + b.x;
    r.y = a.y + b.y;

    return r;
}

operator + :: (a: *Point, b: Point) {
    a.x += b.x;
    a.y += b.y;
}

operator + :: (a: Point, b: int) -> Point #symmetric {
    r: Point = ---;
    r.x = a.x + b;
    r.y = a.y + b;

    return r;
}

operator + :: (a: *Point, b: int) {
    a.x += b;
    a.y += b;
}

operator + :: (a: Point, b: Vector2) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x + b.x;
    r.y = a.y + b.y;

    return r;
}

operator + :: (a: Point, b: float) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x + b;
    r.y = a.y + b;

    return r;
}



operator - :: (a: Point, b: Point) -> Point {
    r: Point = ---;
    r.x = a.x - b.x;
    r.y = a.y - b.y;

    return r;
}

operator - :: (a: *Point, b: Point) {
    a.x -= b.x;
    a.y -= b.y;
}

operator - :: (a: Point, b: int) -> Point #symmetric {
    r: Point = ---;
    r.x = a.x - b;
    r.y = a.y - b;

    return r;
}

operator - :: (a: *Point, b: int) {
    a.x -= b;
    a.y -= b;
}

operator - :: (a: Point, b: Vector2) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x - b.x;
    r.y = a.y - b.y;

    return r;
}

operator - :: (a: Point, b: float) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x - b;
    r.y = a.y - b;

    return r;
}



operator * :: (a: Point, b: Point) -> Point {
    r: Point = ---;
    r.x = a.x * b.x;
    r.y = a.y * b.y;

    return r;
}

operator * :: (a: *Point, b: Point) {
    a.x *= b.x;
    a.y *= b.y;
}

operator * :: (a: Point, b: int) -> Point #symmetric {
    r: Point = ---;
    r.x = a.x * b;
    r.y = a.y * b;

    return r;
}

operator * :: (a: *Point, b: int) {
    r.x *= b;
    r.y *= b;
}

operator * :: (a: Point, b: Vector2) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x * b.x;
    r.y = a.y * b.y;

    return r;
}

operator * :: (a: Point, b: float) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x * b;
    r.y = a.y * b;

    return r;
}



operator - :: (a: Point) -> Point {
    r: Point = ---;
    r.x = -a.x;
    r.x = -a.y;

    return r;
}

operator - :: (a: *Point) {
    a.x = -a.x;
    a.y = -a.y;
}



operator / :: (a: Point, b: Point) -> Point {
    r: Point = ---;
    r.x = a.x / b.x;
    r.y = a.y / b.y;

    return r;
}

operator / :: (a: *Point, b: Point) {
    a.x /= b.x;
    a.y /= b.y;
}

operator / :: (a: Point, b: int) -> Point #symmetric {
    r: Point = ---;
    r.x = a.x / b;
    r.y = a.y / b;

    return r;
}

operator / :: (a: *Point, b: int) {
    a.x /= b;
    a.y /= b;
}

operator / :: (a: Point, b: Vector2) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x / b.x;
    r.y = a.y / b.y;

    return r;
}

operator / :: (a: Point, b: float) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x / b;
    r.y = a.y / b;

    return r;
}



operator == :: (a: Point, b: Point) -> bool {
    return a.x == b.x && a.y == b.y;
}

operator == :: (a: Point, b: Vector2) -> bool #symmetric {
    return a.x == b.x && a.y == b.y;
}



operator * :: (a: Vector2, b: int) -> Vector2 #symmetric {
    r: Vector2 = ---;
    r.x = a.x * b;
    r.y = a.y * b;

    return r;
}

operator * :: (a: *Vector2, b: int) {
    a.x *= b;
    a.y *= b;
}



operator - :: (a: Vector2) -> Vector2 {
    r: Vector2 = ---;
    r.x = -a.x;
    r.y = -a.y;

    return r;
}

operator - :: (a: *Vector2) {
    a.x = -a.x;
    a.y = -a.y;
}



operator + :: (aabb: BoundingPoints, p: Point) -> BoundingPoints {
    r: BoundingPoints = ---;
    r.lower = aabb.lower + p;
    r.upper = aabb.upper + p;

    return r;
}

operator - ::  (aabb: BoundingPoints, p: Point) -> BoundingPoints {
    r: BoundingPoints = ---;
    r.lower = aabb.lower - p;
    r.upper = aabb.upper - p;

    return r;
}

operator * ::  (aabb: BoundingPoints, p: Point) -> BoundingPoints {
    r: BoundingPoints = ---;
    r.lower = aabb.lower * p;
    r.upper = aabb.upper * p;

    return r;
}

operator / ::  (aabb: BoundingPoints, p: Point) -> BoundingPoints {
    r: BoundingPoints = ---;
    r.lower = aabb.lower / p;
    r.upper = aabb.upper / p;

    return r;
}

operator == :: (a: BoundingPoints, b: BoundingPoints) -> bool {
    return a.lower == b.lower && a.upper == b.upper;
}

#scope_file

#import "Math";