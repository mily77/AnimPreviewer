import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:svga_previewer/utils/file_type_detector.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('file_detector_');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('detects Lottie JSON when the extension is misleading', () async {
    final file =
        await _writeBytes(tempDirectory, 'animation.bin', _lottieJsonBytes());

    expect(
      FileTypeDetector.detect(file.path),
      completion(AnimationFileFormat.lottieJson),
    );
  });

  test('detects a Lottie ZIP from its signature and structure', () async {
    final archive = Archive()
      ..addFile(ArchiveFile(
        'animations/animation.json',
        _lottieJsonBytes().length,
        _lottieJsonBytes(),
      ));
    final file = await _writeBytes(
      tempDirectory,
      'animation.asset',
      ZipEncoder().encode(archive)!,
    );

    expect(
      FileTypeDetector.detect(file.path),
      completion(AnimationFileFormat.lottieZip),
    );
  });

  test('detects GZIP-compressed Lottie JSON without a gz extension', () async {
    final file = await _writeBytes(
      tempDirectory,
      'animation.download',
      GZipEncoder().encode(_lottieJsonBytes())!,
    );

    expect(
      FileTypeDetector.detect(file.path),
      completion(AnimationFileFormat.lottieGzip),
    );
  });

  test('detects a structurally valid SVGA payload', () async {
    final movie = MovieEntity(
      version: '2.0',
      params: MovieParams(
        viewBoxWidth: 120,
        viewBoxHeight: 80,
        fps: 30,
        frames: 60,
      ),
    );
    final file = await _writeBytes(
      tempDirectory,
      'animation.data',
      const ZLibEncoder().encode(movie.writeToBuffer()),
    );

    expect(
      FileTypeDetector.detect(file.path),
      completion(AnimationFileFormat.svga),
    );
  });

  test('rejects JSON without the required Lottie structure', () async {
    final file = await _writeBytes(
      tempDirectory,
      'notes.json',
      utf8.encode('{"message":"not an animation"}'),
    );

    expect(FileTypeDetector.detect(file.path), throwsFormatException);
  });

  test('rejects a ZIP without a valid Lottie animation JSON', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('notes/readme.txt', 'not an animation'));
    final file = await _writeBytes(
      tempDirectory,
      'invalid.zip',
      ZipEncoder().encode(archive)!,
    );

    expect(FileTypeDetector.detect(file.path), throwsFormatException);
  });
}

Future<File> _writeBytes(
  Directory directory,
  String name,
  List<int> bytes,
) {
  return File('${directory.path}/$name').writeAsBytes(bytes);
}

List<int> _lottieJsonBytes() {
  return utf8.encode(json.encode({
    'v': '5.7.0',
    'fr': 30,
    'ip': 0,
    'op': 30,
    'w': 120,
    'h': 80,
    'layers': <dynamic>[],
    'assets': <dynamic>[],
  }));
}
