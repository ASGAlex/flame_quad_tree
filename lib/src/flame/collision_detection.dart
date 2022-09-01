import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/widgets.dart';

import '../quad_tree.dart';
import 'broadphase.dart';

class QuadTreeCollisionDetection extends StandardCollisionDetection {
  QuadTreeCollisionDetection(Rect mapDimensions)
      : super(broadphase: QuadTreeBroadphase<ShapeHitbox>()) {
    (broadphase as QuadTreeBroadphase).tree.mainBoxSize = mapDimensions;
  }

  QuadTreeBroadphase get quadBroadphase => broadphase as QuadTreeBroadphase;

  @override
  void add(ShapeHitbox item) {
    super.add(item);
    quadBroadphase.add(item);
  }

  @override
  void addAll(Iterable<ShapeHitbox> items) {
    for (final item in items) {
      add(item);
    }
  }

  @override
  void remove(ShapeHitbox item) {
    quadBroadphase.remove(item);
    super.remove(item);
  }

  @override
  void removeAll(Iterable<ShapeHitbox> items) {
    quadBroadphase.clear();
    super.removeAll(items);
  }

  List<BoxesDbgInfo> get collisionQuadBoxes =>
      _getBoxes(quadBroadphase.tree.rootNode, quadBroadphase.tree.mainBoxSize);

  List<BoxesDbgInfo> _getBoxes(Node node, Rect rootBox) {
    final boxes = <BoxesDbgInfo>[];
    final hitboxes = node.values;
    bool hasChildren = node.children[0] != null;
    boxes.add(BoxesDbgInfo(
        rootBox, hitboxes as List<ShapeHitbox>, hitboxes.length, hasChildren));
    if (hasChildren) {
      for (var i = 0; i < node.children.length; i++) {
        boxes.addAll(_getBoxes(node.children[i] as Node<ShapeHitbox>,
            quadBroadphase.tree.computeBox(rootBox, i)));
      }
    }
    return boxes;
  }
}

class BoxesDbgInfo {
  BoxesDbgInfo(this.rect, this.hitboxes, this.count, this.hasChildren);

  Rect rect;
  List<ShapeHitbox> hitboxes;
  int count;
  bool hasChildren;
}
