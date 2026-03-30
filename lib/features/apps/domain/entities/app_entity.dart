import 'dart:typed_data';

class AppEntity {
  final String name;
  final String packageName;
  final String? apkPath;
  final Uint8List? icon;
  final bool isCloned;

  const AppEntity({
    required this.name,
    required this.packageName,
    this.apkPath,
    this.icon,
    this.isCloned = false,
  });
}
