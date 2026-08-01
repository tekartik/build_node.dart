import 'package:args/command_runner.dart';
import 'package:tekartik_build_node/build_node.dart';

mixin NpmCommandMixin<T> on Command<T> {
  String get globalAppPath => globalResults!['path'] as String;

  void addRecursiveArg() {
    argParser.addFlag(
      'recursive',
      abbr: 'r',
      help: 'Find node packages recursively (use --no-recursive to disable).',
      defaultsTo: true,
    );
  }

  bool get argRecursive => argResults!['recursive'] as bool;
}

/// Command to run npm install recursively.
class NpmInstallCommand extends Command<int> with NpmCommandMixin<int> {
  NpmInstallCommand() {
    addRecursiveArg();
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Run npm install even if node_modules already exists.',
      defaultsTo: false,
    );
  }

  @override
  final name = 'npm-install';

  @override
  final description =
      'Run npm install recursively (on every folder containing a package.json).';

  @override
  Future<int> run() async {
    var path = globalAppPath;
    var force = argResults!['force'] as bool;
    if (argRecursive) {
      await recursiveNodePackageNpmInstall([path], force: force);
    } else {
      await nodePackageNpmInstall(path, force: force);
    }
    return 0;
  }
}
