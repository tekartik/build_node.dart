/// CI of a node enabled Dart package: [nodePackageRunCi] runs dev_build's
/// `packageRunCi` (pub get, format, analyze), then `dart test -p vm,node`.
library;

export 'src/run_ci.dart' show nodePackageRunCi, NodePackageRunCiOptions;
