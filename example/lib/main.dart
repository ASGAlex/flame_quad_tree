import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_quad_tree/flame_quad_tree.dart';
import 'package:flame_quad_tree_example/brick.dart';
import 'package:flame_quad_tree_example/player.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame_tiled_utils/flame_tiled_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiled/tiled.dart';

import 'static_layer.dart';

void main(List<String> args) async {
  final game = TestGameQuadTree();
  runApp(GameWidget(game: game));
}

class TestGameStandard extends BaseGame with HasCollisionDetection {
  TestGameStandard();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final tiledComponent =
        await TiledComponent.load('collisions.tmx', Vector2.all(8));

    _initStaticMap(tiledComponent);

    await TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'brick': ((tile, position, size) async {
            final sprite = await tile.getSprite();
            final brick = BrickStandard(
                position: position, size: size, priority: 2, sprite: sprite);
            add(brick);
            staticLayer.components.add(brick);
          }),
        },
        layersToLoad: [
          'bricks',
        ]);

    staticLayer.reRender();
    camera.viewport = FixedResolutionViewport(Vector2(500, 250));
    final playerPoint =
        tiledComponent.tileMap.getLayer<ObjectGroup>('objects')?.objects.first;

    if (playerPoint != null) {
      final position = Vector2(playerPoint.x, playerPoint.y);
      final player =
          PlayerStandard(position: position, size: Vector2.all(8), priority: 2);
      add(player);
      this.player = player;
      camera.followComponent(player);
    }

    add(LayerComponent(staticLayer));
    add(FpsTextComponent());
    camera.zoom = 1;
  }

  final ems = <double>[];

  @override
  void update(double dt) {
    final sw = Stopwatch()..start();
    super.update(dt);
    sw.stop();
    ems.add(sw.elapsedMicroseconds.toDouble());
    print(
        "updateTree: ${(ems.reduce((value, element) => value + element) / ems.length)}, length: ${ems.length}");
  }
}

class TestGameQuadTree extends BaseGame with HasQuadTreeCollisionDetection {
  TestGameQuadTree();

  @override
  double? get minimumDistance => 10;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final tiledComponent =
        await TiledComponent.load('collisions.tmx', Vector2.all(8));

    _initStaticMap(tiledComponent);

    final mapWidth = (tiledComponent.tileMap.map.width *
            tiledComponent.tileMap.map.tileWidth)
        .toDouble();
    final mapHeight = (tiledComponent.tileMap.map.height *
            tiledComponent.tileMap.map.tileHeight)
        .toDouble();
    initCollisionDetection(Rect.fromLTWH(0, 0, mapWidth, mapHeight));

    await TileProcessor.processTileType(
        tileMap: tiledComponent.tileMap,
        processorByType: <String, TileProcessorFunc>{
          'brick': ((tile, position, size) async {
            final sprite = await tile.getSprite();
            final brick = BrickQuadTree(
                position: position, size: size, priority: 2, sprite: sprite);
            add(brick);
            staticLayer.components.add(brick);
          }),
        },
        layersToLoad: [
          'bricks',
        ]);

    staticLayer.reRender();
    camera.viewport = FixedResolutionViewport(Vector2(500, 250));
    final playerPoint =
        tiledComponent.tileMap.getLayer<ObjectGroup>('objects')?.objects.first;

    if (playerPoint != null) {
      final position = Vector2(playerPoint.x, playerPoint.y);
      final player =
          PlayerQuadTree(position: position, size: Vector2.all(8), priority: 2);
      add(player);
      this.player = player;
      camera.followComponent(player);
    }

    add(LayerComponent(staticLayer));
    add(FpsTextComponent());
    camera.zoom = 1;
  }

  final ems = <double>[];

  @override
  void update(double dt) {
    final sw = Stopwatch()..start();
    super.update(dt);
    sw.stop();
    ems.add(sw.elapsedMicroseconds.toDouble());
    print(
        "updateTree: ${(ems.reduce((value, element) => value + element) / ems.length)}, length: ${ems.length}");
  }
}

class BaseGame extends FlameGame with KeyboardEvents, ScrollDetector {
  late Player player;
  final staticLayer = StaticLayer();
  bool firstRender = true;

  _initStaticMap(TiledComponent tiledComponent) async {
    final imageCompiler = ImageBatchCompiler();
    // Adding separate ground layer
    final ground = await imageCompiler.compileMapLayer(
        tileMap: tiledComponent.tileMap, layerNames: ['ground']);
    ground.priority = -1;
    add(ground);
  }

  @override
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    for (final key in keysPressed) {
      if (key == LogicalKeyboardKey.keyW && player.canMoveTop) {
        player.position = player.position.translate(0, -8);
      }
      if (key == LogicalKeyboardKey.keyA && player.canMoveLeft) {
        player.position = player.position.translate(-8, 0);
      }
      if (key == LogicalKeyboardKey.keyS && player.canMoveBottom) {
        player.position = player.position.translate(0, 8);
      }
      if (key == LogicalKeyboardKey.keyD && player.canMoveRight) {
        player.position = player.position.translate(8, 0);
      }
    }

    return KeyEventResult.handled;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    camera.zoom += info.scrollDelta.game.y.sign * 0.08;
    camera.zoom = camera.zoom.clamp(0.05, 5.0);
  }
}

extension Vector2Ext on Vector2 {
  Vector2 translate(double x, double y) {
    return Vector2(this.x + x, this.y + y);
  }
}
