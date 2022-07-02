<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->
## Network History
Network history debugger for Dio Http Client

## Features

- View Network history.
- View Request/response.
- Copy cURL (Not support Multipart/form-data)

## Getting started

Add to pubspec
```dart
network_history:
    git:
      url: https://github.com/dhnghia22/network_history
      ref: master
```

## Usage

Init

```dart
ApiDebug()
```

Add function into Dio Interceptor
```dart
Dio _dio = Dio(BaseOptions(connectTimeout: 60000, baseUrl: 'https://localhoast:8080/'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          ApiDebug().onRequest(options);
          handler.next(options);
        },
        onError: (DioError dioError, ErrorInterceptorHandler handler) {
          ApiDebug().onError(dioError);
          handler.next(dioError);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          ApiDebug().onResponse(response);
          handler.next(response);
        },
      ),
    );
```

Enable Log request
```dart
ApiDebug().updateDebugFlag(true);
```

Open Network history

```dart
ApiDebug().openDebugScreen(ctx: your_context);
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
