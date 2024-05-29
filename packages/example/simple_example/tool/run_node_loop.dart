import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''
node --watch build/node/loop.dart.js
  ''');
}
