import 'package:simple_example_support/run_node.dart' as run;
import 'package:simple_example_support/build_node.dart' as build;

Future main() async {
  await build.main();
  await run.main();
}
