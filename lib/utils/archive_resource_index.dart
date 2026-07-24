import 'package:archive/archive.dart';

/// An image entry discovered while indexing an animation archive.
class ArchiveImageEntry {
  const ArchiveImageEntry({
    required this.file,
    required this.relativePath,
  });

  final ArchiveFile file;

  /// Path relative to the archive's `images/` directory.
  final String relativePath;
}

/// Single-pass index for locating Lottie files and image resources in an archive.
class ArchiveResourceIndex {
  ArchiveResourceIndex._({
    required Map<String, ArchiveFile> filesByPath,
    required Map<String, ArchiveImageEntry> imagesByRelativePath,
    required Map<String, ArchiveImageEntry> imagesByName,
    required this.imageEntries,
    required this.animationJson,
    required this.hasLottieSignature,
    required this.inspectedEntryCount,
  })  : _filesByPath = filesByPath,
        _imagesByRelativePath = imagesByRelativePath,
        _imagesByName = imagesByName;

  factory ArchiveResourceIndex.build(Archive archive) {
    final filesByPath = <String, ArchiveFile>{};
    final imagesByRelativePath = <String, ArchiveImageEntry>{};
    final imagesByName = <String, ArchiveImageEntry>{};
    final imageEntries = <ArchiveImageEntry>[];

    ArchiveFile? animationJson;
    var bestCandidatePriority = -1;
    var hasLottieSignature = false;
    var inspectedEntryCount = 0;

    for (final file in archive) {
      inspectedEntryCount++;
      final normalizedPath = normalizePath(file.name);
      final displayPath = _displayPath(file.name);

      if (!file.isFile || _isSystemEntry(normalizedPath)) {
        continue;
      }

      filesByPath.putIfAbsent(normalizedPath, () => file);

      final normalizedImageRelativePath = _imageRelativePath(normalizedPath);
      final imageRelativePath = _imageRelativePath(displayPath);
      if (imageRelativePath != null && imageRelativePath.isNotEmpty) {
        final imageEntry = ArchiveImageEntry(
          file: file,
          relativePath: imageRelativePath,
        );
        imageEntries.add(imageEntry);
        imagesByRelativePath.putIfAbsent(
          normalizedImageRelativePath!,
          () => imageEntry,
        );
        imagesByName.putIfAbsent(
          _basename(normalizedImageRelativePath),
          () => imageEntry,
        );
      }

      final candidatePriority = _animationCandidatePriority(normalizedPath);
      if (candidatePriority < 0) {
        continue;
      }

      if (_hasStandardLottieSignature(normalizedPath)) {
        hasLottieSignature = true;
      }

      // Strictly greater preserves archive order for equal-priority candidates.
      if (candidatePriority > bestCandidatePriority) {
        bestCandidatePriority = candidatePriority;
        animationJson = file;
      }
    }

    return ArchiveResourceIndex._(
      filesByPath: filesByPath,
      imagesByRelativePath: imagesByRelativePath,
      imagesByName: imagesByName,
      imageEntries: List.unmodifiable(imageEntries),
      animationJson: animationJson,
      hasLottieSignature: hasLottieSignature,
      inspectedEntryCount: inspectedEntryCount,
    );
  }

  final Map<String, ArchiveFile> _filesByPath;
  final Map<String, ArchiveImageEntry> _imagesByRelativePath;
  final Map<String, ArchiveImageEntry> _imagesByName;

  final List<ArchiveImageEntry> imageEntries;
  final ArchiveFile? animationJson;
  final bool hasLottieSignature;
  final int inspectedEntryCount;

  ArchiveFile? findByPath(String filePath) {
    return _filesByPath[normalizePath(filePath)];
  }

  /// Finds an image using its original Lottie `u` directory and `p` file name.
  ArchiveImageEntry? findImage(String? directory, String fileName) {
    final normalizedFileName = normalizePath(fileName);
    if (normalizedFileName.isEmpty) {
      return null;
    }

    if (directory != null && directory.isNotEmpty) {
      final combinedPath = normalizePath('$directory/$fileName');
      final relativeCombinedPath = _imageRelativePath(combinedPath);
      final exactPath = relativeCombinedPath ?? combinedPath;
      final exactMatch = _imagesByRelativePath[exactPath];
      if (exactMatch != null) {
        return exactMatch;
      }
    }

    final relativeMatch = _imagesByRelativePath[normalizedFileName];
    if (relativeMatch != null) {
      return relativeMatch;
    }

    return _imagesByName[_basename(normalizedFileName)];
  }

  static String normalizePath(String filePath) {
    return _displayPath(filePath).toLowerCase();
  }

  static String _displayPath(String filePath) {
    var normalized = filePath.replaceAll('\\', '/').trim();
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    while (normalized.contains('//')) {
      normalized = normalized.replaceAll('//', '/');
    }
    return normalized.startsWith('/') ? normalized.substring(1) : normalized;
  }

  static bool _isSystemEntry(String normalizedPath) {
    return normalizedPath == '__macosx' ||
        normalizedPath.startsWith('__macosx/') ||
        normalizedPath.startsWith('._') ||
        normalizedPath.contains('/._');
  }

  static int _animationCandidatePriority(String normalizedPath) {
    if (!normalizedPath.endsWith('.json') ||
        _basename(normalizedPath) == 'manifest.json') {
      return -1;
    }

    final basename = _basename(normalizedPath);
    if (basename == 'data.json') {
      return 400;
    }
    if (normalizedPath == 'animations/animation.json' ||
        normalizedPath.endsWith('/animations/animation.json')) {
      return 300;
    }
    if (normalizedPath.startsWith('animations/') ||
        normalizedPath.contains('/animations/')) {
      return 200;
    }
    return 100;
  }

  static bool _hasStandardLottieSignature(String normalizedPath) {
    if (!normalizedPath.endsWith('.json') ||
        _basename(normalizedPath) == 'manifest.json') {
      return false;
    }

    return _basename(normalizedPath) == 'data.json' ||
        normalizedPath.startsWith('animations/') ||
        normalizedPath.contains('/animations/') ||
        normalizedPath.contains('data');
  }

  static String? _imageRelativePath(String archivePath) {
    final normalizedPath = archivePath.toLowerCase();
    if (normalizedPath.startsWith('images/')) {
      return archivePath.substring('images/'.length);
    }

    const marker = '/images/';
    final markerIndex = normalizedPath.indexOf(marker);
    if (markerIndex < 0) {
      return null;
    }
    return archivePath.substring(markerIndex + marker.length);
  }

  static String _basename(String normalizedPath) {
    final separatorIndex = normalizedPath.lastIndexOf('/');
    return separatorIndex < 0
        ? normalizedPath
        : normalizedPath.substring(separatorIndex + 1);
  }
}
