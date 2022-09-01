import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

import '../collision_detection.dart';
import 'collision_controller.dart';

mixin HasQuadTreeCollisionDetection on FlameGame
    implements HasCollisionDetection {
  CollisionDetection<ShapeHitbox>? _collisionDetection;

  @override
  CollisionDetection<ShapeHitbox> get collisionDetection =>
      _collisionDetection!;

  final _scheduledUpdate = <ShapeHitbox>{};

  @override
  set collisionDetection(CollisionDetection<Hitbox> cd) {
    if (cd is! QuadTreeCollisionDetection) {
      throw 'Must be QuadTreeCollisionDetection!';
    }
    _collisionDetection = cd;
  }

  initCollisionDetection(Rect mapDimensions) {
    _collisionDetection = QuadTreeCollisionDetection(mapDimensions);
    (collisionDetection as QuadTreeCollisionDetection)
        .quadBroadphase
        .broadphaseCheck = broadPhaseCheck;
    (collisionDetection as QuadTreeCollisionDetection)
        .quadBroadphase
        .minimumDistanceCheck = minimumDistanceCheck;
  }

  double? minimumDistance;

  bool minimumDistanceCheck(Vector2 activeItemCenter, Vector2 potentialCenter) {
    if (minimumDistance != null) {
      if ((activeItemCenter.x - potentialCenter.x).abs() > minimumDistance! ||
          (activeItemCenter.y - potentialCenter.y).abs() > minimumDistance!) {
        return false;
      } else {
        return true;
      }
    }
    return true;
  }

  bool broadPhaseCheck(PositionComponent one, PositionComponent another) {
    bool checkParent = false;
    if (one is CollisionQuadTreeController) {
      if (!(one).broadPhaseCheck(another)) {
        return false;
      }
    } else {
      checkParent = true;
    }

    if (another is CollisionQuadTreeController) {
      if (!(another).broadPhaseCheck(one)) {
        return false;
      }
    } else {
      checkParent = true;
    }

    if (checkParent &&
        one.parent is CollisionQuadTreeController &&
        another.parent is CollisionQuadTreeController) {
      return broadPhaseCheck(
          one.parent as PositionComponent, another.parent as PositionComponent);
    }
    return true;
  }

  scheduleHitboxUpdate(ShapeHitbox hitbox) {
    _scheduledUpdate.add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_scheduledUpdate.isNotEmpty) {
      for (final hb in _scheduledUpdate) {
        (collisionDetection as QuadTreeCollisionDetection)
            .quadBroadphase
            .updateItemSizeOrPosition(hb);
      }
      _scheduledUpdate.clear();
    }
    collisionDetection.run();
  }
}
