import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_flutter_barcode_sdk/utils.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';

class Desktop extends StatefulWidget {
  const Desktop({super.key, required this.callback, required this.licenceKey});
  final Function(String) callback;
  final String licenceKey;

  @override
  _DesktopState createState() => _DesktopState();
}

class _DesktopState extends State<Desktop> {
  String _platformVersion = 'Unknown';
  final _controller = TextEditingController();
  String _barcodeResults = '';
  late FlutterBarcodeSdk _barcodeReader;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initBarcodeSDK();
  }

  Future<void> initBarcodeSDK() async {
    _barcodeReader = FlutterBarcodeSdk();
    // Get 30-day FREEE trial license from https://www.dynamsoft.com/customer/license/trialLicense?product=dbr
    await _barcodeReader.setLicense(widget.licenceKey);
    await _barcodeReader.init();
    await _barcodeReader.setBarcodeFormats(BarcodeFormat.ALL);

    // Get all current parameters.
    // Refer to: https://www.dynamsoft.com/barcode-reader/parameters/reference/image-parameter/?ver=latest
    String params = await _barcodeReader.getParameters();
    // Convert parameters to a JSON object.
    dynamic obj = json.decode(params);
    // Modify parameters.
    obj['ImageParameter']['DeblurLevel'] = 5;
    // Update the parameters.
    int ret = await _barcodeReader.setParameters(json.encode(obj));
    print('Parameter update: $ret');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterBarcodeSdk.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Widget getDefaultImage() {
    if (_controller.text.isEmpty || !_isValid) {
      return Image.asset('images/default.png');
    } else {
      return Image.file(File(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamsoft Barcode Reader FlutterFlow'),
      ),
      body: Column(children: [
        SizedBox(
          height: 100,
          child: Row(children: <Widget>[
            Text(
              _platformVersion,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            )
          ]),
        ),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Input an image path',
            errorText: _isValid ? null : 'File not exists',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                getDefaultImage(),
                Text(
                  _barcodeResults,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
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
                      const typeGroup = XTypeGroup(
                        label: 'images',
                        extensions: ['jpg', 'png', 'jpeg'],
                      );
                      try {
                        final files = await FileSelectorPlatform.instance
                            .openFiles(acceptedTypeGroups: [typeGroup]);
                        final file = files[0];
                        List<BarcodeResult> results =
                            await _barcodeReader.decodeFile(file.path);

                        _isValid = true;
                        setState(() {
                          _controller.text = file.path;
                          _barcodeResults = getBarcodeResults(results);
                          widget.callback(results[0].text);
                        });
                      } catch (err) {
                        print('Error: $err');
                      }
                    },
                    child: const Text('Open an Image')),
                MaterialButton(
                    textColor: Colors.white,
                    color: Colors.blue,
                    onPressed: () async {
                      if (_controller.text.isEmpty) {
                        _isValid = false;
                        setState(() {
                          _barcodeResults = '';
                        });
                        return;
                      }

                      File file = File(_controller.text);
                      if (!file.existsSync()) {
                        _isValid = false;
                        setState(() {
                          _barcodeResults = '';
                        });
                        return;
                      } else {
                        _isValid = true;
                      }
                      Uint8List fileBytes = await file.readAsBytes();

                      ui.Image image = await decodeImageFromList(fileBytes);

                      ByteData? byteData = await image.toByteData(
                          format: ui.ImageByteFormat.rawRgba);

                      if (byteData == null) return;
                      List<BarcodeResult> results =
                          await _barcodeReader.decodeImageBuffer(
                              byteData.buffer.asUint8List(),
                              image.width,
                              image.height,
                              byteData.lengthInBytes ~/ image.height,
                              ImagePixelFormat.IPF_ARGB_8888.index);
                      // List<BarcodeResult> results =
                      //     await _barcodeReader.decodeFile(_controller.text);

                      setState(() {
                        _barcodeResults = getBarcodeResults(results);
                        widget.callback(_barcodeResults);
                      });
                    },
                    child: const Text('Decode Barcode')),
              ]),
        ),
      ]),
    );
  }
}
