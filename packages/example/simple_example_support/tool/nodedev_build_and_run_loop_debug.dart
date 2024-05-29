import 'package:process_run/shell.dart';

Future<void> main() async {
  var shell = Shell(workingDirectory: '../../nodedev');
  await shell.run('dart run bin/nodedev.dart --path ../example/simple_example bar --app node/loop.dart --debug');
}