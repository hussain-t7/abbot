import 'package:flutter/material.dart';
import 'html_printer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HTMLPrintDemo());
  }
}

class HTMLPrintDemo extends StatelessWidget {
  HTMLPrintDemo({super.key});

  final String htmlSample = """
<html>
  <body style="font-size:14px; font-family: Arial; text-align:center;">
    <h2 style='margin:0;'>My Restaurant</h2>
    <p>Street No 12, Mumbai</p>
    <p>Phone: +91 9876543210</p>
    <hr>

    <p><b>Order No:</b> 1001</p>
    <p>Date: 11/02/2025</p>
    <hr>

    <table width="100%" style="font-size:14px;">
      <tr>
        <th align="left">Item</th>
        <th align="center">Qty</th>
        <th align="right">Price</th>
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
          onPressed: () {
            HtmlPrinter.printHtml(htmlSample);
          },
          child: const Text("PRINT HTML"),
        ),
      ),
    );
  }
}
