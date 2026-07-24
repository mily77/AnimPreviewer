import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:svga_previewer/services/parsers/lottie_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp('lottie_parser_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return tempDirectory.path;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('parses a ZIP containing the standard animations path', () async {
    final zipFile = await _writeZip(
      tempDirectory,
      'standard.zip',
      Archive()..addFile(_animationFile('animations/animation.json')),
    );

    final result = await LottieParser().parse(zipFile.path);

    expect(result.metadata.width, 120);
    expect(result.metadata.height, 80);
    expect(result.metadata.totalFrames, 30);
    expect(result.animationFile, isNotNull);
  });

  test('parses a ZIP whose extension does not identify its container',
      () async {
    final zipFile = await _writeZip(
      tempDirectory,
      'renamed.asset',
      Archive()..addFile(_animationFile('animations/animation.json')),
    );

    final result = await LottieParser().parse(zipFile.path);

    expect(result.metadata.width, 120);
    expect(result.metadata.height, 80);
  });

  test('parses GZIP JSON with a misleading extension', () async {
    final jsonBytes = _animationFile('data.json').content as List<int>;
    final gzipFile = await File('${tempDirectory.path}/compressed.asset')
        .writeAsBytes(GZipEncoder().encode(jsonBytes)!);

    final result = await LottieParser().parse(gzipFile.path);

    expect(result.metadata.width, 120);
    expect(result.metadata.totalFrames, 30);
  });

  test('repairs a nested image directory using the archive index', () async {
    final imageBytes = await File('web/favicon.png').readAsBytes();
    final archive = Archive()
      ..addFile(_animationFile(
        'data.json',
        assets: [
          {'id': 'image_0', 'u': 'wrong/', 'p': 'Hero.png'},
        ],
      ))
      ..addFile(ArchiveFile(
        'bundle/images/icons/Hero.png',
        imageBytes.length,
        imageBytes,
      ));
    final zipFile = await _writeZip(tempDirectory, 'nested.lottie', archive);

    final result = await LottieParser().parse(zipFile.path);
    final repairedJson = json.decode(
      await result.animationFile!.readAsString(),
    ) as Map<String, dynamic>;
    final assets = repairedJson['assets'] as List<dynamic>;
    final imageAsset = assets.single as Map<String, dynamic>;

    expect(imageAsset['u'], 'images/icons/');
    expect(result.frames, hasLength(1));
    expect(result.frameInfos.single.width, greaterThan(0));
    expect(result.metadata.memoryUsageMB, greaterThan(0));
    expect(
      File('${result.lottieImagesDir}/icons/Hero.png').exists(),
      completion(isTrue),
    );
  });

  test('rejects a ZIP without a Lottie signature', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('notes/readme.txt', 'not an animation'));
    final zipFile = await _writeZip(tempDirectory, 'invalid.zip', archive);

    expect(
      () => LottieParser().parse(zipFile.path),
      throwsA(
        predicate((error) => error.toString().contains('不是有效的 Lottie 格式')),
      ),
    );
  });
}

ArchiveFile _animationFile(
  String name, {
  List<Map<String, dynamic>> assets = const [],
}) {
  final content = utf8.encode(json.encode({
    'v': '5.7.0',
    'fr': 30,
    'ip': 0,
    'op': 30,
    'w': 120,
    'h': 80,
    'layers': <dynamic>[],
    'assets': assets,
  }));
  return ArchiveFile(name, content.length, content);
}

Future<File> _writeZip(
  Directory directory,
  String name,
  Archive archive,
) async {
  final bytes = ZipEncoder().encode(archive)!;
  return File('${directory.path}/$name').writeAsBytes(bytes);
}
