import 'package:tekartik_build_node/build_node.dart';
import 'package:test/test.dart';

void main() {
  test('api', () {
    nodeCheck;
    nodePackageCheck;
    nodeBuild;
    nodePackageBuild;
    nodePackageRunTest;
    nodeRunTest;
  });
}
