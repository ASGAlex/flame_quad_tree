import 'package:flame/collisions.dart';
import 'package:flame/extensions.dart';

extension _QuadMethods on Rect {
  bool containsRect(Rect box) =>
      left <= box.left &&
      box.right <= right &&
      top <= box.top &&
      box.bottom <= bottom;

  bool intersects(Rect box) => !(left >= box.right ||
      right <= box.left ||
      top >= box.bottom ||
      bottom <= box.top);
}

class Node<T extends Hitbox<T>> {
  static int nodeLastId = 0;
  final List<Node?> children =
      List.generate(4, (index) => null, growable: false);
  var values = <T>[];

  Node? parent;
  int id = 0;

  List<T> get valuesRecursive {
    final data = <T>[];

    data.addAll(values);
    for (final ch in children) {
      if (ch == null) continue;
      data.addAll(ch.valuesRecursive as List<T>);
    }
    return data;
  }
}

class QuadTree<T extends Hitbox<T>> {
  static const maxObjects = 25;
  static const maxLevels = 10;
  static final _oldPositionByItem = <ShapeHitbox, Aabb2>{};
  static final _itemAtNode = <ShapeHitbox, Node>{};

  var level = 0;

  QuadTree();

  Rect mainBoxSize = Rect.zero;

  var rootNode = Node<T>();

  List<T> get hitboxes => rootNode.valuesRecursive;

  Rect getBoxOfValue(T value) {
    final minOffset = Offset(value.aabb.min.x < 0 ? 0 : value.aabb.min.x,
        value.aabb.min.y < 0 ? 0 : value.aabb.min.y);
    return Rect.fromPoints(minOffset, value.aabb.max.toOffset());
  }

  bool isLeaf(Node node) => node.children[0] == null;

  clear() {
    rootNode = Node<T>();
    Node.nodeLastId = 0;
  }

  Rect computeBox(Rect box, int i) {
    var origin = box.topLeft;
    var childSize = (box.size / 2).toOffset();
    switch (i) {
      case 0:
        // North West
        return Rect.fromLTWH(origin.dx, origin.dy, childSize.dx, childSize.dy);
      // North East
      case 1:
        return Rect.fromLTWH(
            origin.dx + childSize.dx, origin.dy, childSize.dx, childSize.dy);
      // South West
      case 2:
        return Rect.fromLTWH(
            origin.dx, origin.dy + childSize.dy, childSize.dx, childSize.dy);
      // South East
      case 3:
        final position = origin + childSize;
        return Rect.fromLTWH(
            position.dx, position.dy, childSize.dx, childSize.dy);
      default:
        assert(false, "Invalid child index");
        return Rect.zero;
    }
  }

  int getQuadrant(Rect nodeBox, Rect valueBox) {
    var center = nodeBox.center;
    // West
    if (valueBox.right <= center.dx) {
      // North West
      if (valueBox.bottom <= center.dy) {
        return 0;
      } else if (valueBox.top >= center.dy) {
        return 2;
      } else {
        return -1;
      }
    }
    // East
    else if (valueBox.left >= center.dx) {
      // North East
      if (valueBox.bottom <= center.dy) {
        return 1;
      } else if (valueBox.top >= center.dy) {
        return 3;
      } else {
        return -1;
      }
    }
    // Not contained in any quadrant
    else {
      return -1;
    }
  }

  add(T hitbox) {
    final node = _add(rootNode, 0, mainBoxSize, hitbox, null);
    _oldPositionByItem[hitbox as ShapeHitbox] = Aabb2.copy(hitbox.aabb);
    _itemAtNode[hitbox as ShapeHitbox] = node;
  }

  Node<T> _add(Node<T> node, int depth, Rect box, T value, Node? parent) {
    // assert(box.containsRect(getBoxOfValue(value)));
    Node<T> finalNode;
    if (isLeaf(node)) {
      // Insert the value in this node if possible
      if (depth >= maxLevels || node.values.length < maxObjects) {
        node.values.add(value);
        finalNode = node;
      }
      // Otherwise, we split and we try again
      else {
        split(node, box);
        finalNode = _add(node, depth, box, value, parent);
      }
    } else {
      var i = getQuadrant(box, getBoxOfValue(value));
      // Add the value in a child if the value is entirely contained in it
      if (i != -1) {
        final children = node.children[i];
        if (children == null) throw 'Invalid index $i';
        finalNode = _add(
            children as Node<T>, depth + 1, computeBox(box, i), value, node);
      }
      // Otherwise, we add the value in the current node
      else {
        node.values.add(value);
        finalNode = node;
      }
    }
    if (parent != null && finalNode.parent == null) {
      finalNode.parent = parent;
    }
    return finalNode;
  }

