import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'main.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({
    super.key,
  });

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraImage? imgCamera;
  bool isWorking = false;
  String result = "";
  CameraController? cameraController;

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  Future<void> initCamera() async {
    try {
      if (cameras.isEmpty) {
        print('No camera is found');
        return;
      }
      cameraController = CameraController(cameras[0], ResolutionPreset.high);
      await cameraController!.initialize();
      if (mounted) {
        setState(() {
          cameraController!.startImageStream((image) {
            if (!isWorking) {
              isWorking = true;
              imgCamera = image;
              runModelOnStreamFrames();
            }
          });
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing camera: $e");
      }
    }
  }

  runModelOnStreamFrames() async {
    if (imgCamera != null) {
      List<dynamic>? recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: imgCamera!.height,
        imageWidth: imgCamera!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.9,
        asynch: true,
      );
      if (mounted) {
        setState(() {
          if (recognitions != null && recognitions.isNotEmpty) {
            double confidence = recognitions.first["confidence"];
            String label = recognitions.first['label'];

            if (confidence >= 0.999) {
              Uint8List bytes = concatenatePlanes(imgCamera!.planes);

              if (kDebugMode) {
                print(
                    " =============== Reflection Power: ${bytes.toString()} ==========");
              }

              result =
                  "Object : $label  confidence :${confidence.toStringAsFixed(2)}";
            }
          } else {
            result = "";
          }

          isWorking = false;
        });
      }
    }
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    List<Uint8List> bytesList = planes.map((plane) => plane.bytes).toList();
    return Uint8List.fromList(bytesList.expand((list) => list).toList());
  }

  // Future<void> closeCamera() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: CameraPreview(cameraController!)),
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 55.0),
              child: SingleChildScrollView(
                child: Text(
                  result,
                  style: const TextStyle(
                    backgroundColor: Colors.black87,
                    fontSize: 30,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: ElevatedButton(
                onPressed: () async {
                  result = "";
                  isWorking = false; // Re
                  Navigator.pop(context);
                  await cameraController?.stopImageStream();
                  await Tflite.close();
                  await cameraController?.dispose();

                  cameraController = null;
                  imgCamera = null;
                },
                child: const Text("Close Camera"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
