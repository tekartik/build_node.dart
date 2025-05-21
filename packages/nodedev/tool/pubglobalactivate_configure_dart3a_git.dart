import 'package:process_run/shell.dart';

/// To run after push.
Future<void> main() async {
  await run(
    'dart pub global run pubglobalupdate --config-package tekartik_nodedev --source git --git-url https://github.com/tekartik/build_node.dart --git-path packages/nodedev --git-ref dart3a',
  );
}
