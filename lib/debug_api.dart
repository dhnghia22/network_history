import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'debug_api_screen.dart';
import 'debug_model.dart';

final _debugStorageKey = 'io.shopnext.debug.network_flag';

class ApiDebug {
  static final ApiDebug _apiCore = ApiDebug._internal();
  factory ApiDebug() {
    return _apiCore;
  }

  bool enableDebug = false;

  void updateDebugFlag(bool enable) async {
    enableDebug = enable;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_debugStorageKey, enable);
  }

  void getDebugFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(_debugStorageKey) ?? false;
    enableDebug = result;
  }

  ApiDebug._internal() {
    print("AppDebugApiCore is now implemented");
    getDebugFlag();
  }

  void openDebugScreen({required BuildContext ctx}) {
    ApiDebug.navigate(ctx, (context) => NetworkHistoryScreen());
  }

  final BehaviorSubject<List<AppApiCall>> callsSubject =
      BehaviorSubject.seeded([]);

  void dispose() {
    callsSubject.close();
  }

  AppApiCall? _selectCall(int requestId) =>
      callsSubject.value.firstWhere((call) => call.id == requestId);

  void _addCall(AppApiCall call) {
    if (enableDebug == false) {
      return;
    }
    final callsCount = callsSubject.value.length;
    if (callsCount >= 50) {
      final originalCalls = callsSubject.value;
      final calls = List<AppApiCall>.from(originalCalls);
      calls.sort(
        (call1, call2) => call1.createdTime.compareTo(call2.createdTime),
      );
      final indexToReplace = (originalCalls).indexOf(calls.first);
      originalCalls[indexToReplace] = call;

      callsSubject.add(originalCalls);
    } else {
      callsSubject.add([...(callsSubject.value), call]);
    }
  }

  void _addError(AppApiDebugError error, int requestId) {
    if (enableDebug == false) {
      return;
    }
    final AppApiCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      // AliceUtils.log("Selected call is null");
      return;
    }

    selectedCall.error = error;
    callsSubject.add([...callsSubject.value]);
  }

  void _addResponse(AppApiDebugResponse response, int requestId) {
    if (enableDebug == false) {
      return;
    }
    final AppApiCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      // AliceUtils.log("Selected call is null");
      return;
    }
    selectedCall.loading = false;
    selectedCall.response = response;
    selectedCall.duration = response.time.millisecondsSinceEpoch -
        selectedCall.request!.time.millisecondsSinceEpoch;

    callsSubject.add([...callsSubject.value]);
  }

  void removeCalls() {
    callsSubject.add([]);
  }

  void onRequest(RequestOptions options) {
    try {
      final AppApiCall call = AppApiCall(options.hashCode);

      final Uri uri = options.uri;
      call.method = options.method;
      var path = options.uri.path;
      if (path.isEmpty) {
        path = "/";
      }
      call.endpoint = path;
      call.server = uri.host;
      call.client = "Dio";
      call.uri = options.uri.toString();

      call.cUrl = options.cUrl;

      if (uri.scheme == "https") {
        call.secure = true;
      }

      final AppApiDebugRequest request = AppApiDebugRequest();

      final dynamic data = options.data;
      if (data == null) {
        request.size = 0;
        request.body = "";
      } else {
        if (data is FormData) {
          request.body += "Form data";

          if (data.fields.isNotEmpty == true) {
            final List<AppApiFormDataField> fields = [];
            data.fields.forEach((entry) {
              fields.add(AppApiFormDataField(entry.key, entry.value));
            });
            request.formDataFields = fields;
          }
          if (data.files.isNotEmpty == true) {
            final List<AppApiFormDataFile> files = [];
            data.files.forEach((entry) {
              files.add(
                AppApiFormDataFile(
                  entry.value.filename,
                  entry.value.contentType.toString(),
                  entry.value.length,
                ),
              );
            });

            request.formDataFiles = files;
          }
        } else {
          request.size = utf8.encode(data.toString()).length;
          request.body = data;
        }
      }

      request.time = DateTime.now();
      request.headers = options.headers;
      request.contentType = options.contentType.toString();
      request.queryParameters = options.queryParameters;

      call.request = request;
      call.response = AppApiDebugResponse();

      this._addCall(call);
    } catch (e) {}
  }

  void onResponse(Response response) {
    try {
      final httpResponse = AppApiDebugResponse();
      httpResponse.status = response.statusCode ?? -1;

      if (response.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        httpResponse.body = response.data;
        httpResponse.size = utf8.encode(response.data.toString()).length;
      }

      httpResponse.time = DateTime.now();
      final Map<String, String> headers = {};
      response.headers.forEach((header, values) {
        headers[header] = values.toString();
      });
      httpResponse.headers = headers;

      this._addResponse(httpResponse, response.requestOptions.hashCode);
    } catch (e) {}
  }

  void onError(DioError error) {
    try {
      final httpError = AppApiDebugError();
      httpError.error = error.toString();
      if (error is Error) {
        final basicError = error as Error;
        httpError.stackTrace = basicError.stackTrace;
      }

      this._addError(httpError, error.requestOptions.hashCode);
      final httpResponse = AppApiDebugResponse();
      httpResponse.time = DateTime.now();
      if (error.response == null) {
        httpResponse.status = -1;
        this._addResponse(httpResponse, error.requestOptions.hashCode);
      } else {
        httpResponse.status = error.response?.statusCode ?? -1;

        if (error.response!.data == null) {
          httpResponse.body = "";
          httpResponse.size = 0;
        } else {
          httpResponse.body = error.response!.data;
          httpResponse.size =
              utf8.encode(error.response!.data.toString()).length;
        }
        final Map<String, String> headers = {};
        error.response!.headers.forEach((header, values) {
          headers[header] = values.toString();
        });
        httpResponse.headers = headers;
        this._addResponse(
          httpResponse,
          error.response!.requestOptions.hashCode,
        );
      }
    } catch (e) {}
  }

  static void navigate(BuildContext context, WidgetBuilder builder) {
    if (Platform.isIOS) {
      Navigator.of(context).push(CupertinoPageRoute(builder: builder));
    } else if (Platform.isAndroid) {
      Navigator.of(context).push(MaterialPageRoute(builder: builder));
    }
  }
}

