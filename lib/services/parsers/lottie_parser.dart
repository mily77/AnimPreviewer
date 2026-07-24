import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:svga_previewer/models/animation_metadata.dart';
import 'package:svga_previewer/models/animation_type.dart';
import 'package:svga_previewer/models/frame_info.dart';
import 'package:svga_previewer/services/parsers/animation_parser.dart';
import 'package:svga_previewer/services/parsers/animation_parse_result.dart';
import 'package:svga_previewer/services/temp_file_manager.dart';
import 'package:svga_previewer/utils/archive_extractor.dart';
import 'package:svga_previewer/utils/archive_resource_index.dart';
import 'package:svga_previewer/utils/file_type_detector.dart';
import 'package:flutter/material.dart';

/// Lottie 动画解析器
/// 负责解析 Lottie 格式的动画文件，支持 .json, .lottie, .zip, .json.gz 格式
class LottieParser implements AnimationParser {
  @override
  bool canParse(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ext == '.json' ||
        ext == '.lottie' ||
        filePath.toLowerCase().endsWith('.json.gz') ||
        ext == '.zip';
  }

  @override
  Future<AnimationParseResult> parse(String filePath) async {
    print('开始处理新的Lottie文件: ${path.basename(filePath)}');

    try {
      // 清空图片缓存
      imageCache.clear();
      imageCache.clearLiveImages();
      print('图片缓存已清空');

      // 获取原始文件大小
      final originalFile = File(filePath);
      int fileSizeBytes = 0;
      if (await originalFile.exists()) {
        fileSizeBytes = await originalFile.length();
        print('Lottie文件大小: $fileSizeBytes bytes');
      }

      // 读取 Lottie JSON 内容（同时提取图片资源）
      print('开始读取 Lottie 文件内容...');
      final readResult =
          await _readLottieContent(filePath, extractImages: true);
      final jsonString = readResult.jsonContent;
      final lottieImagesDir = readResult.imagesDir;
      final archiveIndex = readResult.archiveIndex;
      print('JSON 内容长度: ${jsonString.length} 字符');

      // 先规范化 JSON，修复部分导出器生成的 effect 参数结构
      print('开始解析 JSON 数据...');
      Map<String, dynamic> lottieData;
      try {
        lottieData = json.decode(jsonString) as Map<String, dynamic>;
        print('JSON 解析成功，包含 ${lottieData.length} 个键');
      } catch (e) {
        print('JSON 解析失败: $e');
        print(
            'JSON 内容前 500 字符: ${jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length)}');
        rethrow;
      }

      final normalizedEffectCount = _normalizeEffectValueObjects(lottieData);
      final normalizedAssetCount =
          _normalizeImageAssetPaths(lottieData, lottieImagesDir, archiveIndex);
      final jsonWasNormalized =
          normalizedEffectCount > 0 || normalizedAssetCount > 0;
      final processedJsonString =
          jsonWasNormalized ? json.encode(lottieData) : jsonString;

      if (normalizedEffectCount > 0) {
        print('已修复 $normalizedEffectCount 个 effect 参数值结构');
      }
      if (normalizedAssetCount > 0) {
        print('已修复 $normalizedAssetCount 个图片资源路径');
      }

      // 如果是 ZIP/GZIP 格式，或者 JSON 被修复过，需要将 JSON 保存到临时文件
      final isCompressedJson = readResult.requiresTempFile;
      String? targetImagesDirPath; // 保存目标图片目录路径，供后续使用
      File? lottieJsonFile;

      if (isCompressedJson || jsonWasNormalized) {
        // 创建临时 JSON 文件
        lottieJsonFile =
            await TempFileManager.createTempJsonFile(processedJsonString);
        print('已将 Lottie JSON 保存到临时文件: ${lottieJsonFile.path}');

        // 如果提取了图片资源，需要先复制图片，然后再设置 lottieFile
        if (lottieImagesDir != null) {
          // 注意：Lottie 库会自动在 JSON 文件所在目录查找 images/ 文件夹
          // 所以我们需要将 images 文件夹复制到 JSON 文件所在目录
          final jsonDir = lottieJsonFile.parent;
          final targetImagesDir = Directory('${jsonDir.path}/images');
          targetImagesDirPath = targetImagesDir.path; // 保存路径供后续使用

          if (await Directory(lottieImagesDir).exists()) {
            // 如果目标目录已存在，先删除
            if (await targetImagesDir.exists()) {
              await targetImagesDir.delete(recursive: true);
            }

            // 复制图片目录（必须在设置 lottieFile 之前完成）
            print('开始复制图片资源...');
            print('源目录: $lottieImagesDir');
            print('目标目录: ${targetImagesDir.path}');
            await ArchiveExtractor.copyDirectory(
                Directory(lottieImagesDir), targetImagesDir);
            print('已将图片资源复制到: ${targetImagesDir.path}');

            // 验证图片是否复制成功
            if (await targetImagesDir.exists()) {
              final imageFiles = await targetImagesDir.list().toList();
              print('图片目录包含 ${imageFiles.length} 个文件/目录');
              for (final file in imageFiles.take(5)) {
                if (file is File) {
                  print('  - ${file.path} (${await file.length()} bytes)');
                }
              }
            } else {
              print('警告: 目标图片目录不存在: ${targetImagesDir.path}');
            }
          } else {
            print('警告: 源图片目录不存在: $lottieImagesDir');
          }
        } else {
          print('未提取到图片资源，跳过图片复制');
        }
      } else {
        // 直接使用原始文件
        lottieJsonFile = originalFile;
        print('使用原始 JSON 文件: ${originalFile.path}');
      }

      // 解析 Lottie 信息
      print('开始解析 Lottie 动画信息...');
      print('JSON 键列表: ${lottieData.keys.toList()}');

      final width = (lottieData['w'] as num?)?.toDouble() ?? 0.0;
      final height = (lottieData['h'] as num?)?.toDouble() ?? 0.0;
      final frameRate = (lottieData['fr'] as num?)?.toDouble() ?? 60.0;
      final inPoint = (lottieData['ip'] as num?)?.toInt() ?? 0;
      final outPoint = (lottieData['op'] as num?)?.toInt() ?? 0;

      print(
          '原始值 - w: $width, h: $height, fr: $frameRate, ip: $inPoint, op: $outPoint');

      final frameWidth = width.toInt();
      final frameHeight = height.toInt();
      final fps = frameRate > 0 ? frameRate : 60.0; // 确保 FPS 不为 0
      final totalFrames = outPoint > inPoint ? (outPoint - inPoint) : 0;
      // 计算时长，避免除以 0
      final duration = totalFrames > 0 && fps > 0 ? totalFrames / fps : 0.0;

      print(
          'Lottie信息: ${frameWidth}x$frameHeight, FPS: $fps, 总帧数: $totalFrames, 时长: $duration秒');

      // 验证关键信息
      if (frameWidth == 0 || frameHeight == 0) {
        print('警告: 宽度或高度为 0，可能是 JSON 格式问题');
      }
      if (totalFrames == 0) {
        print('警告: 总帧数为 0，可能是 JSON 格式问题');
      }

      // 创建临时目录
      final framesDir = await TempFileManager.getLottieFramesDirectory();
      print('创建新的临时目录: ${framesDir.path}');

      // 提取帧和图片资源
      final List<File> tempFrames = [];
      final List<FrameInfo> tempFrameInfos = [];
      double totalFileSizeBytes = 0;
      double memoryUsageMB = 0.0;

      print('开始处理 Lottie 图片资源...');

      // 如果提取了图片资源，将这些图片添加到帧列表中
      // 优先使用复制后的目标目录，如果没有则使用原始提取目录
      String? imagesDirToUse = targetImagesDirPath ?? lottieImagesDir;

      if (imagesDirToUse != null && await Directory(imagesDirToUse).exists()) {
        print('开始加载 images 文件夹中的图片...');
        print('使用图片目录: $imagesDirToUse');
        final imageFiles = await Directory(
          imagesDirToUse,
        ).list(recursive: true).toList();

        // 过滤出图片文件并按文件名排序
        final imageFileList = imageFiles.whereType<File>().where((file) {
          final ext = path.extension(file.path).toLowerCase();
          return ext == '.png' ||
              ext == '.jpg' ||
              ext == '.jpeg' ||
              ext == '.webp';
        }).toList();

        // 按文件名排序
        imageFileList.sort(
            (a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

        print('找到 ${imageFileList.length} 个图片文件');

        for (var imageFile in imageFileList) {
          try {
            // 读取图片信息
            final bytes = await imageFile.readAsBytes();
            final codec = await instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();

            // 计算内存占用
            final frameMemoryMB =
                (frame.image.width * frame.image.height * 4) / (1024 * 1024);
            memoryUsageMB += frameMemoryMB;

            // 获取文件大小
            final fileSizeBytes = await imageFile.length();
            totalFileSizeBytes += fileSizeBytes;

            // 添加到帧列表
            tempFrames.add(imageFile);

            // 创建帧信息
            final frameInfo = FrameInfo(
              file: imageFile,
              fileSizeBytes: fileSizeBytes,
              memoryUsageMB: frameMemoryMB,
              width: frame.image.width,
              height: frame.image.height,
            );
            tempFrameInfos.add(frameInfo);

            print(
                '添加图片: ${path.basename(imageFile.path)} (${frame.image.width}x${frame.image.height}, ${frameInfo.fileSizeText})');
          } catch (e) {
            print('处理图片 ${imageFile.path} 时出错: $e');
          }
        }
      }

      if (tempFrames.isEmpty) {
        print('未能从Lottie文件中提取到任何图片');
      } else {
        print('成功加载了 ${tempFrames.length} 个图片文件');
        final totalFileSizeMB = totalFileSizeBytes / (1024 * 1024);
        print('临时文件总大小: ${totalFileSizeMB.toStringAsFixed(1)} MB');
      }

      imageCache.clear();
      imageCache.clearLiveImages();
      print('再次清空图片缓存');

      // 创建元数据
      final metadata = AnimationMetadata(
        width: frameWidth,
        height: frameHeight,
        fps: fps,
        totalFrames: totalFrames,
        duration: duration,
        fileSizeBytes: fileSizeBytes,
        memoryUsageMB: memoryUsageMB,
        totalFileSizeMB: totalFileSizeBytes / (1024 * 1024),
      );

      return AnimationParseResult(
        animationType: AnimationType.lottie,
        metadata: metadata,
        animationFile: lottieJsonFile,
        frames: tempFrames,
        frameInfos: tempFrameInfos,
        lottieImagesDir: targetImagesDirPath ?? lottieImagesDir,
      );
    } catch (e) {
      print('处理Lottie文件时出错: $e');
      print(e.toString());
      rethrow;
    }
  }

  int _normalizeImageAssetPaths(
    Map<String, dynamic> lottieData,
    String? lottieImagesDir,
    ArchiveResourceIndex? archiveIndex,
  ) {
    if (!lottieData.containsKey('assets')) {
      return 0;
    }
    if (lottieImagesDir == null) {
      print('JSON 包含 assets，但未提取到 images 文件夹，保持原始路径');
      return 0;
    }

    final assets = lottieData['assets'] as List<dynamic>?;
    if (assets == null) {
      return 0;
    }

    print('检查 assets 中的图片路径，共 ${assets.length} 个资源...');
    var normalizedCount = 0;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;

      final p = asset['p'] as String?;
      final u = asset['u'] as String?;
      if (p == null) continue;

      final lowerP = p.toLowerCase();
      final isImage = lowerP.endsWith('.png') ||
          lowerP.endsWith('.jpg') ||
          lowerP.endsWith('.jpeg');
      if (!isImage) continue;

      var newPath = 'images/';
      final imageEntry = archiveIndex?.findImage(u, p);
      if (imageEntry != null && !p.contains('/') && !p.contains('\\')) {
        final relativePath = imageEntry.relativePath.replaceAll('\\', '/');
        final separatorIndex = relativePath.lastIndexOf('/');
        if (separatorIndex >= 0) {
          newPath = 'images/${relativePath.substring(0, separatorIndex + 1)}';
        }
      }
      if (u != newPath) {
        asset['u'] = newPath;
        normalizedCount++;
        print('更新图片路径: ${u ?? "(空)"} -> $newPath (文件: $p)');
      } else {
        print('图片路径已正确: $newPath$p');
      }
    }

    if (normalizedCount == 0) {
      print('未发现需要修复的图片资源路径');
    }
    return normalizedCount;
  }

  int _normalizeEffectValueObjects(Map<String, dynamic> lottieData) {
    final layers = lottieData['layers'] as List<dynamic>?;
    if (layers == null) {
      return 0;
    }

    var normalizedCount = 0;
    for (final layer in layers) {
      if (layer is! Map<String, dynamic>) continue;
      final effects = layer['ef'] as List<dynamic>?;
      if (effects == null) continue;

      for (final effect in effects) {
        normalizedCount += _normalizeEffectEntry(effect);
      }
    }
    return normalizedCount;
  }

  int _normalizeEffectEntry(dynamic entry) {
    if (entry is! Map<String, dynamic>) {
      return 0;
    }

    var normalizedCount = 0;
    final childEffects = entry['ef'] as List<dynamic>?;
    if (childEffects != null) {
      for (final child in childEffects) {
        normalizedCount += _normalizeEffectEntry(child);
      }
    }

    if (!entry.containsKey('v')) {
      return normalizedCount;
    }

    final value = entry['v'];
    if (value is num || value is bool || value is String) {
      entry['v'] = {
        'a': 0,
        'k': value,
      };
      normalizedCount++;
      print(
          '修复 effect 值结构: ${entry['nm'] ?? '(未命名)'} -> ${json.encode(entry['v'])}');
    }

    return normalizedCount;
  }

  /// 读取 Lottie 文件内容
  ///
  /// [filePath] 文件路径
  /// [extractImages] 是否提取图片资源
  /// 返回读取结果，包含 JSON 内容和图片目录路径
  Future<_LottieReadResult> _readLottieContent(String filePath,
      {bool extractImages = true}) async {
    final file = File(filePath);
    final signature = await FileTypeDetector.detectSignature(filePath);

    if (signature == AnimationFileFormat.lottieGzip) {
      // 处理 .json.gz 文件
      final bytes = await file.readAsBytes();
      final gzipDecoder = GZipDecoder();
      final decompressed = gzipDecoder.decodeBytes(bytes);
      if (!FileTypeDetector.isLottieJsonBytes(decompressed)) {
        throw Exception('GZIP 文件不是有效的 Lottie JSON');
      }
      return _LottieReadResult(
        jsonContent: FileTypeDetector.decodeJsonText(decompressed),
        imagesDir: null,
        requiresTempFile: true,
      );
    } else if (signature == AnimationFileFormat.lottieZip) {
      // 处理 .lottie 或 .zip 文件（ZIP 格式）
      print('开始处理 ZIP 格式文件: $filePath');
      final bytes = await file.readAsBytes();
      print('ZIP 文件大小: ${bytes.length} bytes');

      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
        print('ZIP 文件解压成功，包含 ${archive.length} 个文件');
      } catch (e) {
        print('ZIP 文件解压失败: $e');
        throw Exception('无法解压 ZIP 文件: $e');
      }

      final archiveIndex = ArchiveResourceIndex.build(archive);
      print('归档索引建立完成，单次扫描 ${archiveIndex.inspectedEntryCount} 个条目');

      // 提取图片资源（如果存在）
      String? lottieImagesDir;
      if (extractImages) {
        final lottieTempDir =
            await TempFileManager.getLottieExtractedDirectory();
        lottieImagesDir = await ArchiveExtractor.extractLottieImages(
          archive,
          lottieTempDir.path,
          index: archiveIndex,
        );
        if (lottieImagesDir != null) {
          print('已提取图片资源到: $lottieImagesDir');
        } else {
          print('ZIP 文件中没有图片资源');
        }
      }

      final animationJson = archiveIndex.animationJson;
      if (animationJson == null) {
        throw Exception('ZIP 文件不是有效的 Lottie 格式（未找到动画 JSON）');
      }
      if (animationJson.content is! List<int> ||
          !FileTypeDetector.isLottieJsonBytes(
              animationJson.content as List<int>)) {
        throw Exception('ZIP 文件不是有效的 Lottie 格式（动画 JSON 校验失败）');
      }
      final jsonContent = FileTypeDetector.decodeJsonText(
        animationJson.content as List<int>,
      );
      print('索引定位动画 JSON: ${animationJson.name}，大小: ${jsonContent.length} 字符');

      return _LottieReadResult(
        jsonContent: jsonContent,
        imagesDir: lottieImagesDir,
        archiveIndex: archiveIndex,
        requiresTempFile: true,
      );
    } else {
      // 直接读取 .json 文件
      final bytes = await file.readAsBytes();
      if (!FileTypeDetector.isLottieJsonBytes(bytes)) {
        throw Exception('文件不是有效的 Lottie JSON');
      }
      return _LottieReadResult(
        jsonContent: FileTypeDetector.decodeJsonText(bytes),
        imagesDir: null,
        requiresTempFile: false,
      );
    }
  }
}

/// Lottie 读取结果
class _LottieReadResult {
  final String jsonContent;
  final String? imagesDir;
  final ArchiveResourceIndex? archiveIndex;
  final bool requiresTempFile;

  _LottieReadResult({
    required this.jsonContent,
    required this.requiresTempFile,
    this.imagesDir,
    this.archiveIndex,
  });
}
