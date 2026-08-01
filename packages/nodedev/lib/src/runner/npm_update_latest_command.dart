import 'package:args/command_runner.dart';
import 'package:tekartik_build_node/build_node.dart';

import 'npm_install_command.dart';

/// Command to update npm dependencies to their latest version.
class NpmUpdateLatestCommand extends Command<int> with NpmCommandMixin<int> {
  NpmUpdateLatestCommand() {
    addRecursiveArg();
  }

  @override
  final name = 'npm-update-latest';

  @override
  final description =
      'Update npm dependencies to their latest version (recursively).';

  @override
  Future<int> run() async {
    var path = globalAppPath;
    if (argRecursive) {
      await recursiveNodePackageNpmUpdateLatest([path]);
    } else {
      await nodePackageNpmUpdateLatest(path);
    }
    return 0;
  }
}
