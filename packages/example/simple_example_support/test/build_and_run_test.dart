import 'package:dev_test/build_support.dart';
import 'package:test/test.dart';

import 'package:simple_example_support/run_node.dart' as run;
import 'package:simple_example_support/build_node.dart' as build;

void main() {
  group('node', () {
    test('build_and_run', () async {
      if (isNodeSupportedSync) {
        await run.main();
        await build.main();
      }
    });
  });
}
