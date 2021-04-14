import 'package:path/path.dart';
import 'package:dev_test/package.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'build_node',
    'example/simple_example',
  ]) {
    var path = join(topDir, dir);
    await packageRunCi(path);
  }
}
