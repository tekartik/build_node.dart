import 'package:args/command_runner.dart';
import 'package:tekartik_build_node/build_node.dart';

mixin BuildCommandMixin<T> on Command<T> {
  String get globalAppPath => globalResults!['path'] as String;

  void addBuildArgs() {
    argParser.addFlag(
      'debug',
      abbr: 'd',
      help: 'Debug mode',
      defaultsTo: false,
    );
  }

  bool get argDebug => argResults!['debug'] as bool;
}

/// Command to execute pub run build_runner build.
class BuildCommand extends Command<int> with BuildCommandMixin<int> {
  BuildCommand() {
    addBuildArgs();
  }
  @override
  final name = 'build';

  @override
  final description = 'Run builders to build a package.';

  @override
  Future<int> run() async {
    var path = globalAppPath;
    var debug = argDebug;
    await nodePackageBuild(path, debug: debug);
    return 0;
  }
}
