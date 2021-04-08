import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'crop_manager.dart';

class Cropper extends StatefulWidget {
  const Cropper({Key key, @required this.imageProvider, @required this.size})
      : super(key: key);

  final ImageProvider imageProvider;
  final Size size;

  @override
  CropperState createState() => CropperState();
}

class CropperState extends State<Cropper> with TickerProviderStateMixin, Drag {
  ImageStream _imageStream;
  ImageStreamListener _imageListener;

  Tween<double> _scaleTween;
  Tween<double> _horizontalPanTween;
  Tween<double> _verticalPanTween;

  AnimationController _settleController;

  double _startScale;

  ui.Offset _lastFocalPoint;

  double _startHorizontalPan;

  double _startVerticalPan;

  Size get _boundaries {
    return widget.size;
  }

  CropManager _cropManager;

  @override
  void initState() {
    super.initState();
    _lastFocalPoint = Offset.zero;
    _settleController = AnimationController(vsync: this)
      ..addListener(_scaleAnimationChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getImage();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: CropPainter(
                _cropManager,
                _cropManager?.image,
                _cropManager?.scale,
                _cropManager?.horizontalPan,
                _cropManager?.verticalPan,
                _cropManager?.verticalRatio,
              ),
            )),
      ),
    );
  }

  void _getImage({bool force: false}) {
    final oldImageStream = _imageStream;
    _imageStream =
        widget.imageProvider.resolve(createLocalImageConfiguration(context));
    if (_imageStream.key != oldImageStream?.key || force) {
      oldImageStream?.removeListener(_imageListener);
      _imageListener = ImageStreamListener(_updateImage);
      _imageStream.addListener(_imageListener);
    }
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      var horizontalRatio = _boundaries.width / imageInfo.image.width;
      var verticalRatio = _boundaries.height / imageInfo.image.height;
      var ratio = max(horizontalRatio, verticalRatio);

      _cropManager = CropManager(
        image: imageInfo.image,
        scale: imageInfo.scale,
        horizontalRatio: horizontalRatio,
        verticalRatio: verticalRatio,
        maxRatio: ratio,
      );
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

  void _scaleAnimationChanged() {
    setState(() {
      _cropManager.scale = _scaleTween?.transform(_settleController.value) ?? 1;
      _cropManager.horizontalPan =
          _horizontalPanTween?.transform(_settleController.value) ?? 0;
      _cropManager.verticalPan =
          _verticalPanTween?.transform(_settleController.value) ?? 0;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _settleController.stop(canceled: false);
    _startScale = _cropManager.scale;
    _lastFocalPoint = details.focalPoint;
    _startHorizontalPan = _cropManager.horizontalPan;
    _startVerticalPan = _cropManager.verticalPan;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.scale == 1) {
        final delta = details.focalPoint - _lastFocalPoint;
        _lastFocalPoint = details.focalPoint;

        _cropManager.addVerticalPan(delta.dy);
        _cropManager.addHorizontalPan(delta.dx);
      } else {
        _cropManager.updateScale(_startScale * details.scale);

        final dx = _boundaries.width *
            (1.0 - details.scale) /
            (_cropManager.image.width *
                _cropManager.scale *
                _cropManager.maxRatio);
        final dy = _boundaries.height *
            (1.0 - details.scale) /
            (_cropManager.image.height *
                _cropManager.scale *
                _cropManager.maxRatio);

        _cropManager.horizontalPan = _startHorizontalPan + dx / 2;
        _cropManager.verticalPan = _startVerticalPan + dy / 2;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    final targetScale = _cropManager.clampScale;
    _scaleTween = Tween<double>(
      begin: _cropManager.scale,
      end: targetScale,
    );

    _horizontalPanTween = Tween<double>(
      begin: _cropManager.horizontalPan,
      end: _cropManager.clampHorizantalPan,
    );

    _verticalPanTween = Tween<double>(
      begin: _cropManager.verticalPan,
      end: _cropManager.clampVerticalPan,
    );

    _settleController.value = 0.0;
    _settleController.animateTo(
      1.0,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 350),
    );
  }

  Future<Uint8List> crop() async {
    return _cropManager.crop(context.size);
  }
}

class CropPainter extends CustomPainter {
  final CropManager cropManager;
  final ui.Image image;
  final double scale;
  final double horizontalPan;
  final double verticalPan;
  final double ratio;
  CropPainter(
    this.cropManager,
    this.image,
    this.scale,
    this.horizontalPan,
    this.verticalPan,
    this.ratio,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;

    if (cropManager?.image != null) {
      final src = cropManager.getSourceRect();
      final dst = cropManager.getDestinationRect();
      canvas.drawImageRect(cropManager.image, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CropPainter oldDelegate) {
    // TODO: implement shouldRepaint

    return image != oldDelegate.image ||
        scale != oldDelegate.scale ||
        horizontalPan != oldDelegate.horizontalPan ||
        verticalPan != oldDelegate.verticalPan ||
        ratio != oldDelegate.ratio;
  }
}
