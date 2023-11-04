import 'build_node.dart' as build;
import 'run_node.dart' as run;

Future main() async {
  await build.main();
  await run.main();
}
