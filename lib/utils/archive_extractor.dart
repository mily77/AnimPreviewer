import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:svga_previewer/utils/archive_resource_index.dart';

/// 归档文件提取工具
/// 用于从 ZIP 和 GZIP 归档中提取文件，特别是 Lottie 动画的资源文件
class ArchiveExtractor {
  /// 从 ZIP 归档中提取 Lottie 图片资源
  ///
  /// 支持嵌套目录结构（如 "folder/images/file.png"）
  /// 会将所有图片统一提取到目标目录的 images/ 文件夹中
  ///
  /// [archive] ZIP 归档对象
  /// [tempDirPath] 临时目录路径
  /// 返回提取的图片目录路径，如果没有图片则返回 null
  static Future<String?> extractLottieImages(
    Archive archive,
    String tempDirPath, {
    ArchiveResourceIndex? index,
  }) async {
    final imagesDir = Directory('$tempDirPath/images');
    final resourceIndex = index ?? ArchiveResourceIndex.build(archive);

    for (final imageEntry in resourceIndex.imageEntries) {
      final targetPath = path.join(
        tempDirPath,
        'images',
        imageEntry.relativePath,
      );
      final targetFile = File(targetPath);

      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      final content = imageEntry.file.content;
      if (content is List<int>) {
        await targetFile.writeAsBytes(content);
        print('提取图片资源: ${imageEntry.file.name} -> $targetPath');
      }
    }

    if (resourceIndex.imageEntries.isNotEmpty) {
      return imagesDir.path;
    }
    return null;
  }

  /// 递归复制目录
  ///
  /// [source] 源目录
  /// [target] 目标目录
  static Future<void> copyDirectory(Directory source, Directory target) async {
    if (!await target.exists()) {
      await target.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      final targetPath = path.join(target.path, path.basename(entity.path));
      if (entity is Directory) {
        await copyDirectory(entity, Directory(targetPath));
      } else if (entity is File) {
        await entity.copy(targetPath);
      }
    }
  }
}
