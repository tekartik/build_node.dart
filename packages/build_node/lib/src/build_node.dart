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
Future<void> _nodePackageBuild(String path, {String directory = 'node', bool? debug, String builder  = 'build'}) async {
  await nodePackageCheck(path);
  var shell = Shell(workingDirectory: path);
  await shell.run('''
dart run build_runner $builder ${(debug ?? false) ? ' --no-release' : ' --release'} --output=build/ $directory  --delete-conflicting-outputs --define=build_web_compilers:entrypoint=compiler=dart2js
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


/// Build for node, adding preamble for generated js files.
///
Future<void> nodePackageBuild(String path, {String directory = 'node', bool? debug}) async {
  await _nodePackageBuild(path, directory: directory, debug: debug);
}

/// Watch for node, adding preamble for generated js files.
///
Future<void> nodePackageWatch(String path, {String directory = 'node', bool? debug}) async {
  await _nodePackageBuild(path, directory: directory, debug: debug, builder: 'watch');
}
/// Run node test on a given package
Future nodePackageRunTest(String path) async {
  await nodePackageCheck(path);
  await nodeModulesCheck(path);
  var shell = Shell(workingDirectory: path);
  await shell.run('dart test -p node');
}

/// Run a node app.
Future<void> nodePackageRun(String path, {String? app}) async {
  app ??= () {
    if (File(join(path, 'node', 'main.dart')).existsSync()) {
      return 'node/main.dart';
    }
    if (File(join(path, 'bin', 'main.dart')).existsSync()) {
      return 'bin/main.dart';
    }
  } ();
  var shell = Shell(workingDirectory: path);
  await shell.run('node ${join('build', '$app.js')}');
}