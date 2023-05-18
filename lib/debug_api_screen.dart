import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'debug_api.dart';
import 'debug_model.dart';

class NetworkHistoryScreen extends StatefulWidget {
  const NetworkHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NetworkHistoryScreen> createState() => _NetworkHistoryScreenState();
}

class _NetworkHistoryScreenState extends State<NetworkHistoryScreen> {
  List<AppApiCall> apis = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String formatDate(DateTime date) {
    final dateFormat = DateFormat('HH:mm');
    return dateFormat.format(date);
  }

  Color? _getStatusTextColor(AppApiCall call) {
    final int? status = call.response!.status;
    if (status == -1) {
      return Colors.red;
    } else if (status! < 200) {
      return Theme.of(context).textTheme.bodyText1!.color;
    } else if (status >= 200 && status < 300) {
      return Colors.green;
    } else if (status >= 300 && status < 400) {
      return Colors.orange;
    } else if (status >= 400 && status < 600) {
      return Colors.red;
    } else {
      return Theme.of(context).textTheme.bodyText1!.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Network History', style: TextStyle(fontSize: 16, color: Colors.black)),
        toolbarHeight: Platform.isIOS ? 44 : 55,
        leading: BackButton(onPressed: () => Navigator.of(context).pop(), color: Colors.black,),
        backgroundColor: Colors.white,
        bottomOpacity: 1.0,
        elevation: 0.5,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Icon(Icons.delete, color: Colors.black), onPressed: () {
              ApiDebug().removeCalls();
            })
        ],
      ),
      body: Container(
        child: StreamBuilder<List<AppApiCall>>(
          stream: ApiDebug().callsSubject,
          builder: (context, snapshot) {
            List<AppApiCall> calls = (snapshot.data ?? []).reversed.toList();
            return ListView.separated(
                itemBuilder: (context, index) {
                  final item = calls[index];
                  return InkWell(
                    onTap: () {
                      ApiDebug.navigate(context, (context) => NetworkHistoryItemDetailScreen(call: item));
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.method + ' ' + item.endpoint,
                                  style: TextStyle(color: item.getStatusColor, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.lock, size: 12, color: item.secure == true ? Colors.greenAccent.shade700 : Colors.redAccent.shade400),
                                    SizedBox(width: 4),
                                    Text(
                                      item.server,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Container(
                                  child: Row(children: [
                                    Expanded(
                                        child: Text(formatDate(item.createdTime.toLocal()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal))),
                                    Expanded(
                                        child: Text('${AppApiDebugConversionHelper.formatTime(item.duration)}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal))),
                                    Expanded(
                                        child: Text(
                                            '${AppApiDebugConversionHelper.formatBytes(item.request?.size ?? 0)}/${AppApiDebugConversionHelper.formatBytes(item.response?.size ?? 0)}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)))
                                  ]),
                                )
                              ],
                            ),
                          ),
                          Container(
                            child: Center(
                              child: Text(
                                (item.response?.getStatus ?? '---'),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _getStatusTextColor(item)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => Container(height: 1, color: Colors.black54),
                itemCount: calls.length);
          },
        ),
      ),
    );
  }
}

class NetworkHistoryItemDetailScreen extends StatefulWidget {
  final AppApiCall call;
  const NetworkHistoryItemDetailScreen({Key? key, required this.call}) : super(key: key);

  @override
  State<NetworkHistoryItemDetailScreen> createState() => _NetworkHistoryItemDetailScreenState();
}

class _NetworkHistoryItemDetailScreenState extends State<NetworkHistoryItemDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Network History', style: TextStyle(fontSize: 16, color: Colors.black)),
        toolbarHeight: Platform.isIOS ? 44 : 55,
        leading: BackButton(onPressed: () => Navigator.of(context).pop(), color: Colors.black,),
        backgroundColor: Colors.white,
        bottomOpacity: 1.0,
        elevation: 0.5,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Text('Copy CURL', style: TextStyle(fontSize: 12, color: Colors.black)), onPressed: () {
              Clipboard.setData(ClipboardData(text: call.cUrl));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Copied"),
                ));
            })
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text('GENERAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Item(title: 'Request URL', content: call.uri),
              Item(title: 'Request Method', content: call.method),
              Item(title: 'Status Code', content: call.response?.getStatus ?? '---'),
              Item(title: 'Response Body', content: 'Tap to view', onTap: () {
                ApiDebug.navigate(context, (context) => ApiDebugViewJSONScreen(call: call));
              }),
              Item(title: 'Request size', content: AppApiDebugConversionHelper.formatBytes(call.request?.size ?? 0)),
              Item(title: 'Response size', content: AppApiDebugConversionHelper.formatBytes(call.response?.size ?? 0)),
              Item(title: 'Start time', content: call.createdTime.toLocal().toIso8601String()),
              Item(title: 'Duration', content: AppApiDebugConversionHelper.formatTime(call.duration)),
              SizedBox(height: 16),
              Text('REQUEST HEADER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ...(call.request?.headers.keys.toList() ?? []).map((e) {
                return Item(title: '$e', content: '${call.request!.headers[e]}');
              }).toList(),
              if ((call.request?.queryParameters.keys.toList() ?? []).length > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text('QUERY PARAMETERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...(call.request?.queryParameters.keys.toList() ?? []).map((e) {
                      return Item(title: '$e', content: '${call.request!.queryParameters[e]}');
                    }).toList(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              if (call.request != null && call.request!.body is Map && (call.request!.body as Map<String, dynamic>).keys.length > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text('REQUEST BODY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...((call.request!.body as Map<String, dynamic>).keys.toList()).map((e) {
                      return Item(title: '$e', content: '${call.request!.body[e]}');
                    }).toList(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              if ((call.request?.formDataFiles ?? []).length > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text('FORM DATA FILE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...(call.request?.formDataFiles ?? []).map((e) {
                      return Item(title: '', content: '• ${e.fileName}: ${e.contentType} / ${e.length} B');
                    }).toList(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              if ((call.request?.formDataFields ?? []).length > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text('FORM DATA FIELDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...(call.request?.formDataFields ?? []).map((e) {
                      return Item(title: '${e.name}', content: '${e.value}');
                    }).toList(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              SizedBox(height: 16),
              Text('RESPONSE HEADER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ...(call.response?.headers?.keys.toList() ?? []).map((e) {
                return Item(title: '$e', content: '${call.response!.headers![e] ?? ''}');
              }).toList(),
              SizedBox(height: MediaQuery.of(context).padding.bottom)
            ],
          ),
        ),
      ),
    );
  }
}

