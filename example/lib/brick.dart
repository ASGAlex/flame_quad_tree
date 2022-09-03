import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_quad_tree/flame_quad_tree.dart';

import 'main.dart';

class BrickQuadTree extends Brick
    with CollisionQuadTreeController<TestGameQuadTree>, UpdateOnce {
  BrickQuadTree(
      {required super.position,
      required super.size,
      required super.priority,
      required super.sprite});
}

class BrickStandard extends Brick with UpdateOnce {
  BrickStandard(
      {required super.position,
      required super.size,
      required super.priority,
      required super.sprite});
}

abstract class Brick extends SpriteComponent with CollisionCallbacks {
  Brick(
      {required super.position,
      required super.size,
      required super.priority,
      required super.sprite}) {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  bool rendered = false;

  @override
  void renderTree(Canvas canvas) {
    if (!rendered) {
      super.renderTree(canvas);
    }
  }
}

mixin UpdateOnce on Brick {
  bool updateOnce = true;

  @override
  void updateTree(double dt) {
    if (updateOnce) {
      super.updateTree(dt);
      updateOnce = false;
    }
  }
}
