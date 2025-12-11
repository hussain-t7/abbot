import 'package:flutter/services.dart';

class HtmlPrinter {
  static const MethodChannel _channel = MethodChannel("html_printer");

  static Future<void> printHtml(String html) async {
    try {
      await _channel.invokeMethod("printHtml", {"html": html});
    } catch (e) {
      print("HTML Print Error: $e");
    }
  }
}
