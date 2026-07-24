import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svga_previewer/utils/archive_resource_index.dart';
import 'package:svga_previewer/utils/file_type_detector.dart';

void main() {
  group('ArchiveResourceIndex', () {
    test('selects candidates by priority instead of archive order', () {
      final archive = Archive()
        ..addFile(_jsonFile('fallback.json'))
        ..addFile(_jsonFile('animations/secondary.json'))
        ..addFile(_jsonFile('animations/animation.json'))
        ..addFile(_jsonFile('nested/data.json'));

      final index = ArchiveResourceIndex.build(archive);

      expect(index.animationJson?.name, 'nested/data.json');
      expect(index.inspectedEntryCount, archive.length);
      expect(index.hasLottieSignature, isTrue);
    });

    test('preserves archive order for equal-priority candidates', () {
      final archive = Archive()
        ..addFile(_jsonFile('animations/first.json'))
        ..addFile(_jsonFile('nested/animations/second.json'));

      final index = ArchiveResourceIndex.build(archive);

      expect(index.animationJson?.name, 'animations/first.json');
    });

    test('falls back to a non-manifest JSON for lottie archives', () {
      final archive = Archive()
        ..addFile(_jsonFile('manifest.json'))
        ..addFile(_jsonFile('__MACOSX/data.json'))
        ..addFile(_jsonFile('custom/scene.json'));

      final index = ArchiveResourceIndex.build(archive);

      expect(index.animationJson?.name, 'custom/scene.json');
      expect(index.hasLottieSignature, isFalse);
      expect(FileTypeDetector.isLottieZip(archive, index: index), isFalse);
    });

    test('normalizes paths and indexes nested images', () {
      final image = ArchiveFile('Bundle/Images/Icons/Hero.PNG', 3, [1, 2, 3]);
      final archive = Archive()
        ..addFile(_jsonFile('./DATA.JSON'))
        ..addFile(image);

      final index = ArchiveResourceIndex.build(archive);

      expect(index.findByPath(r'.\data.json'), isNotNull);
      expect(index.imageEntries.single.relativePath, 'Icons/Hero.PNG');
      expect(index.findImage('images/icons/', 'hero.png')?.file, same(image));
      expect(index.findImage(null, 'HERO.PNG')?.file, same(image));
    });

    test('inspects each entry once for a large archive', () {
      final archive = Archive();
      for (var i = 0; i < 1000; i++) {
        archive.addFile(ArchiveFile('assets/file_$i.bin', 1, [i % 255]));
      }
      archive.addFile(_jsonFile('animations/animation.json'));

      final index = ArchiveResourceIndex.build(archive);

      expect(index.inspectedEntryCount, 1001);
      expect(index.animationJson?.name, 'animations/animation.json');
    });
  });
}

ArchiveFile _jsonFile(String name) {
  final content = utf8.encode('{"v":"5.7.0"}');
  return ArchiveFile(name, content.length, content);
}
