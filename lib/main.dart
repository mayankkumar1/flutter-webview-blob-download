import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  runApp(WebViewDownloadExample());
}

class WebViewDownloadExample extends StatefulWidget {
  @override
  _WebViewDownloadExampleState createState() => _WebViewDownloadExampleState();
}

class _WebViewDownloadExampleState extends State<WebViewDownloadExample> {
  WebViewController? webViewController;
  dynamic pdfData;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WebView Example'),
        ),
        body: Container(
          child: WebView(
            initialUrl: '****YourURL****',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            javascriptChannels: {
              JavascriptChannel(
                  name: 'Print',
                  onMessageReceived: (JavascriptMessage message) {
                    _createFileFromBase64(message.message, 'invoice', 'pdf');
                  })
            },
            navigationDelegate: (NavigationRequest request) async {
              // Check if the URL starts with 'blob:' (indicating a blob URL)
              if (request.url.startsWith('blob:')) {
                var url = request.url;

                await webViewController?.runJavascriptReturningResult('''
                      var req = new XMLHttpRequest();
                      req.open('GET', "$url");
                      req.responseType = "blob";
                      req.onload = function() {
                        if (req.status == 200) {
                           var blob = new Blob([req.response], { type: "application/octetstream" });
                           var reader = new FileReader();
                                                  reader.readAsDataURL(blob);
                                                  reader.onloadend = function() {
                                                    var base64data = reader.result;
                                                    var base64ContentArray = base64data.split(",");
                                                    var decodedFile = base64ContentArray[1];
                           
                          Print.postMessage(decodedFile);
                          }
                        } else {
                          Print.postMessage("Error: " + req.status);
                        }
                      }
                      req.send();''');

                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        ),
      ),
    );
  }

  // Function to display the downloaded PDF
  _createFileFromBase64(String base64content, String fileName, String yourExtension) async {
    var bytes = base64Decode(base64content.replaceAll('\n', ''));
    final output = await getExternalStorageDirectory();
    final file = File("${output?.path}/$fileName.$yourExtension");
    await file.writeAsBytes(bytes.buffer.asUint8List());
    print("${output?.path}/${fileName}.$yourExtension");
    await OpenFile.open("${output?.path}/$fileName.$yourExtension");
    setState(() {});
  }
}
