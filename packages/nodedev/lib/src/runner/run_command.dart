import 'package:args/command_runner.dart';
import 'package:tekartik_build_node/build_node.dart';

mixin RunCommandMixin<T> on Command<T> {
  void addRunArgs() {
    argParser.addOption('app', abbr: 'a', help: 'app');
  }

  String? get argApp => argResults!['app'] as String?;
}

/// Command to execute pub run build_runner build.
class RunCommand extends Command<int> with RunCommandMixin<int> {
  RunCommand() {
    addRunArgs();
  }
  @override
  final name = 'run';

  @override
  final description = 'Run node app. (node/main.dart or bin/main.dart)';

  @override
  Future<int> run() async {
    var path = globalResults!['path'] as String;
    var app = argApp;
    await nodePackageRun(path, app: app);
    return 0;
  }
}
