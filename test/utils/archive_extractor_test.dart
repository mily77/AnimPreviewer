import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svga_previewer/utils/archive_extractor.dart';
import 'package:svga_previewer/utils/archive_resource_index.dart';

void main() {
  test('extracts indexed root and nested images with original casing',
      () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'archive_extractor_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final archive = Archive()
      ..addFile(ArchiveFile('images/Root.PNG', 2, [1, 2]))
      ..addFile(ArchiveFile('bundle/Images/icons/Hero.webp', 3, [3, 4, 5]))
      ..addFile(ArchiveFile('other/ignored.png', 1, [6]));
    final index = ArchiveResourceIndex.build(archive);

    final imagesDirectory = await ArchiveExtractor.extractLottieImages(
      archive,
      tempDirectory.path,
      index: index,
    );

    expect(imagesDirectory, isNotNull);
    expect(
      File('${tempDirectory.path}/images/Root.PNG').readAsBytes(),
      completion([1, 2]),
    );
    expect(
      File('${tempDirectory.path}/images/icons/Hero.webp').readAsBytes(),
      completion([3, 4, 5]),
    );
    expect(
      File('${tempDirectory.path}/images/ignored.png').exists(),
      completion(isFalse),
    );
  });

  test('keeps the original no-images result', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'archive_extractor_empty_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final archive = Archive()
      ..addFile(ArchiveFile('data.json', 2, <int>[123, 125]));

    final result = await ArchiveExtractor.extractLottieImages(
      archive,
      tempDirectory.path,
    );

    expect(result, isNull);
  });
}
