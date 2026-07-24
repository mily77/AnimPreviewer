import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:svga_previewer/models/animation_type.dart';
import 'package:svga_previewer/utils/archive_resource_index.dart';

enum AnimationFileFormat {
  svga(AnimationType.svga),
  lottieJson(AnimationType.lottie),
  lottieZip(AnimationType.lottie),
  lottieGzip(AnimationType.lottie);

  const AnimationFileFormat(this.animationType);

  final AnimationType animationType;
}

/// Detects animation files from signatures and validated content structures.
class FileTypeDetector {
  static const _headerLength = 64;

  /// Extension filtering is retained for file pickers only. Parsing must call
  /// [detect] so renamed or misleading files are checked by their content.
  static bool isSupportedAnimationFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ext == '.svga' ||
        ext == '.json' ||
        ext == '.lottie' ||
        filePath.toLowerCase().endsWith('.json.gz') ||
        ext == '.zip';
  }

  static Future<AnimationFileFormat> detect(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('文件不存在');
    }

    final length = await file.length();
    if (length == 0) {
      throw const FormatException('动画文件为空');
    }

    final signature = await detectSignature(filePath);
    final bytes = await file.readAsBytes();

    switch (signature) {
      case AnimationFileFormat.lottieZip:
        if (_isLottieArchive(bytes)) {
          return AnimationFileFormat.lottieZip;
        }
        throw const FormatException('ZIP 文件不是有效的 Lottie 格式');
      case AnimationFileFormat.lottieGzip:
        try {
          final decoded = GZipDecoder().decodeBytes(bytes);
          if (isLottieJsonBytes(decoded)) {
            return AnimationFileFormat.lottieGzip;
          }
        } catch (_) {
          // Report one stable format error below.
        }
        throw const FormatException('GZIP 文件不是有效的 Lottie JSON');
      case AnimationFileFormat.lottieJson:
        if (isLottieJsonBytes(bytes)) {
          return AnimationFileFormat.lottieJson;
        }
        throw const FormatException('JSON 文件不是有效的 Lottie 动画');
      case AnimationFileFormat.svga:
      case null:
        if (_isSvga(bytes)) {
          return AnimationFileFormat.svga;
        }
        throw const FormatException('无法识别动画文件格式');
    }
  }

  /// Reads only the leading bytes and returns a container candidate. A result
  /// is not considered valid until [detect] performs structural validation.
  static Future<AnimationFileFormat?> detectSignature(String filePath) async {
    final file = File(filePath);
    final length = await file.length();
    final header = await file
        .openRead(0, math.min(length, _headerLength))
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));

    if (_hasZipSignature(header)) {
      return AnimationFileFormat.lottieZip;
    }
    if (_startsWith(header, const [0x1f, 0x8b])) {
      return AnimationFileFormat.lottieGzip;
    }
    if (_looksLikeJson(header)) {
      return AnimationFileFormat.lottieJson;
    }
    if (_hasZlibHeader(header)) {
      return AnimationFileFormat.svga;
    }
    return null;
  }

  static bool isLottieJsonBytes(List<int> bytes) {
    try {
      final decoded = json.decode(decodeJsonText(bytes));
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      return decoded['v'] is String &&
          decoded['fr'] is num &&
          decoded['ip'] is num &&
          decoded['op'] is num &&
          decoded['w'] is num &&
          decoded['h'] is num &&
          decoded['layers'] is List;
    } catch (_) {
      return false;
    }
  }

  static String decodeJsonText(List<int> bytes) {
    final text = utf8.decode(bytes);
    return text.startsWith('\ufeff') ? text.substring(1) : text;
  }

  static bool isLottieZip(
    Archive archive, {
    ArchiveResourceIndex? index,
  }) {
    final resourceIndex = index ?? ArchiveResourceIndex.build(archive);
    return resourceIndex.hasLottieSignature;
  }

  static String? getAnimationType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    if (ext == '.svga') {
      return 'svga';
    }
    if (ext == '.json' ||
        ext == '.lottie' ||
        filePath.toLowerCase().endsWith('.json.gz') ||
        ext == '.zip') {
      return 'lottie';
    }
    return null;
  }

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  static bool _isLottieArchive(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final index = ArchiveResourceIndex.build(archive);
      final animationJson = index.animationJson;
      if (animationJson == null || animationJson.content is! List<int>) {
        return false;
      }
      return isLottieJsonBytes(animationJson.content as List<int>);
    } catch (_) {
      return false;
    }
  }

  static bool _isSvga(List<int> bytes) {
    try {
      final inflated = const ZLibDecoder().decodeBytes(bytes);
      final movie = MovieEntity.fromBuffer(inflated);
      return movie.hasParams() &&
          movie.version.isNotEmpty &&
          movie.params.viewBoxWidth > 0 &&
          movie.params.viewBoxHeight > 0 &&
          movie.params.fps > 0 &&
          movie.params.frames > 0;
    } catch (_) {
      return false;
    }
  }

  static bool _hasZipSignature(List<int> bytes) {
    return _startsWith(bytes, const [0x50, 0x4b, 0x03, 0x04]) ||
        _startsWith(bytes, const [0x50, 0x4b, 0x05, 0x06]) ||
        _startsWith(bytes, const [0x50, 0x4b, 0x07, 0x08]);
  }

  static bool _hasZlibHeader(List<int> bytes) {
    if (bytes.length < 2) {
      return false;
    }
    final cmf = bytes[0];
    final flg = bytes[1];
    return cmf & 0x0f == 8 && ((cmf << 8) + flg) % 31 == 0;
  }

  static bool _looksLikeJson(List<int> bytes) {
    var index = 0;
    if (_startsWith(bytes, const [0xef, 0xbb, 0xbf])) {
      index = 3;
    }
    while (index < bytes.length && _isWhitespace(bytes[index])) {
      index++;
    }
    return index < bytes.length &&
        (bytes[index] == 0x7b || bytes[index] == 0x5b);
  }

  static bool _isWhitespace(int byte) {
    return byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d;
  }

  static bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) {
      return false;
    }
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        return false;
      }
    }
    return true;
  }
}
