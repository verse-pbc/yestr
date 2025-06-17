import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class WebBackgroundService {
  static void setLoginBackground() {
    if (kIsWeb) {
      js.context.callMethod('setBackgroundImage', [
        'https://cdn.midjourney.com/7bc9a4f2-be36-4270-a4f9-2cd6260ef772/0_0.png'
      ]);
    }
  }
  
  static void setMainBackground() {
    if (kIsWeb) {
      js.context.callMethod('setBackgroundImage', [
        'https://cdn.midjourney.com/9cf783cf-ee12-404e-ad22-3ee736588951/0_0.png'
      ]);
    }
  }
}