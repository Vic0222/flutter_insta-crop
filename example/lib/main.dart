import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_insta_crop/flutter_insta_crop.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List croppedImage;

  final _cropperKey = GlobalKey<CropperState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            //give the widget a size
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
              child: Cropper(
                key: _cropperKey,
                imageProvider: NetworkImage(
                    "https://picsum.photos/1024/1024"), //provide an image
              ),
            ),
            RaisedButton(
              onPressed: () => _cropAndSaveToFile(context),
              child: Text("Crop"),
            ),
            //display the croped image
            croppedImage != null
                ? SizedBox(
                    height: 200,
                    width: 200,
                    child: FittedBox(
                      child: Image.memory(croppedImage),
                      fit: BoxFit.contain,
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  ///crop and save image to gallery using image_gallery_saver
  Future<void> _cropAndSaveToFile(BuildContext context) async {
    var image = await _cropperKey.currentState.crop();
    setState(() {
      croppedImage = image;
    });
    await ImageGallerySaver.saveImage(image,
        name: "crop image" + DateTime.now().millisecondsSinceEpoch.toString());
  }
}
