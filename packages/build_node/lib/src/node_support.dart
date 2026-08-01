import 'package:process_run/shell.dart';

import 'npm_install.dart';

/// true if flutter is supported
final isNodeSupported = whichSync('node') != null;

/// Install node modules for test.
Future nodeModulesCheck(String dir) async {
  await nodePackageNpmInstall(dir);
}
