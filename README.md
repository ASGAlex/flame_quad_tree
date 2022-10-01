# Deprecated

Now this library become a part of Flame engine.
See [corresponding documentation section](https://github.com/flame-engine/flame/blob/main/doc/flame/collision_detection.md#quad-tree-broad-phase)
at engine's documentation for actual usage instructions.

## Features

Quad Tree algorithm implementation aimed to be used in Flame

- Fully compatible with vanilla Flame
- Allow to write custom broadphase checks for each type of component
- Manages components automatically bot provide functions for manual control

## Getting started

Configuration process is similar to standard Flame collision detection system setup.

1. Add mixin `HasQuadTreeCollisionDetection` to you game class, extended from FlameGame:

```dart
class TestGameQuadTree extends FlameGame with HasQuadTreeCollisionDetection {}
```

2. Call `initCollisionDetection` function in game's `onLoad` function. Here you should specify a
   rect with you game map dimensions. This information is required to split game space into
   quadrants

```dart
  @override
Future<void> onLoad() async {
  final tiledComponent = await TiledComponent.load('collisions.tmx', Vector2.all(8));

  final mapWidth = (tiledComponent.tileMap.map.width *
      tiledComponent.tileMap.map.tileWidth)
      .toDouble();
  final mapHeight = (tiledComponent.tileMap.map.height *
      tiledComponent.tileMap.map.tileHeight)
      .toDouble();
  initCollisionDetection(Rect.fromLTWH(0, 0, mapWidth, mapHeight));
}
```

3. All game components which need to be involved into collision detection cycle should have two
   mixins:

- Standard Flame's `CollisionCallbacks` to support "onCollision*" functions
- Special `CollisionQuadTreeController` mixin

This is minimal configuration enough for basic functionality

## Additional methods

There are a number of additional methods to make broadphase checks more fast.

### Minimal distance between object's centers

In you FlameGame custom class override `minimumDistance` variable:

```dart

class TestGameQuadTree extends FlameGame with HasQuadTreeCollisionDetection {

  @override
  double? get minimumDistance => 10;
}
```

This will lead to exclude objects from detail expensive collision check if distance between objects
is more than `minimumDistance` variable value.

You also can reimplement `HasQuadTreeCollisionDetection::minimumDistanceCheck` method if you need
more complex logic.

### General check, should objects of several types ever to collide

In you component class reimplement method `broadPhaseCheck`:

```dart
@override
bool broadPhaseCheck(PositionComponent other) {
  if (other is Brick) return false;
  return super.broadPhaseCheck(other);
}
```

IMPORTANT! This check is performed only once for pair of items. If result is negative, it become
cached by `QuadTreeBroadphase` class. So place here only general checks like checking object's type
and so on. If to pass where something very dynamic, you could face unexpected behavior.  

### Manually adding / removing components from collision detection system
