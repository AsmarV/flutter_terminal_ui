
## Description

This package used to show the terminal widget in your app

## Getting started

To show terminal in app screen to help you in debugger with any mode - debug / profile / release -

## Usage

```dart
Future<void> main() async {
  //Replace with your runApp();
  runAppWithDebuggingMode(
    appView: MaterialApp(), //Replace with your MyApp() or any widget uses
    usingDebugging: true, //By default uses -kDebugMode- if need show it on release mode make it true
  );
}
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
