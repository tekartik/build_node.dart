import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:tekartik_build_node/build_node.dart';

var packageTop = join('..', 'simple_example');

Future main() async {
  await build();
}

Future build() async {
  await packageRunCi(packageTop,
      options: PackageRunCiOptions(pubGetOnly: true));
  await nodePackageBuild(packageTop);
}
