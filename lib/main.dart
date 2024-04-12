import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String url = 'https://blindbuddy-fastapi.onrender.com/uploadfile';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;


  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late List<CameraDescription> cameras;
  Color _bgColor = Colors.white;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    flutterTts.speak('Hi , you can use the application now , tap to turn on flash light , long press to take a picture , double tap to retake the picture');
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            /// flutterTts.speak('Hi , you can use the application now , tap to turn on flash light , long press to take a picture , double tap to retake the picture');
            // todo : If the Future is complete, display the preview.
            // todo : return a voice message "hi you can use the app now , you can take a picture by long press"
            return Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height - 0.1,
              width: MediaQuery
                  .of(context)
                  .size
                  .width - 0.05,
              child: Center(
                child: GestureDetector(
                  // on tap - start a flash camera
                  onTap: () async {
                    if (_controller.value.isInitialized) {
                      if (_controller.value.flashMode == FlashMode.off) {
                        await _controller.setFlashMode(FlashMode.torch);
                        flutterTts.speak('FlashLight turned on');
                        setState(() {
                          _bgColor = Colors.greenAccent;
                        });
                      } else {
                        await _controller.setFlashMode(FlashMode.off);
                        flutterTts.speak('Flash Light turned off');
                        setState(() {
                          _bgColor = Colors.white;
                        });
                      }
                    }
                  },
                  onLongPress: () async {
                    try {
                      print('long press');
                      flutterTts.speak('We have sent the image now , please wait till it is process');
                      await _initializeControllerFuture;
                      final image = await _controller.takePicture();
                      final imagepath = image.path;
                      var request = http.MultipartRequest('POST', Uri.parse(url));
                      request.files.add(
                          http.MultipartFile(
                              'picture',
                              File(imagepath).readAsBytes().asStream(),
                              File(imagepath).lengthSync(),
                              filename: imagepath.split("/").last
                          )
                      );
                      var response = await request.send();
                      var res = await response.stream.transform(utf8.decoder).join();
                      print('error$res');
                      if (!context.mounted) return;
                      // todo : create api call for this n update in the dummy recieve text
                      //todo : once picture is taken take picture and post it in backend
                      // todo : create a await function that during starting tell "wait till we process " and at end " the taken image is + {json data} using flutterTts.speak($text);.
                      flutterTts.speak('Your picture sent has $res');
                      print('Your picture sent has $res');


                       await Navigator.of(context).push(
                       MaterialPageRoute(
                         builder: (context) => DisplayPictureScreen(
                            // Pass the automatically generated path to
                            // the DisplayPictureScreen widget.
                             imagePath: image.path,
                          ),
                        ),
                      );
                      // todo : the above implementation is just to show you should also have to create an API that pushes image.path
                    } catch (e) {
                      // If an error occurs, log the error to the console.
                      flutterTts.speak('Sorry internal error , kindly retake the picture');
                      print(e);
                    }
                  },
                  child: Container(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height - 0.1,
                    width: MediaQuery
                        .of(context)
                        .size
                        .width - 0.05,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_voice_outlined,
                      color: Colors.black,
                      size: 50,
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final FlutterTts flutterTts = FlutterTts();

  DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery
            .of(context)
            .size
            .height - 0.1,
        width: MediaQuery
            .of(context)
            .size
            .width - 0.05,
        child: Center(
          child: GestureDetector(
            onDoubleTap: (){
              flutterTts.speak('Retaking the picture');
              Navigator.pop(context);
              //print("popping out");
            },
            child: Image.file(File(imagePath)),
            /// todo : you can add styling or other ui needed features here
          ),
        ),
      )
    );
  }
}
