import 'package:tekartik_build_node/build_node.dart';
import 'run_node.dart' as run;

Future main() async {
  await nodePackageBuild('.', debug: true);
  await run.main();
}
