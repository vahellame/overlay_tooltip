import 'package:flutter/material.dart';

extension GlobalKeyEx on GlobalKey {
  Rect? get globalPaintBounds {
    try {
      final renderObject = currentContext?.findRenderObject();
      if (renderObject?.attached ?? false) {
        var translation = renderObject?.getTransformTo(null).getTranslation();
        if (translation != null && renderObject?.paintBounds != null) {
          return renderObject!.paintBounds.shift(Offset(translation.x, translation.y));
        }
      }
    } catch (_) {}

    return null;
  }
}
