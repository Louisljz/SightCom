import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  await dotenv.load(fileName: "apiKeys.env");

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

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

  FlutterTts flutterTts = FlutterTts();
  String display = '';

  SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  String transcript = '';

  bool isBusy = false;

  void _initSpeech() async {
    speechEnabled = await speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await speechToText.stop();
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));

    isBusy = true;
    switch (transcript.toLowerCase()) {
      case 'describe':
        {
          speak('describe');
          await describeScene();
        }

      case 'text':
        {
          speak('text');
          await recognizeText();
        }

      case 'product':
        {
          speak('product');
          await readBarcode();
        }

      case 'color':
        {
          speak('color');
          await detectColor();
        }

      default:
        {
          speak('chatbot');
          await askChatBot(transcript);
        }
    }
    isBusy = false;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      transcript = result.recognizedWords;
    });
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();

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

  Future<void> speak(script) async {
    setState(() {
      display = script;
    });
    await flutterTts.speak(script);
  }

  Future<List<int>> takePicture() async {
    final image = await _controller.takePicture();
    final imageFile = File(image.path);
    List<int> imageBytes = await imageFile.readAsBytes();
    return imageBytes;
  }

  Future<String> barcodeLookup(code) async {
    final barcodeKey = dotenv.env['barcode'];
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://api.barcodelookup.com/v3/products?barcode=$code&key=$barcodeKey'));
    request.headers.addAll({'Accept': 'application/json'});
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse =
          json.decode(await response.stream.bytesToString());
      return jsonResponse['products'][0]['title'];
    } else {
      return 'Information not found';
    }
  }

  Future<dynamic> sendClarifaiRequest(content, workflowId) async {
    final clarifaiKey = dotenv.env['clarifai'];
    var headers = {
      'Authorization': 'Key $clarifaiKey',
      'Content-Type': 'application/json'
    };
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://api.clarifai.com/v2/users/louisljz/apps/sightcom-api/workflows/$workflowId/results'));
    Map body;
    if (workflowId == 'chatbot') {
      body = 
        {
          "inputs": [
            {
              "data": {
                "text": {
                  "raw": '''<s>
                  <<SYS>> You are a virtual assistant. Your response must be below 50 words. <</SYS>>
                  [INST] $content [/INST]'''
                }
              }
            }
          ]
        };
    } else {
      body = 
        {
          "inputs": [
            {
              "data": {
                "image": {"base64": content}
              }
            }
          ]
        };
    }
    request.body = json.encode(body);
    request.headers.addAll(headers);

    speak('loading');
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final jsonString = await response.stream.bytesToString();
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap['results'][0]['outputs'][0]['data'];
    } else {
      return 'clarifai request failed';
    }
  }

  Future<void> describeScene() async {
    final imageBytes = await takePicture();
    final response = await sendClarifaiRequest(imageBytes, 'image-to-text');
    if (response is Map<String, dynamic>) {
      final description =
          response['text']['raw'];

      speak(description);
    } else {
      speak(response);
    }
  }

  Future<void> recognizeText() async {
    final imageBytes = await takePicture();
    final response = await sendClarifaiRequest(imageBytes, 'text-recognition');
    if (response is Map<String, dynamic>) {
      final results = response['regions'];
      if (results != null) {
        String recognizedText = results
            .map((region) {
              return region['data']['text']['raw'];
            })
            .join(' ')
            .toLowerCase();

        speak(recognizedText);
      } else {
        speak('no text detected');
      }
    } else {
      speak(response);
    }
  }

  Future<void> readBarcode() async {
    final imageBytes = await takePicture();
    final response =
        await sendClarifaiRequest(imageBytes, 'barcode-recognition');
    if (response is Map<String, dynamic>) {
      final results = response['regions'];
      if (results != null) {
        int noOfBarcodes = results.length;
        if (noOfBarcodes > 1) {
          speak('$noOfBarcodes barcodes detected');
          List<String> descriptions = [];
          for (int i = 0; i < noOfBarcodes; i++) {
            final code = results[i]['data']['text']['raw'];
            final productDesc = await barcodeLookup(code);
            int number = i + 1;
            descriptions.add('Barcode $number. $productDesc');
          }
          speak(descriptions.join('; '));
        } else {
          final code = results[0]['data']['text']['raw'];
          final productDesc = await barcodeLookup(code);
          speak(productDesc);
        }
      } else {
        speak('no barcode detected');
      }
    } else {
      speak(response);
    }
  }

  Future<void> detectColor() async {
    final imageBytes = await takePicture();
    final response = await sendClarifaiRequest(imageBytes, 'color-recognition');
    if (response is Map<String, dynamic>) {
      final color = response['colors'][0]
          ['w3c']['name'];

      speak(color);
    } else {
      speak(response);
    }
  }

  Future<void> askChatBot(prompt) async {
    final response = await sendClarifaiRequest(prompt, 'chatbot');
    if (response is Map<String, dynamic>) {
      final answer = response['text']['raw'];
      speak(answer);
    } else {
      speak(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SightCom Blind Accessibility')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Center(child: CameraPreview(_controller));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              display,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isBusy == false) {
            if (speechToText.isNotListening) {
              _startListening();
            } else {
              _stopListening();
            }
          }
        },
        child: Icon(isBusy
            ? Icons.do_not_disturb
            : speechToText.isNotListening
                ? Icons.mic_off
                : Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
