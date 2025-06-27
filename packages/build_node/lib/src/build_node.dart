import 'package:process_run/stdio.dart';

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
Future<void> _nodePackageBuild(
  String path, {
  String directory = 'node',
  bool? debug,
  String builder = 'build',
}) async {
  await nodePackageCheck(path);
  var shell = Shell(workingDirectory: path);
  await shell.run('''
dart run build_runner $builder ${(debug ?? false) ? ' --no-release' : ' --release'} --output=build/ $directory  --delete-conflicting-outputs --define=build_web_compilers:entrypoint=compiler=dart2js
''');
  // [INFO] build_web_compilers:entrypoint on asset:tekartik_app_node_utils/bin/main.dart:Running
  // `dart compile js` with --enable-asserts
  // --libraries-spec=/opt/app/dart/stable-3.4.4/dart-sdk/lib/libraries.json
  // --packages=org-dartlang-app:///.dart_tool/package_config.json
  // --multi-root-scheme=org-dartlang-app
  // --multi-root=/tmp/scratch_spaceZPOZYI/
  // -obin/main.dart.js org-dartlang-app:///bin/main.dart
  var files = await Directory(
    join(path, 'build', directory),
  ).list().where((event) => event.path.endsWith('dart.js')).toList();
  for (var file in files) {
    await _addNodePreamble(file.path);
  }
}

var _minifiedPreamble = getPreamble(minified: true);

/// Add preamble to generated js files
Future<void> _addNodePreamble(String path) async {
  var file = File(path);
  var content = await file.readAsString();
  if (!content.startsWith(_minifiedPreamble)) {
    await file.writeAsString('''$_minifiedPreamble
$content''', flush: true);
    var size = file.statSync().size;
    stdout.writeln('Compiled $path $size bytes');
  }
}

Future<void> _nodePackageCompileJs(
  String path, {
  String? input,
  String? output,
  bool? debug,
  int? optimizationLevel,
}) async {
  input ??= join('node', 'main.dart');
  var inputDir = dirname(input);
  if (output == null) {
    if (!isRelative(input)) {
      throw ArgumentError('input should be relative');
    }
    output = join('build', inputDir, '${basename(input)}.js');
  }
  var shell = Shell(workingDirectory: path);

  optimizationLevel ??= (debug ?? false) ? 0 : 2;
  await Directory(dirname(output)).create(recursive: true);
  await shell.run(
    'dart compile js'
    ' --output ${shellArgument(output)} ${shellArgument(input)}'
    ' -O$optimizationLevel'
    '${debug ?? false ? ' --enable-asserts' : ''}',
  );
  await _addNodePreamble(normalize(join(path, output)));
}

/// Build for node, adding preamble for generated js files.
///
Future<void> nodePackageBuild(
  String path, {
  String directory = 'node',
  bool? debug,
}) async {
  await _nodePackageBuild(path, directory: directory, debug: debug);
}

/// Compile for node, adding preamble for generated js file.
///
/// * [input] default to node/main.dart
/// * [output] default to build/node/main.dart.js or build/<input>.js
/// * optimizationLevel: 0 to 4
Future<void> nodePackageCompileJs(
  String path, {
  String? input,
  String? output,
  bool? debug,
  int? optimizationLevel,
}) async {
  await _nodePackageCompileJs(
    path,
    input: input,
    output: output,
    debug: debug,
    optimizationLevel: optimizationLevel,
  );
}

/// Watch for node, adding preamble for generated js files.
///
Future<void> nodePackageWatch(
  String path, {
  String directory = 'node',
  bool? debug,
}) async {
  await _nodePackageBuild(
    path,
    directory: directory,
    debug: debug,
    builder: 'watch',
  );
}

/// Run node test on a given package
Future nodePackageRunTest(String path, {List<String>? testFiles}) async {
  await nodePackageCheck(path);
  await nodeModulesCheck(path);
  var shell = Shell(workingDirectory: path);
  await shell.run(
    'dart test -p node${testFiles != null ? ' ${testFiles.join(' ')}' : ''}',
  );
}

/// Run a node app. (app being the entry point or explicitly specified jsFile)
Future<void> nodePackageRun(String path, {String? app, String? jsFile}) async {
  var file =
      jsFile ??
      () {
        app ??= () {
          if (File(join(path, 'node', 'main.dart')).existsSync()) {
            return 'node/main.dart';
          }
          if (File(join(path, 'bin', 'main.dart')).existsSync()) {
            return 'bin/main.dart';
          }
          throw ArgumentError('No app found');
        }();
        return join('build', '$app.js');
      }();
  var shell = Shell(workingDirectory: path);
  await shell.run('node ${shellArgument(file)}');
}
