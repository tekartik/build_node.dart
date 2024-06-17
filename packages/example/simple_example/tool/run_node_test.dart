import 'package:tekartik_build_node/build_node.dart';

Future main() async {
  await nodePackageRunTest('.', testFiles: ['test/simple_test.dart']);
}
