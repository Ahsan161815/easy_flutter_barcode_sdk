library flutter_barcode_sdk_flutterflow;

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easy_flutter_barcode_sdk/desktop.dart';
import 'package:easy_flutter_barcode_sdk/mobile.dart';
import 'package:easy_flutter_barcode_sdk/web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EasyFlutterBarcodeSdk extends StatefulWidget {
  const EasyFlutterBarcodeSdk(
      {super.key, required this.licenceKey, required this.callback});

  final String licenceKey;
  final Function(String) callback;

  @override
  State<EasyFlutterBarcodeSdk> createState() => _EasyFlutterBarcodeSdkState();
}

class _EasyFlutterBarcodeSdkState extends State<EasyFlutterBarcodeSdk> {
  late StatefulWidget app;

  @override
  void initState() {
    super.initState();
    // init();
  }

  Future<StatefulWidget> init() async {
    // StatefulWidget? app;
    if (kIsWeb) {
      app = Web(
        licenceKey: widget.licenceKey,
        callback: widget.callback,
      );
      return app;
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Ensure that plugin services are initialized so that `availableCameras()`
      // can be called before `runApp()`
      WidgetsFlutterBinding.ensureInitialized();

      // Obtain a list of the available cameras on the device.
      final cameras = await availableCameras();

      // Get a specific camera from the list of available cameras.
      final firstCamera = cameras.first;

      app = Mobile(
        camera: firstCamera,
        licenceKey: widget.licenceKey,
        callback: widget.callback,
      );
      return app;
    } else {
      app = Desktop(
        licenceKey: widget.licenceKey,
        callback: widget.callback,
      );
      return app;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatefulWidget>(
      future: init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: CircularProgressIndicator(),
          );
        } else {
          return app;
        }
      },
    );
  }
}
