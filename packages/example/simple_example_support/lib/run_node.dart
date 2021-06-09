import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'build_node.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''
node ${join(packageTop, 'build/node/main.dart.js')}
  ''');
}