class AppApiDebugConversionHelper {
  static const int _kilobyteAsByte = 1000;
  static const int _megabyteAsByte = 1000000;
  static const int _secondAsMillisecond = 1000;
  static const int _minuteAsMillisecond = 60000;

  /// Format bytes text
  static String formatBytes(int bytes) {
    if (bytes < 0) {
      return "-1 B";
    }
    if (bytes <= _kilobyteAsByte) {
      return "$bytes B";
    }
    if (bytes <= _megabyteAsByte) {
      return "${_formatDouble(bytes / _kilobyteAsByte)} kB";
    }

    return "${_formatDouble(bytes / _megabyteAsByte)} MB";
  }

  static String _formatDouble(double value) => value.toStringAsFixed(2);

  /// Format time in milliseconds
  static String formatTime(int timeInMillis) {
    if (timeInMillis < 0) {
      return "-1 ms";
    }
    if (timeInMillis <= _secondAsMillisecond) {
      return "$timeInMillis ms";
    }
    if (timeInMillis <= _minuteAsMillisecond) {
      return "${_formatDouble(timeInMillis / _secondAsMillisecond)} s";
    }

    final Duration duration = Duration(milliseconds: timeInMillis);

    return "${duration.inMinutes} min ${duration.inSeconds.remainder(60)} s "
        "${duration.inMilliseconds.remainder(1000)} ms";
  }
}

class AppApiDebugParser {
  static const String _emptyBody = "Body is empty";
  static const String _unknownContentType = "Unknown";
  static const String _jsonContentTypeSmall = "content-type";
  static const String _jsonContentTypeBig = "Content-Type";
  static const String _stream = "Stream";
  static const String _applicationJson = "application/json";
  static const String _parseFailedText = "Failed to parse ";
  static const JsonEncoder encoder = JsonEncoder.withIndent('  ');

  static String _parseJson(dynamic json) {
    try {
      return encoder.convert(json);
    } catch (exception) {
      return json.toString();
    }
  }

  static dynamic _decodeJson(dynamic body) {
    try {
      return json.decode(body as String);
    } catch (exception) {
      return body;
    }
  }

  static String formatBody(dynamic body, String? contentType) {
    try {
      if (body == null) {
        return _emptyBody;
      }

      var bodyContent = _emptyBody;

      if (contentType == null ||
          !contentType.toLowerCase().contains(_applicationJson)) {
        final bodyTemp = body.toString();

        if (bodyTemp.isNotEmpty) {
          bodyContent = bodyTemp;
        }
      } else {
        if (body is String && body.contains("\n")) {
          bodyContent = body;
        } else {
          if (body is String) {
            if (body.isNotEmpty) {
              //body is minified json, so decode it to a map and let the encoder pretty print this map
              bodyContent = _parseJson(_decodeJson(body));
            }
          } else if (body is Stream) {
            bodyContent = _stream;
          } else {
            bodyContent = _parseJson(body);
          }
        }
      }

      return bodyContent;
    } catch (exception) {
      return _parseFailedText + body.toString();
    }
  }

  static String? getContentType(Map<String, dynamic>? headers) {
    if (headers != null) {
      if (headers.containsKey(_jsonContentTypeSmall)) {
        return headers[_jsonContentTypeSmall] as String?;
      }
      if (headers.containsKey(_jsonContentTypeBig)) {
        return headers[_jsonContentTypeBig] as String?;
      }
    }
    return _unknownContentType;
  }
}

extension CURLRepresentation on RequestOptions {
  String get cUrl {
    List<String> components = ['curl -i'];
    if (this.method.toUpperCase() == 'GET') {
      components.add('-X ${this.method}');
    }

    this.headers.forEach((k, v) {
      if (k != 'Cookie') {
        components.add('-H \"$k: $v\"');
      }
    });

    if (this.data != null && this.data is Map) {
      var dataRaw = "";
      if ((this.headers["content-type"] == Headers.jsonContentType ||
              this.headers["Content-Type"] == Headers.jsonContentType) &&
          this.data is Map) {
        final raw = jsonEncode(this.data);
        if (raw.length > 0) {
          dataRaw = '$raw';
        }
      } else {
        var parametersList = [];
        this.data.forEach((key, value) {
          parametersList.add('$key=$value');
        });
        if (parametersList.length > 0) {
          dataRaw = "${parametersList.join('&')}'";
        }
      }
      components.add('--data-raw \"$dataRaw\"');
    }

    components.add('\"${this.uri.toString()}\"');

    return components.join('\\\n\t');
  }
}
