import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera.dart';

class HomeView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeView({Key? key, required this.cameras}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraPreviewScreen(),
                    ),
                  );
                },
                child: Center(
                  child: Container(
                    color: Colors.black,
                    height: 320,
                    width: 360,
                    child: Image.asset('assets/camera.jpg'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
