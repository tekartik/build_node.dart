import 'package:args/command_runner.dart';
import 'package:tekartik_build_node/build_node.dart';

/// Command to execute pub run build_runner build.
class WatchCommand extends Command<int> {
  @override
  final name = 'watch';

  @override
  final description = 'Run builders and watch to build a package.';

  @override
  Future<int> run() async {
    var path = globalResults!['path'] as String;
    await nodePackageWatch(path, debug: true);
    return 0;
  }
}
