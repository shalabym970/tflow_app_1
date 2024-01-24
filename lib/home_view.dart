import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:tflow_app_1/main.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isWorking = false;
  String result = "";
  CameraController? cameraController;
  CameraImage? imgCamera;

  loadModel() async {
    await Tflite.loadModel(
        model: 'assets/mobilenet.tflite', labels: 'assets/mobilenet.txt');
  }

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

  void initCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.high);
    cameraController?.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController?.startImageStream((image) => {
              if (!isWorking)
                {isWorking = true, imgCamera = image, runModelOnStreamFrames()}
            });
      });
    });
  }

  runModelOnStreamFrames() async {
    if (imgCamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: imgCamera!.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: imgCamera!.height,
          imageWidth: imgCamera!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      result = "";

      recognitions?.forEach((response) {
        result += response['label'] +
            "  " +
            (response["confidence"] as double).toStringAsFixed(2) +
            "\n\n";
      });

      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Container(
      decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/jarvis.jpg"))),
      child: Column(
        children: [
          Stack(
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
                  onPressed: () {
                    initCamera();
                  },
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
              )
            ],
          ),
          Center(
            child: Container(
                margin: const EdgeInsets.only(top: 55.0),
                child: SingleChildScrollView(
                  child: Text(
                    result,
                    style: const TextStyle(
                        backgroundColor: Colors.black87,
                        fontSize: 30,
                        color: Colors.white),
                    textAlign: TextAlign.center ,
                  ),
                )),
          )
        ],
      ),
    )));
  }
}
