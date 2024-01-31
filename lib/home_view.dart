import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

class HomeView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeView({Key? key, required this.cameras}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isWorking = false;
  String result = "";
  CameraController? cameraController;
  CameraImage? imgCamera;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    cameraController?.dispose();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  Future<void> initCamera() async {
    try {
      cameraController =
          CameraController(widget.cameras[0], ResolutionPreset.high);
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
        threshold: 0.99,
        asynch: true,
      );

      setState(() {
        if (recognitions != null && recognitions.isNotEmpty) {
          double confidence = recognitions.first["confidence"];
          String label = recognitions.first['label'];
          if (kDebugMode) {
            print('=========== confidence : $confidence ========== ');
          }
          if (confidence >= 0.999) {
            result = "$label  ${confidence.toStringAsFixed(2)}";
          }
        } else {
          result = "";
        }

        isWorking = false;
      });
    }
  }

  Future<void> closeCamera() async {
    setState(() {
      imgCamera = null;
    });
    await cameraController?.stopImageStream();
    await cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/jarvis.jpg")),
          ),
          child: Column(
            children: [
              CameraPreviewWidget(
                cameraController: cameraController,
                isWorking: isWorking,
                initCamera: initCamera,
                imgCamera: imgCamera,
                closeCamera: closeCamera,
              ),
              ResultDisplay(result: result),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? cameraController;
  final bool isWorking;
  final VoidCallback initCamera;
  final CameraImage? imgCamera;
  final VoidCallback closeCamera;

  const CameraPreviewWidget({
    Key? key,
    required this.cameraController,
    required this.isWorking,
    required this.initCamera,
    required this.closeCamera,
    required this.imgCamera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            color: Colors.black,
            height: 320,
            width: 360,
            child: Image.asset('assets/camera.jpg'),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: initCamera,
                child: Container(
                  margin: const EdgeInsets.only(top: 35),
                  height: 270,
                  width: 360,
                  child: imgCamera == null
                      ? const SizedBox(
                          height: 270,
                          width: 360,
                          child: Icon(
                            Icons.photo_camera_front,
                            color: Colors.blueAccent,
                            size: 40,
                          ),
                        )
                      : AspectRatio(
                          aspectRatio: cameraController!.value.aspectRatio,
                          child: CameraPreview(cameraController!),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              if (imgCamera != null)
                ElevatedButton(
                  onPressed: closeCamera,
                  child: const Text("Close Camera"),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResultDisplay extends StatelessWidget {
  final String result;

  const ResultDisplay({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
