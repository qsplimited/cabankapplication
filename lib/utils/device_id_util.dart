import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';


Future<String> getUniqueDeviceId() async {
  String deviceIdentifier = 'unknown';
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  try {
    if (kIsWeb) {

      WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      deviceIdentifier = 'WEB-${webInfo.vendor ?? 'Vendor'}';
    } else if (Platform.isAndroid) {

      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceIdentifier = androidInfo.id;
    } else if (Platform.isIOS) {

      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceIdentifier = iosInfo.identifierForVendor ?? 'IOS-Unknown';
    } else {

      deviceIdentifier = 'Unknown Platform';
    }
  } catch (e) {
    print('Error retrieving device ID: $e');
    deviceIdentifier = 'Error-Retrieving-ID';
  }

  return deviceIdentifier;
}