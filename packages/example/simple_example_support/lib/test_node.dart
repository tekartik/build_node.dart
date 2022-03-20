import 'package:tekartik_build_node/build_node.dart';

import 'build_node.dart';

Future main() async {
  await runNodeTest();
}

Future runNodeTest() async {
  await nodePackageRunTest(packageTop);
}
