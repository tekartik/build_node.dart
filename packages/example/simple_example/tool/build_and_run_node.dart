import 'run_node.dart' as run;
import 'build_node.dart' as build;

Future main() async {
  await build.main();
  await run.main();
}
