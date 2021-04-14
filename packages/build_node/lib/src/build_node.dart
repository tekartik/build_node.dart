import 'dart:io';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:node_preamble/preamble.dart';

bool _checked = false;

Future nodeCheck() async {
  if (!_checked) {
    _checked = true;
    if (!(File('build.yaml').existsSync())) {
      stderr.writeln('Missing \'build.yaml\'');
    }
  }
}

/// Build for node, adding preamble for generated js files.
///
Future nodeBuild({String directory = 'node'}) async {
  await nodeCheck();
  var shell = Shell();
  await shell.run('''
pub run build_runner build --output=build/ $directory
''');

  var files = await Directory(join('build', directory))
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
