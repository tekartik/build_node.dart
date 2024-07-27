// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_common_utils/src/debug.dart';

void main() {
  print('Hello world');
  print('isDebug: $isDebug');
  print('${jsonPretty(debugEnvMap)}');
}
