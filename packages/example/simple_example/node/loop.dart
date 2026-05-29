// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/env_utils.dart';

Future<void> main() async {
  while (true) {
    // ignore: avoid_print
    print('isDebug: $isDebug');
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
