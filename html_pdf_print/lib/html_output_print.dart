// import 'package:flutter/material.dart';
// import 'package:printing/printing.dart';

// class HTMLPrintDemo extends StatelessWidget {
//   const HTMLPrintDemo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("HTML Print Demo")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             await printHTML();
//           },
//           child: const Text("Print HTML"),
//         ),
//       ),
//     );
//   }

//   // ------------------------------
//   // 📌 Print HTML directly
//   // ------------------------------
//   Future<void> printHTML() async {
//     const String htmlContent = """
// <html>
//   <body style="font-size:14px; font-family: Arial; text-align:center;">
//     <h2>My Restaurant</h2>
//     <p>Street No 12, Mumbai</p>
//     <p>Phone: +91 9876543210</p>
//     <hr>

//     <p><b>Order No:</b> 12345</p>
//     <p>Date: 01/02/2025</p>
//     <hr>

//     <table width="100%" style="font-size:14px;">
//       <tr>
//         <th align="left">Item</th>
//         <th align="center">Qty</th>
//         <th align="right">Amount</th>
//       </tr>
//       <tr>
//         <td>Burger</td>
//         <td align="center">2</td>
//         <td align="right">₹200</td>
//       </tr>
//       <tr>
//         <td>Coke</td>
//         <td align="center">1</td>
//         <td align="right">₹40</td>
//       </tr>
//     </table>

//     <hr>
//     <p><b>Total: ₹240</b></p>
//     <hr>

//     <p>Thank you for visiting!</p>
//   </body>
// </html>
// """;

//     await Printing.layoutPdf(
//       onLayout: (format) async {
//         return await Printing.convertHtml(format: format, html: htmlContent);
//       },
//     );
//   }

// }
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart'; // <<-- Add this import
import 'package:pdf/widgets.dart' as pw;

class HTMLPrintDemo extends StatelessWidget {
  const HTMLPrintDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HTML Print Demo")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await printHTML();
          },
          child: const Text("Print HTML as Text"),
        ),
      ),
    );
  }

  // ------------------------------------
  // 📌 Print HTML as NORMAL TEXT (RAW)
  // ------------------------------------
  Future<void> printHTML() async {
    const String htmlContent = """
<html>
  <body style="font-size:14px; font-family: Arial; text-align:center;">
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

    // Convert HTML string to raw bytes
    final rawBytes = Uint8List.fromList(htmlContent.codeUnits);

    // Send RAW printable content (NOT PDF)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return rawBytes; // print text directly as-is
      },
    );
  }
}
