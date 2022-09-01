import 'package:flame/components.dart';
import 'package:flame/layers.dart';
import 'package:flame_quad_tree_example/brick.dart';
import 'package:flutter/material.dart';

class StaticLayer extends PreRenderedLayer {
  StaticLayer();

  List<PositionComponent> components = [];

  @override
  void drawLayer() {
    for (var element in components) {
      if (element is Brick) {
        element.rendered = false;
        element.renderTree(canvas);
        element.rendered = true;
      }
    }
  }
}

class LayerComponent extends PositionComponent {
  LayerComponent(this.layer);

  StaticLayer layer;

  @override
  render(Canvas canvas) {
    layer.render(canvas);
  }
}
