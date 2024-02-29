import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easy_flutter_barcode_sdk/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';

class Mobile extends StatefulWidget {
  final CameraDescription camera;
  final Function(String) callback;
  final String licenceKey;

  const Mobile({
    super.key,
    required this.camera,
    required this.callback,
    required this.licenceKey,
  });

  @override
  MobileState createState() => MobileState();
}

class MobileState extends State<Mobile> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  FlutterBarcodeSdk? _barcodeReader;
  bool _isScanAvailable = true;
  bool _isScanRunning = false;
  String _barcodeResults = '';
  String _buttonText = 'Start Video Scan';

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller!.initialize().then((_) {
      setState(() {});
    });
    // Initialize Dynamsoft Barcode Reader
    initBarcodeSDK();
  }

  Future<void> initBarcodeSDK() async {
    _barcodeReader = FlutterBarcodeSdk();
    // Get 30-day FREEE trial license from https://www.dynamsoft.com/customer/license/trialLicense?product=dbr
    await _barcodeReader!.setLicense(widget.licenceKey);
    await _barcodeReader!.init();
    await _barcodeReader!.setBarcodeFormats(BarcodeFormat.ALL);
    // Get all current parameters.
    // Refer to: https://www.dynamsoft.com/barcode-reader/parameters/reference/image-parameter/?ver=latest
    String params = await _barcodeReader!.getParameters();
    // Convert parameters to a JSON object.
    dynamic obj = json.decode(params);
    // Modify parameters.
    obj['ImageParameter']['DeblurLevel'] = 5;
    // Update the parameters.
    int ret = await _barcodeReader!.setParameters(json.encode(obj));
    print('Parameter update: $ret');
  }

  void pictureScan() async {
    if (_isScanRunning) stopVideo();
    final image = await _controller!.takePicture();
    List<BarcodeResult> results = await _barcodeReader!.decodeFile(image.path);

    // Uint8List bytes = await image.readAsBytes();
    // List<BarcodeResult> results =
    //     await _barcodeReader.decodeFileBytes(bytes);

    // If the picture was taken, display it on a new screen.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(
            // Pass the automatically generated path to
            // the DisplayPictureScreen widget.
            imagePath: image.path,
            barcodeResults: getBarcodeResults(results)),
      ),
    );
  }

  void startVideo() async {
    setState(() {
      _buttonText = 'Stop Video Scan';
    });
    _isScanRunning = true;
    await _controller!.startImageStream((CameraImage availableImage) async {
      assert(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
      int format = ImagePixelFormat.IPF_NV21.index;

      switch (availableImage.format.group) {
        case ImageFormatGroup.yuv420:
          format = ImagePixelFormat.IPF_NV21.index;
          break;
        case ImageFormatGroup.bgra8888:
          format = ImagePixelFormat.IPF_ARGB_8888.index;
          break;
        default:
          format = ImagePixelFormat.IPF_RGB_888.index;
      }

      if (!_isScanAvailable) {
        return;
      }

      _isScanAvailable = false;

      _barcodeReader!
          .decodeImageBuffer(
              availableImage.planes[0].bytes,
              availableImage.width,
              availableImage.height,
              availableImage.planes[0].bytesPerRow,
              format)
          .then((results) {
        if (_isScanRunning) {
          setState(() {
            _barcodeResults = getBarcodeResults(results);
            if (_barcodeResults != 'No Barcode Detected') {
              widget.callback(_barcodeResults);
              print(_barcodeResults);
            }
          });
        }

        _isScanAvailable = true;
      }).catchError((error) {
        _isScanAvailable = false;
      });
    });
  }

  void stopVideo() async {
    setState(() {
      _buttonText = 'Start Video Scan';
      _barcodeResults = '';
    });
    _isScanRunning = false;
    await _controller!.stopImageStream();
  }

  void videoScan() async {
    if (!_isScanRunning) {
      startVideo();
    } else {
      stopVideo();
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller?.dispose();
    super.dispose();
  }

  Widget getCameraWidget() {
    if (!_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    } else {
      // https://stackoverflow.com/questions/49946153/flutter-camera-appears-stretched
      final size = MediaQuery.of(context).size;
      var scale = size.aspectRatio * _controller!.value.aspectRatio;

      if (scale < 1) scale = 1 / scale;

      return Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(_controller!),
        ),
      );
      // return CameraPreview(_controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      getCameraWidget(),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              child: Text(
                _barcodeResults,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  MaterialButton(
                      textColor: Colors.white,
                      color: Colors.blue,
                      onPressed: () async {
                        try {
                          // Ensure that the camera is initialized.
                          await _initializeControllerFuture;

                          videoScan();
                          // pictureScan();
                        } catch (e) {
                          // If an error occurs, log the error to the console.
                          print(e);
                        }
                      },
                      child: Text(_buttonText)),
                  MaterialButton(
                      textColor: Colors.white,
                      color: Colors.blue,
                      onPressed: () async {
                        pictureScan();
                      },
                      child: const Text("Picture Scan"))
                ]),
          ),
        ],
      )
    ]);
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final String barcodeResults;

  const DisplayPictureScreen(
      {super.key, required this.imagePath, required this.barcodeResults});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Stack(
        alignment: const Alignment(0.0, 0.0),
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.black45,
            ),
            child: Text(
              // 'Dynamsoft Barcode Reader',
              barcodeResults,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
