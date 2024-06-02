import 'package:process_run/shell.dart';

Future<void> main(List<String> args) async {
  await Shell().run('dart run build_runner build --delete-conflicting-outputs');
}
