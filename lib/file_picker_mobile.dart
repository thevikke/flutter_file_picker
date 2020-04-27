import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

abstract class FilePickerInterface {
  FilePickerInterface._();
  static const String _tag = 'FilePicker';
  static const MethodChannel _channel = const MethodChannel('miguelruivo.flutter.plugins.file_picker');

  /// Returns an iterable `Map<String,String>` where the `key` is the name of the file
  /// and the `value` the path.
  ///
  /// A [fileExtension] can be provided to filter the picking results.
  /// If provided, it will be use the `FileType.CUSTOM` for that [fileExtension].
  /// If not, `FileType.ANY` will be used and any combination of files can be multi picked at once.
  static Future<Map<String, String>> getMultiFilePath({FileType type = FileType.any, String fileExtension}) async =>
      await _handlePicker(_handleType(type, fileExtension), true);

  /// Returns an absolute file path from the calling platform.
  ///
  /// A [type] must be provided to filter the picking results.
  /// Can be used a custom file type with `FileType.CUSTOM`. A [fileExtension] must be provided (e.g. PDF, SVG, etc.)
  /// Defaults to `FileType.ANY` which will display all file types.
  static Future<String> getFilePath({FileType type = FileType.any, String fileExtension}) async =>
      await _handlePicker(_handleType(type, fileExtension), false);

  /// Returns a `File` object from the selected file path.
  ///
  /// This is an utility method that does the same of `getFilePath()` but saving some boilerplate if
  /// you are planing to create a `File` for the returned path.
  static Future<File> getFile({FileType type = FileType.any, String fileExtension}) async {
    final String filePath = await _handlePicker(_handleType(type, fileExtension), false);
    return filePath != null ? File(filePath) : null;
  }

  /// Returns a `List<File>` object from the selected files paths.
  ///
  /// This is an utility method that does the same of `getMultiFilePath()` but saving some boilerplate if
  /// you are planing to create a list of `File`s for the returned paths.
  static Future<List<File>> getMultiFile({FileType type = FileType.any, String fileExtension}) async {
    final Map<String, String> paths = await _handlePicker(_handleType(type, fileExtension), true);
    return paths != null && paths.isNotEmpty ? paths.values.map((path) => File(path)).toList() : null;
  }

  static Future<dynamic> _handlePicker(String type, bool multipleSelection) async {
    try {
      var result = await _channel.invokeMethod(type, multipleSelection);
      if (result != null && multipleSelection) {
        if (result is String) {
          result = [result];
        }
        return Map<String, String>.fromIterable(result, key: (path) => path.split('/').last, value: (path) => path);
      }
      return result;
    } on PlatformException catch (e) {
      print('[$_tag] Platform exception: $e');
      rethrow;
    } catch (e) {
      print('[$_tag] Unsupported operation. Method not found. The exception thrown was: $e');
      rethrow;
    }
  }

  static String _handleType(FileType type, String fileExtension) {
    if (type != FileType.custom && (fileExtension?.isNotEmpty ?? false)) {
      throw Exception('If you are using a custom extension filter, please use the FileType.custom instead.');
    }
    switch (type) {
      case FileType.image:
        return 'IMAGE';
      case FileType.audio:
        return 'AUDIO';
      case FileType.video:
        return 'VIDEO';
      case FileType.any:
        return 'ANY';
      case FileType.custom:
        return '__CUSTOM_' + (fileExtension ?? '');
      default:
        return 'ANY';
    }
  }
}