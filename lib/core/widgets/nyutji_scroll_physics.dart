import 'package:flutter/material.dart';

class NyutjiScrollPhysics extends BouncingScrollPhysics {
  const NyutjiScrollPhysics({super.parent});

  @override
  NyutjiScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NyutjiScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Clamp at the top (meniru ClampingScrollPhysics)
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      // underscroll at top
      return value - position.pixels;
    }
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) {
      // hit top edge
      return value - position.minScrollExtent;
    }
    
    // Bouncing at the bottom
    return 0.0;
  }
}
