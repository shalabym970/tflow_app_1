import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:tflow_app_1/main.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isWorking = false;
  String result = "";
  late CameraController cameraController;
  late CameraImage imgCamera;

  @override
  void initState() {
    super.initState();
    cameraController = CameraController(cameras![0], ResolutionPreset.high);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController.startImageStream((image) => {
              if (!isWorking) {isWorking = true, imgCamera = image}
            });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
