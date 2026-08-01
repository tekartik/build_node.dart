import 'package:args/command_runner.dart';
import 'package:process_run/stdio.dart';
import 'package:tekartik_build_node/build_node.dart';

import 'npm_install_command.dart';

/// Command to list the path of every package.json found.
class NpmListPathCommand extends Command<int> with NpmCommandMixin<int> {
  NpmListPathCommand() {
    addRecursiveArg();
  }

  @override
  final name = 'npm-list-path';

  @override
  final description =
      'List the relative path of every package.json found (recursively).';

  @override
  Future<int> run() async {
    var path = globalAppPath;
    if (argRecursive) {
      for (var relativePath in await recursiveNodePackageJsonRelativePaths(
        path,
      )) {
        stdout.writeln(relativePath);
      }
    } else if (isNodePackageRoot(path)) {
      stdout.writeln('package.json');
    }
    return 0;
  }
}
