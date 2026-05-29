// ignore: depend_on_referenced_packages
// ignore_for_file: avoid_print

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';

void main() {
  print('Hello world');
  print('isDebug: $isDebug');
  print('${jsonPretty(debugEnvMap)}');
}
