import 'package:path/path.dart';
import 'package:tekartik_build_node/build_node.dart';

Future main() async {
  var path = join('..', 'simple_example');
  await nodePackageCompileJs(path);
  await nodePackageRun(path);
}
