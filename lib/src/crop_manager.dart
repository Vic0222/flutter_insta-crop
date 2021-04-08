import 'dart:typed_data';
import 'dart:ui';
import 'dart:math';

import 'package:image/image.dart' as imagelib;

class CropManager {
  Image image;
  double scale;
  double horizontalPan;
  double verticalPan;
  double maxRatio;
  double verticalRatio;
  double horizontalRatio;

  final double minScale;
  final double maxScale;
  double maxPan;

  CropManager({
    this.image,
    this.scale = 1,
    this.minScale = 1,
    this.maxScale = 2,
    this.horizontalPan = 0,
    this.verticalPan = 0,
    this.verticalRatio = 1,
    this.horizontalRatio = 1,
    this.maxRatio = 1,
    this.maxPan = 0,
  });

  Rect getDestinationRect() {
    if (image == null) {
      return Rect.zero;
    }

    return Rect.fromLTWH(
      horizontalPan * image.width * scale * maxRatio,
      verticalPan * image.height * scale * maxRatio,
      image.width.toDouble() * scale * maxRatio,
      image.height.toDouble() * scale * maxRatio,
    );
  }

  Rect getSourceRect() {
    if (image == null) {
      return Rect.zero;
    }
    return Rect.fromLTWH(
      0.0,
      0.0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
  }

  void addVerticalPan(double deltaY) {
    if (image != null) {
      verticalPan += deltaY / (image.height * scale * verticalRatio);
    }
  }

  void addHorizontalPan(double deltaX) {
    if (image != null) {
      horizontalPan += deltaX / (image.width * scale * horizontalRatio);
    }
  }

  void updateScale(double newScale) {
    scale = newScale;
  }

  double get clampScale => scale.clamp(minScale, maxScale);
  double get minPan => (1 / clampScale) - 1;
  double get clampHorizantalPan {
    double pan = minPan;
    if (image.width > image.height) {
      double toSubtract = image.height / image.width / clampScale;
      pan = toSubtract - 1;
    }
    return horizontalPan.clamp(pan, maxPan);
  }

  double get clampVerticalPan {
    double pan = minPan;
    if (image.height > image.width) {
      double toSubtract = image.width / image.height / clampScale;
      pan = toSubtract - 1;
    }

    return verticalPan.clamp(pan, maxPan);
  }

  Future<Uint8List> crop(Size widgetSize) async {
    Uint8List ret;
    if (image != null) {
      var data = await image.toByteData(format: ImageByteFormat.png);
      var encodedImage = imagelib.decodePng(data.buffer.asUint8List());
      var cropedImage = imagelib.copyCrop(
          encodedImage,
          cropLeft.toInt(),
          cropTop.toInt(),
          cropWidth(widgetSize.width).toInt(),
          cropHeight(widgetSize.height).toInt());

      ret = imagelib.encodePng(cropedImage);
    }
    return ret;
  }

  double cropHeight(double widgetHeight) {
    return widgetHeight / scale / maxRatio;
  }

  double cropWidth(double widgetWidth) {
    return widgetWidth / scale / maxRatio;
  }

  double get cropTop {
    final top = getDestinationRect().top / scale / maxRatio;
    if (top.isFinite) {
      return top * -1;
    } else {
      return 0;
    }
  }

  double get cropLeft {
    final left = getDestinationRect().left / scale / maxRatio;
    if (left.isFinite) {
      return left * -1;
    } else {
      return 0;
    }
  }
}
