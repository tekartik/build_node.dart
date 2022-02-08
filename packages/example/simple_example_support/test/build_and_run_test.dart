import 'package:dev_test/build_support.dart';
import 'package:simple_example_support/build_node.dart' as build;
import 'package:simple_example_support/run_node.dart' as run;
import 'package:simple_example_support/test_node.dart';
import 'package:test/test.dart';

void main() {
  group('node', () {
    test('build_and_run', () async {
      await build.main();
      await run.main();
    }, timeout: Timeout(Duration(minutes: 5)));
    test('dart test -p node', () async {
      await runNodeTest();
    }, timeout: Timeout(Duration(minutes: 1)));
  }, skip: !isNodeSupportedSync ? 'Node not supported' : null);
}
