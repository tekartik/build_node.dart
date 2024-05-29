import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:tekartik_nodedev/src/constant.dart';
import 'package:tekartik_nodedev/src/runner/build_and_run_command.dart';
import 'package:tekartik_nodedev/src/runner/build_command.dart';
import 'package:tekartik_nodedev/src/runner/run_command.dart';
import 'package:tekartik_nodedev/src/runner/watch_command.dart';
import 'package:tekartik_nodedev/src/version.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await run(arguments);
}
Future<int> run(List<String> args) async => (await MainRunner().run(args))!;

class MainRunner extends CommandRunner<int> {
  MainRunner() : super(appName, 'A tool to develop Dart node projects.') {
    argParser.addFlag('version',
        negatable: false, help: 'Prints the version of nodedev.');
    argParser.addOption(pathOptions, help: 'Path to the package.', defaultsTo: '.');

    addCommand(BuildCommand());
    addCommand(WatchCommand());
    addCommand(RunCommand());
    addCommand(BuildAndRunCommand());
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] as bool) {
      print(packageVersion);
      return 0;
    }

    // In the case of `help`, `null` is returned. Treat that as success.
    return await super.runCommand(topLevelResults) ?? 0;
  }
}