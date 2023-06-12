import 'dart:io';

import 'package:node_preamble/preamble.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'node_support.dart';

bool _checked = false;

/// Local folder only
Future nodeCheck() async {
  if (!_checked) {
    _checked = true;
    await nodePackageCheck('.');
  }
}

/// Check a node package
Future nodePackageCheck(String path) async {
  if (!(File(join(path, 'build.yaml')).existsSync())) {
    stderr.writeln('Missing \'build.yaml\'');
  }
}

/// Build for node, adding preamble for generated js files.
///
Future nodeBuild({String directory = 'node'}) async {
  await nodePackageBuild('.', directory: directory);
}

/// Run local node tests
Future nodeRunTest() async {
  await nodePackageRunTest('.');
}

/// Build for node, adding preamble for generated js files.
///
Future<void> nodePackageBuild(String path, {String directory = 'node'}) async {
  await nodePackageCheck(path);
  var shell = Shell(workingDirectory: path);
  await shell.run('''
dart run build_runner build --release --output=build/ $directory
''');

  var files = await Directory(join(path, 'build', directory))
      .list()
      .where((event) => event.path.endsWith('dart.js'))
      .toList();
  var preamble = getPreamble(minified: true);
  for (var file in files) {
    var content = await File(file.path).readAsString();
    if (!content.startsWith(preamble)) {
      print(file);
      await File(file.path).writeAsString('''$preamble
$content''');
    }
  }
}

/// Run node test on a given package
Future nodePackageRunTest(String path) async {
  await nodePackageCheck(path);
  await nodeModulesCheck(path);
  var shell = Shell(workingDirectory: path);
  await shell.run('dart test -p node');
}
