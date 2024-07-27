import 'package:tekartik_build_node/build_node.dart';

Future main() async {
  await nodePackageCompileJs('.', debug: true);
  // Compiled ./build/node/loop.dart.js 173434 bytes
  // Compiled ./build/node/main.dart.js 108693 bytes
}
