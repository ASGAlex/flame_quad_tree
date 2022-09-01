import 'dart:collection';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../quad_tree.dart';

typedef ExternalBroadphaseCheck = bool Function(
    PositionComponent one, PositionComponent another);

typedef ExternalMinDistanceCheck = bool Function(
    Vector2 activeItemCenter, Vector2 potentialCenter);

class QuadTreeBroadphase<T extends Hitbox<T>> extends Broadphase<T> {
  QuadTreeBroadphase({super.items});

  final tree = QuadTree<T>();

  final activeCollisions = HashSet<T>();

  ExternalBroadphaseCheck? broadphaseCheck;
  ExternalMinDistanceCheck? minimumDistanceCheck;
  final _broadphaseCheckCache = <T, Map<T, bool>>{};

  final Map _cachedCenters = <ShapeHitbox, Vector2>{};

  final potentials = HashSet<CollisionProspect<T>>();
  final potentialsTmp = <List<T>>[];

  @override
  HashSet<CollisionProspect<T>> query() {
    potentials.clear();
    potentialsTmp.clear();

    for (final activeItem in activeCollisions) {
      final asShapeItem = (activeItem as ShapeHitbox);

      if (asShapeItem.isRemoving || asShapeItem.parent == null) {
        tree.remove(activeItem);
        continue;
      }

      final itemCenter = activeItem.aabb.center;
      final markRemove = <T>[];
      final potentiallyCollide = tree.query(activeItem);
      for (final potential in potentiallyCollide.entries.first.value) {
        if (potential.collisionType == CollisionType.inactive) {
          continue;
        }

        if (_broadphaseCheckCache[activeItem]?[potential] == false) {
          continue;
        }

        final asShapePotential = (potential as ShapeHitbox);

        if (asShapePotential.isRemoving || asShapePotential.parent == null) {
          markRemove.add(potential);
          continue;
        }
        if (asShapePotential.parent == asShapeItem.parent &&
            asShapeItem.parent != null) {
          continue;
        }

        Vector2 potentialCenter;
        if (potential.collisionType == CollisionType.passive) {
          potentialCenter = _getCenterOfHitbox(asShapePotential);
        } else {
          potentialCenter = potential.aabb.center;
        }

        final distanceCloseEnough =
            minimumDistanceCheck?.call(itemCenter, potentialCenter);
        if (distanceCloseEnough == false) {
          continue;
        }

        potentialsTmp.add([activeItem, potential]);
      }
      for (final i in markRemove) {
        tree.remove(i);
      }
    }

    if (potentialsTmp.isNotEmpty && broadphaseCheck != null) {
      for (var i = 0; i < potentialsTmp.length; i++) {
        final item0 = potentialsTmp[i].first as PositionComponent;
        final item1 = potentialsTmp[i].last as PositionComponent;
        var keep = broadphaseCheck!(item0, item1);
        if (keep) {
          keep = broadphaseCheck!(item1, item0);
        }
        if (keep) {
          potentials.add(CollisionProspect(item0 as T, item1 as T));
        } else {
          if (_broadphaseCheckCache[item0 as T] == null) {
            _broadphaseCheckCache[item0 as T] = {};
          }
          _broadphaseCheckCache[item0 as T]![item1 as T] = false;
        }
      }
    }
    // print("P: ${potentials.length}");
    return potentials;
  }

  updateItemSizeOrPosition(T item) {
    tree.remove(item, oldPosition: true);
    if (item.collisionType == CollisionType.passive) {
      _getCenterOfHitbox(item as ShapeHitbox);
    }
    tree.add(item);
  }

  add(T hitbox) {
    tree.add(hitbox);
    if (hitbox.collisionType == CollisionType.active) {
      activeCollisions.add(hitbox);
    } else if (hitbox.collisionType == CollisionType.passive) {
      _getCenterOfHitbox(hitbox as ShapeHitbox);
    }
  }

  remove(T item) {
    tree.remove(item);
    if (item.collisionType == CollisionType.active) {
      activeCollisions.remove(item);
    }
  }

  clear() {
    tree.clear();
    activeCollisions.clear();
    _broadphaseCheckCache.clear();
    _cachedCenters.clear();
  }

  Vector2 _getCenterOfHitbox(ShapeHitbox hitbox) {
    var cache = _cachedCenters[hitbox];
    if (cache == null) {
      _cachedCenters[hitbox] = hitbox.aabb.center;
      cache = _cachedCenters[hitbox];
    }
    return cache;
  }
}
