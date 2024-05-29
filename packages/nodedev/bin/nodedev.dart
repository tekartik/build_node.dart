import 'dart:io';

import 'package:tekartik_nodedev/src/runner/main_runner.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await run(arguments);
}
