import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HTMLPrintDemo1 extends StatefulWidget {
  const HTMLPrintDemo1({super.key});

  @override
  State<HTMLPrintDemo1> createState() => _HTMLPrintDemoState1();
}

class _HTMLPrintDemoState1 extends State<HTMLPrintDemo1> {
  InAppWebViewController? webController;

  final String htmlReceipt = """
<html>
  <body style="font-size:14px; width:80mm; font-family: Arial; text-align:center;">
    <h2>My Restaurant</h2>
    <p>Street No 12, Mumbai</p>
    <p>Phone: +91 9876543210</p>
    <hr>

    <p><b>Order No:</b> 12345</p>
    <p>Date: 01/02/2025</p>
    <hr>

    <table width="100%" style="font-size:14px;">
      <tr>
        <th align="left">Item</th>
        <th align="center">Qty</th>
        <th align="right">Amount</th>
      </tr>
      <tr>
        <td>Burger</td>
        <td align="center">2</td>
        <td align="right">₹200</td>
      </tr>
      <tr>
        <td>Coke</td>
        <td align="center">1</td>
        <td align="right">₹40</td>
      </tr>
    </table>

    <hr>
    <p><b>Total: ₹240</b></p>
    <hr>

    <p>Thank you for visiting!</p>
  </body>
</html>
""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HTML Print Demo")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Print HTML Receipt"),
          onPressed: () async {
            await openPrintView();
          },
        ),
      ),
    );
  }

  Future<void> openPrintView() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Print Preview")),
          body: InAppWebView(
            initialData: InAppWebViewInitialData(data: htmlReceipt),
            onWebViewCreated: (controller) async {
              webController = controller;

              // WAIT 1 second to load HTML fully
              await Future.delayed(const Duration(seconds: 1));

              // Trigger Print Dialog
              controller.evaluateJavascript(source: "window.print();");
            },
          ),
        ),
      ),
    );
  }
}
