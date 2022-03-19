import 'dart:io';

import 'package:flutter/material.dart';

class AppApiCall {
  late DateTime createdTime;
  final int id;
  String client = "";
  bool loading = true;
  bool secure = false;
  String method = "";
  String endpoint = "";
  String cUrl = "";
  String server = "";
  String uri = "";
  int duration = 0;

  AppApiDebugRequest? request;
  AppApiDebugResponse? response;
  AppApiDebugError? error;

  AppApiCall(this.id) {
    loading = true;
    createdTime = DateTime.now();
  }

  setResponse(AppApiDebugResponse response) {
    this.response = response;
    loading = false;
  }

  Color get getStatusColor {
    if (response != null) {
      return Colors.green.shade700;
    }
    if (error != null) {
      return Colors.redAccent;
    }
    return Colors.yellowAccent;
  }
}

class AppApiDebugRequest {
  int size = 0;
  DateTime time = DateTime.now();
  Map<String, dynamic> headers = Map();
  dynamic body = "";
  String contentType = "";
  List<Cookie> cookies = [];
  Map<String, dynamic> queryParameters = <String, dynamic>{};
  List<AppApiFormDataFile>? formDataFiles;
  List<AppApiFormDataField>? formDataFields;
}

class AppApiDebugResponse {
  int status = 0;
  int size = 0;
  DateTime time = DateTime.now();
  dynamic body;
  Map<String, String>? headers;


  String get getStatus {
    if (this.status == -1) {
      return "ERR";
    } else if (this.status == 0) {
      return "???";
    } else {
      return "${this.status}";
    }
  }
}

class AppApiDebugError {
  dynamic error;
  StackTrace? stackTrace;
}



   
class AppApiFormDataFile {
  final String? fileName;
  final String contentType;
  final int length;

  AppApiFormDataFile(this.fileName, this.contentType, this.length);
}


   
class AppApiFormDataField {
  final String name;
  final String value;

  AppApiFormDataField(this.name, this.value);
}