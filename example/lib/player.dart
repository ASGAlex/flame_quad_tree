import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_quad_tree/flame_quad_tree.dart';

import 'main.dart';

class PlayerQuadTree extends Player
    with CollisionQuadTreeController<TestGameQuadTree> {
  PlayerQuadTree(
      {required super.position, required super.size, required super.priority})
      : super();
}

class PlayerStandard extends Player {
  PlayerStandard(
      {required super.position, required super.size, required super.priority})
      : super();
}

abstract class Player extends SpriteComponent
    with CollisionCallbacks, HasGameRef<TestGameQuadTree> {
  Player(
      {required super.position, required super.size, required super.priority}) {
    Sprite.load('brick_tiles.png',
            srcSize: Vector2.all(8), srcPosition: Vector2(24, 8))
        .then((value) {
      sprite = value;
    });

    add(RectangleHitbox());
  }

  bool canMoveLeft = true;
  bool canMoveRight = true;
  bool canMoveTop = true;
  bool canMoveBottom = true;

  @override
  onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    final diffX = position.x - other.x;
    if (diffX < 0) {
      canMoveRight = false;
    } else if (diffX > 0) {
      canMoveLeft = false;
    }

    final diffY = position.y - other.y;
    if (diffY < 0) {
      canMoveBottom = false;
    } else if (diffY > 0) {
      canMoveTop = false;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  onCollisionEnd(PositionComponent other) {
    canMoveLeft = true;
    canMoveRight = true;
    canMoveTop = true;
    canMoveBottom = true;
    super.onCollisionEnd(other);
  }
}
