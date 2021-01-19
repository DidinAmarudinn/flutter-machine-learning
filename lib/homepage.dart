import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ml/helper/loadimage.dart';
import 'package:flutter_ml/widget/bottom_sheet.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tflite/tflite.dart';

class ClassifierPage extends StatefulWidget {
  @override
  _ClassifierPageState createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  CameraController _controller;
  LoadImageClass _loadImage;
  String label;
  String confidence;
  @override
  void initState() {
    super.initState();
    initCamera();
    _loadImage = LoadImageClass();
    loadModel();
  }

  @override
  void dispose() {
    Tflite.close();
    _controller.dispose();
    super.dispose();
  }

  void initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    onNewCameraSelected(firstCamera);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_controller.value.hasError) {
        print('Camera Error');
      }
    });

    try {
      await _controller.initialize();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: CameraPreview(_controller),
                ),
              ),
            ),
            Ink(
              width: 100,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[500],
                    offset: Offset(4.0, 4.0),
                    blurRadius: 15.0,
                    spreadRadius: 1.0,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-4.0, -4.0),
                    blurRadius: 15.0,
                    spreadRadius: 1.0,
                  )
                ],
              ),
              child: IconButton(
                iconSize: 50.0,
                onPressed: () {
                  _runModel(context);
                },
                icon: Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _runModel(context) async {
    try {
      if (_controller == null || !_controller.value.isInitialized) {
        return;
      }

      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      await _controller.takePicture(path);

      var loadImage = await _loadImage.loadImage(path);
      await imageClassification(path);
      showModalBottomSheetResult(context, loadImage, label, confidence);
    } catch (e) {
      print(e);
    }
  }

  Future loadModel() async {
    Tflite.close();
    String res;
    res = await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
    print(res);
  }

  Future imageClassification(String image) async {
    // Run tensorflowlite image classification model on the image
    final List results = await Tflite.runModelOnImage(
      path: image,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      label = results[0]['label'];
      confidence = results[0]['confidence'].toString();
      print(results[0]);
    });
  }
}
