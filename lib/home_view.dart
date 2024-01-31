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
  Rect? highestConfidenceBoundingBox;

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
      model: 'assets/mobilenet.tflite',
      labels: 'assets/mobilenet.txt',
    );
  }

  Future<void> initCamera() async {
    try {
      cameraController = CameraController(widget.cameras[0], ResolutionPreset.high);
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
      List<dynamic>? newRecognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: imgCamera!.height,
        imageWidth: imgCamera!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.1,
        asynch: true,
      );

      setState(() {
        if (newRecognitions != null && newRecognitions.isNotEmpty) {
          double maxConfidence = 0.0;
          var maxConfidenceRecognition;

          for (var recognition in newRecognitions) {
          if (kDebugMode) {
            print( "========== the item recognited : ${recognition.toString()} ============");
            print("Type of recognition: ${recognition.runtimeType}");
          }
              double confidence = recognition["confidence"];
              if (confidence > maxConfidence) {
                maxConfidence = confidence;
                maxConfidenceRecognition = recognition;
              }

          }

          if (maxConfidenceRecognition != null) {
            // double x = maxConfidenceRecognition["rect"]["x"] *
            //     cameraController!.value.previewSize!.width;
            // double y = maxConfidenceRecognition["rect"]["y"] *
            //     cameraController!.value.previewSize!.height;
            // double w = maxConfidenceRecognition["rect"]["w"] *
            //     cameraController!.value.previewSize!.width;
            // double h = maxConfidenceRecognition["rect"]["h"] *
            //     cameraController!.value.previewSize!.height;
            //
            // highestConfidenceBoundingBox = Rect.fromPoints(
            //   Offset(x, y),
            //   Offset(x + w, y + h),
            // );

            result =
                "${maxConfidenceRecognition['label']}  ${maxConfidenceRecognition['confidence'].toStringAsFixed(2)}";
          } else {
            highestConfidenceBoundingBox = null;
            result = "";
          }
        } else {
          highestConfidenceBoundingBox = null;
          result = "";
        }

        isWorking = false;
      });
    }
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
                boundingBox: highestConfidenceBoundingBox,
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
  final Rect? boundingBox;

  const CameraPreviewWidget({
    Key? key,
    required this.cameraController,
    required this.isWorking,
    required this.initCamera,
    required this.imgCamera,
    required this.boundingBox,
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
          child: TextButton(
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
        ),
        // CustomPaint(
        //   painter: BoundingBoxPainter(boundingBox),
        //   child: const SizedBox(
        //     height: 270,
        //     width: 360,
        //   ),
        // ),
      ],
    );
  }
}

// class BoundingBoxPainter extends CustomPainter {
//   final Rect? boundingBox;
//
//   BoundingBoxPainter(this.boundingBox);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.red
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     if (boundingBox != null) {
//       canvas.drawRect(boundingBox!, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }

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
