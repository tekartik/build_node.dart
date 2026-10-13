import 'package:tekartik_build_node/package.dart';
import 'package:tekartik_build_node/src/run_ci.dart'
    show nodePackageRunCiTestPlatforms;
import 'package:test/test.dart';

void main() {
  group('run_ci', () {
    test('test platforms', () {
      List<String> platforms(
        NodePackageRunCiOptions options, {
        bool nodeSupported = true,
      }) =>
          nodePackageRunCiTestPlatforms(options, nodeSupported: nodeSupported);

      expect(platforms(NodePackageRunCiOptions()), ['vm', 'node']);
      expect(platforms(NodePackageRunCiOptions(), nodeSupported: false), [
        'vm',
      ]);
      // vm tests still run without node tests
      expect(platforms(NodePackageRunCiOptions(noNodeTest: true)), ['vm']);
      expect(platforms(NodePackageRunCiOptions(noVmTest: true)), ['node']);
      expect(
        platforms(NodePackageRunCiOptions(noVmTest: true, noNodeTest: true)),
        isEmpty,
      );
    });
  });
}
