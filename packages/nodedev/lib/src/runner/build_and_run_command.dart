import 'package:args/command_runner.dart';
import 'package:tekartik_build_node/build_node.dart';

import 'build_command.dart';
import 'run_command.dart';

/// Command to execute pub run build_runner build.
class BuildAndRunCommand extends Command<int>
    with RunCommandMixin<int>, BuildCommandMixin<int> {
  BuildAndRunCommand() {
    addBuildArgs();
    addRunArgs();
  }

  @override
  final name = 'bar';

  @override
  final description =
      'Build and run node app. (node/main.dart or bin/main.dart)';

  @override
  Future<int> run() async {
    var path = globalAppPath;
    var app = argApp;
    var debug = argDebug;
    await nodePackageBuild(path, debug: debug);
    await nodePackageRun(path, app: app);
    return 0;
  }
}
