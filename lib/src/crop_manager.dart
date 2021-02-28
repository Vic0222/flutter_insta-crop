import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as imagelib;

class CropManager {
  Image image;
  double scale;
  double horizontalPan;
  double verticalPan;
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
    this.maxPan = 0,
  });

  Rect getDestinationRect() {
    if (image == null) {
      return Rect.zero;
    }
    return Rect.fromLTWH(
      horizontalPan * image.width * scale * horizontalRatio,
      verticalPan * image.height * scale * verticalRatio,
      image.width.toDouble() * scale * horizontalRatio,
      image.height.toDouble() * scale * verticalRatio,
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
  double get clampHorizantalPan => horizontalPan.clamp(minPan, maxPan);
  double get clampVerticalPan => verticalPan.clamp(minPan, maxPan);

  Future<Uint8List> crop(Size widgetSize) async {
    if (image != null) {
      var data = await image.toByteData(format: ImageByteFormat.png);
      var encodedImage = imagelib.decodePng(data.buffer.asUint8List());
      var cropedImage = imagelib.copyCrop(
          encodedImage,
          cropLeft.toInt(),
          cropTop.toInt(),
          cropWidth(widgetSize.width).toInt(),
          cropHeight(widgetSize.height).toInt());

      return imagelib.encodePng(cropedImage);
    }
  }

  double cropHeight(double widgetHeight) {
    return widgetHeight / scale / verticalRatio;
  }

  double cropWidth(double widgetWidth) {
    return widgetWidth / scale / horizontalRatio;
  }

  double get cropTop {
    final top = getDestinationRect().top / scale / verticalRatio;
    if (top.isFinite) {
      return top * -1;
    } else {
      return 0;
    }
  }

  double get cropLeft {
    final left = getDestinationRect().left / scale / horizontalRatio;
    if (left.isFinite) {
      return left * -1;
    } else {
      return 0;
    }
  }
}
