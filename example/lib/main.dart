import 'package:easy_flutter_barcode_sdk/easy_flutter_barcode_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    title: 'Flutter Demo',
    home: EasyFlutterBarcodeSdk(
        licenceKey:
            'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==',
        callback: (result) {
          print(result);
          print('Barcode results: $result-----------------------');
        }),
  ));
}