  void split(Node node, Rect box) {
    assert(isLeaf(node), "Only leaves can be split");
    // Create children
    for (var i = 0; i < node.children.length; i++) {
      final newId = ++Node.nodeLastId;
      node.children[i] = Node<T>()
        ..parent = node
        ..id = newId;
    }

    // Assign values to children
    var moveValues = <T>[]; // New values for this node
    for (final value in node.values) {
      var i = getQuadrant(box, getBoxOfValue(value as T));
      if (i != -1) {
        final children = node.children[i];
        if (children == null) throw 'Invalid index $i';
        children.values.add(value);
      } else {
        moveValues.add(value);
      }
    }
    node.values = moveValues;
  }

  remove(T hitbox, {bool oldPosition = false}) =>
      _removeFast(hitbox, oldPosition: oldPosition);

  bool _removeFast(T hitbox, {bool oldPosition = false}) {
    final node = _itemAtNode[hitbox];
    if (node == null) {
      return _remove(rootNode, mainBoxSize, hitbox, oldPosition);
    } else {
      return node.values.remove(hitbox);
    }
  }

  bool _remove(Node node, Rect box, T value, bool oldPosition) {
    // assert(box.containsRect(getBoxOfValue(value)));
    if (isLeaf(node)) {
      // Remove the value from node
      removeValue(node, value);
      return true;
    } else {
      // Remove the value in a child if the value is entirely contained in it
      var hitboxToCheck = value;
      if (oldPosition) {
        final lastPos = _oldPositionByItem[value];
        if (lastPos != null) {
          hitboxToCheck = RectangleHitbox(
              position: Vector2(lastPos.min.x, lastPos.min.y),
              size: Vector2(lastPos.max.x - lastPos.min.x,
                  lastPos.max.y - lastPos.min.y)) as T;
        }
      }
      var i = getQuadrant(box, getBoxOfValue(hitboxToCheck));
      if (i != -1) {
        final children = node.children[i];
        if (children == null) throw 'invalid index $i';
        if (_remove(children, computeBox(box, i), value, oldPosition)) {
          return tryMerge(node);
        }
      }
      // Otherwise, we remove the value from the current node
      else {
        removeValue(node, value);
      }
      return false;
    }
  }

  void removeValue(Node node, T value) {
    node.values.removeWhere((element) => element == value);
  }

  bool tryMerge(Node node) {
    assert(!isLeaf(node), "Only interior nodes can be merged");
    var nbValues = node.values.length;
    for (final child in node.children) {
      if (child == null) throw "Child must be not null";
      if (!isLeaf(child)) {
        return false;
      }
      nbValues += child.values.length;
    }
    if (nbValues <= maxLevels) {
      // Merge the values of all the children
      for (final child in node.children) {
        if (child == null) throw "Child must be not null";
        node.values.addAll(child.values);
        child.values.clear();
      }
      return true;
    } else {
      return false;
    }
  }

  Map<int, List<T>> query(T value) => _queryFast(value);

  Map<int, List<T>> _queryFast(T value) {
    final node = _itemAtNode[value as ShapeHitbox];
    var id = -1;
    var values = <T>[];
    if (node == null) {
      _querySlow(rootNode, mainBoxSize, getBoxOfValue(value), values);
    } else {
      id = node.id;
      values.addAll(node.values as List<T>);
      values.addAll(_getChildrenItems(node));
      values.addAll(_getParentItems(node));
    }
    return {id: values};
  }

  List<T> _getChildrenItems(Node parent) {
    final list = <T>[];
    for (final child in parent.children) {
      if (child != null) {
        list.addAll(child.values as List<T>);
        if (child.children[0] != null) {
          list.addAll(_getChildrenItems(child));
        }
      }
    }
    return list;
  }

  List<T> _getParentItems(Node node) {
    final list = <T>[];
    var parent = node.parent;
    if (parent != null) {
      list.addAll(parent.values as List<T>);
      list.addAll(_getParentItems(parent));
    }
    return list;
  }

  void _querySlow(Node node, Rect box, Rect queryBox, List<T> values) {
    // assert(queryBox.intersects(box));
    for (final value in node.values) {
      if (queryBox.intersects(getBoxOfValue(value as T))) {
        values.add(value);
      }
    }
    if (!isLeaf(node)) {
      for (var i = 0; i < node.children.length; ++i) {
        var childBox = computeBox(box, i);
        if (queryBox.intersects(childBox)) {
          final child = node.children[i];
          if (child == null) throw "Child must be not null";

          _querySlow(child, childBox, queryBox, values);
        }
      }
    }
  }

  bool isMoved(T hitbox) {
    final lastPos = _oldPositionByItem[hitbox];
    if (lastPos == null) return true;
    if (lastPos.min == hitbox.aabb.min && lastPos.max == hitbox.aabb.max) {
      return false;
    } else {
      return true;
    }
  }
}