class Item extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onTap;
  const Item({Key? key, required this.title, required this.content, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Copied"),
                ));
      },
      onTap: () {
        if (onTap != null) onTap!();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black54, width: 0.5))),
        child: Row(
          children: [
            Expanded(
                child: RichText(
                    text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal), children: [
              TextSpan(text: title + (title.length > 0 ? ': ' : ''), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
              TextSpan(text: content, style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black))
            ]))),
            if (onTap != null) Icon(Icons.keyboard_arrow_right_outlined)
          ],
        ),
      ),
    );
  }
}

class ApiDebugViewJSONScreen extends StatefulWidget {
  final AppApiCall call;
  const ApiDebugViewJSONScreen({ Key? key, required this.call}) : super(key: key);

  @override
  State<ApiDebugViewJSONScreen> createState() => _ApiDebugViewJSONScreenState();
}

class _ApiDebugViewJSONScreenState extends State<ApiDebugViewJSONScreen> {

  String prettyJson(dynamic json, {int indent = 2}) {
  var spaces = ' ' * indent;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}


  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    final jsonString = prettyJson(widget.call.response?.body ?? '');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Response', style: TextStyle(fontSize: 16, color: Colors.black)),
        toolbarHeight: Platform.isIOS ? 44 : 55,
        leading: BackButton(onPressed: () => Navigator.of(context).pop(), color: Colors.black,),
        backgroundColor: Colors.white,
        bottomOpacity: 1.0,
        elevation: 0.5,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Icon(Icons.copy, color: Colors.black), onPressed: () {
               Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Copied"),
                ));
            })
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, paddingBottom + 8),
            child: SelectableText(jsonString, style: TextStyle(fontSize: 12),),
          ),
        ),
      ),
    );
  }
}
