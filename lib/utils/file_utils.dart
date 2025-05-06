import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:mime/mime.dart';

class FileUtils {
  /// Gets the file extension from a file path
  static String extension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Validates if the file type is supported
  static bool isValidFileType(String fileExtension) {
    final validExtensions = ['.pdf', '.doc', '.docx', '.txt'];
    return validExtensions.contains(fileExtension.toLowerCase());
  }

  /// Validates file size (max 5MB)
  static bool isValidFileSize(File file) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    return file.lengthSync() <= maxSizeInBytes;
  }

  /// Validates web file size (max 5MB)
  static bool isValidWebFileSize(Uint8List fileBytes) {
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    return fileBytes.length <= maxSizeInBytes;
  }

  /// Validates a file before upload
  static void validateFile(String filePath, {File? file, Uint8List? bytes}) {
    final fileExtension = extension(filePath);

    if (!isValidFileType(fileExtension)) {
      throw Exception(
        'Unsupported file type. Please upload PDF, DOC, DOCX, or TXT files.',
      );
    }

    if (kIsWeb && bytes != null) {
      if (!isValidWebFileSize(bytes)) {
        throw Exception('File size exceeds the 5MB limit.');
      }
    } else if (file != null) {
      if (!isValidFileSize(file)) {
        throw Exception('File size exceeds the 5MB limit.');
      }
    }
  }

  /// Gets MIME type from file extension
  static String getMimeType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType ?? 'application/octet-stream';
  }

  /// Formats file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Gets a user-friendly name for a file type
  static String getFileTypeName(String filePath) {
    final ext = extension(filePath).toLowerCase();

    switch (ext) {
      case '.pdf':
        return 'PDF Document';
      case '.doc':
      case '.docx':
        return 'Word Document';
      case '.txt':
        return 'Text Document';
      default:
        return 'Unknown File Type';
    }
  }

  /// Gets an appropriate icon name for a file type
  static String getFileIconName(String filePath) {
    final ext = extension(filePath).toLowerCase();

    switch (ext) {
      case '.pdf':
        return 'pdf';
      case '.doc':
      case '.docx':
        return 'word';
      case '.txt':
        return 'text';
      default:
        return 'file';
    }
  }

  /// Generates a unique filename using timestamp
  static String generateUniqueFilename(String originalFilename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = extension(originalFilename);
    final baseName = path.basenameWithoutExtension(originalFilename);

    return '${baseName}_$timestamp$ext';
  }

  /// Gets the file name from a file path
  static String basename(String filePath) {
    return path.basename(filePath);
  }
}
