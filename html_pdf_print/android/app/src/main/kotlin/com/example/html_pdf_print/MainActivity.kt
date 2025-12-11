package com.example.html_pdf_print
import android.os.Bundle
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "html_printer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "printHtml") {
                val html = call.argument<String>("html")!!
                printHTML(html)
                result.success(true)
            }
        }
    }

    private fun printHTML(html: String) {
        val webView = WebView(this)
        webView.settings.javaScriptEnabled = true
        webView.settings.defaultTextEncodingName = "utf-8"

        webView.loadDataWithBaseURL(null, html, "text/HTML", "UTF-8", null)

        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                val printManager = getSystemService(PRINT_SERVICE) as PrintManager
                val printAdapter = view!!.createPrintDocumentAdapter("HTML Receipt")
                printManager.print(
                    "HTML Receipt",
                    printAdapter,
                    PrintAttributes.Builder()
                        .setMediaSize(PrintAttributes.MediaSize.UNKNOWN_PORTRAIT)
                        .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                        .build()
                )
            }
        }
    }
}
