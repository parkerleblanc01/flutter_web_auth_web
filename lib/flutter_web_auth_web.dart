import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FlutterWebAuthPlugin {
  html.WindowBase _popupWin;

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
        'flutter_web_auth',
        const StandardMethodCodec(),
        registrar.messenger);
    final FlutterWebAuthPlugin instance = FlutterWebAuthPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  String _login(data) {
    // final _authCode = data
    //     .split('?')
    //     .firstWhere((e) => e.startsWith('code=') ? true : false)
    //     .substring('code='.length);

    _closePopup();

    return data;
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'authenticate':
        final givenUrl = Uri.parse(call.arguments["url"]);
        final callbackUrlScheme = call.arguments["callbackUrlScheme"];


        // final String url = call.arguments['url'];
        // return _launch(url);
        print('authenticate');

        // Our current app URL
        final currentUri = Uri.base;

        // Generate the URL redirection to our static.html page
        final redirectUri = Uri(
          host: currentUri.host,
          scheme: currentUri.scheme,
          port: currentUri.port,
          path: '/static.html',
        );

        // replace redirect url
        final url = Uri.https(givenUrl.authority, givenUrl.path, {...givenUrl.queryParameters, 'redirect_uri': "$redirectUri"} );

        // Start listening for auth callback
        final listenFuture = _listen();

        // Open window
        _popupWin = html.window.open(
            url.toString(), "Client Oauth", "width=800, height=900, scrollbars=yes"
        );

        // Wait for auth callback within 10 minutes
        return await listenFuture;
      case 'cleanUpDanglingCalls':
        _closePopup();
        return null;
      default:
        _closePopup();
        throw PlatformException(
            code: 'Unimplemented',
            details: "The url_launcher plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  void _closePopup() {
    /// Close the popup window
    if (_popupWin != null) {
    _popupWin.close();
    _popupWin = null;
    }
  }

  Future<String> _listen() async {
    final event = await html.window.onMessage.first.timeout(Duration(minutes: 5));

    if (event?.data.toString().contains('code=')) {
      return _login(event.data);
    } else {
      _closePopup();
      return null;
    }
  }
}