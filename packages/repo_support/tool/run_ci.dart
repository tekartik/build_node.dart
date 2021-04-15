import 'package:path/path.dart';
import 'package:dev_test/package.dart';
import 'package:tekartik_build_node/package.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'build_node',
    'example/simple_example',
  ]) {
    var path = join(topDir, dir);
    await packageRunCi(path);
  }

  for (var dir in [
    'example/simple_example',
  ]) {
    var path = join(topDir, dir);
    await nodePackageRunCi(path);
  }
}
