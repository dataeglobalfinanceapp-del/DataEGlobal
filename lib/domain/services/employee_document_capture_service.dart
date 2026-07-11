import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:savetep/domain/models/temporary_employee_document.dart';

abstract class EmployeeDocumentCaptureService {
  const EmployeeDocumentCaptureService();

  Future<TemporaryEmployeeDocument?> captureW4Photo();
}

class ImagePickerEmployeeDocumentCaptureService
    implements EmployeeDocumentCaptureService {
  final ImagePicker _picker;
  final DateTime Function() _clock;

  ImagePickerEmployeeDocumentCaptureService({
    ImagePicker? picker,
    DateTime Function()? clock,
  }) : _picker = picker ?? ImagePicker(),
       _clock = clock ?? DateTime.now;

  @override
  Future<TemporaryEmployeeDocument?> captureW4Photo() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final DateTime createdAt = _clock();
      final String mimeType = _mimeTypeFor(picked);
      return TemporaryEmployeeDocument(
        bytes: await picked.readAsBytes(),
        fileName: _fileNameFor(createdAt, mimeType),
        mimeType: mimeType,
        createdAt: createdAt,
      );
    } on PlatformException catch (error) {
      throw EmployeeDocumentCaptureException.fromPlatform(error);
    } catch (_) {
      throw const EmployeeDocumentCaptureException(
        'Unable to capture W4 photo.',
      );
    }
  }

  String _mimeTypeFor(XFile picked) {
    final String? mimeType = picked.mimeType;
    if (mimeType != null && mimeType.trim().isNotEmpty) {
      return mimeType.trim();
    }

    final String lowerName = picked.name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _fileNameFor(DateTime createdAt, String mimeType) {
    final String extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    return 'w4-photo-${createdAt.year}'
        '${_twoDigits(createdAt.month)}'
        '${_twoDigits(createdAt.day)}-'
        '${_twoDigits(createdAt.hour)}'
        '${_twoDigits(createdAt.minute)}'
        '${_twoDigits(createdAt.second)}.$extension';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class EmployeeDocumentCaptureException implements Exception {
  final String message;

  const EmployeeDocumentCaptureException(this.message);

  factory EmployeeDocumentCaptureException.fromPlatform(
    PlatformException error,
  ) {
    return switch (error.code) {
      'camera_access_denied' ||
      'camera_access_restricted' ||
      'camera_permission_denied' => const EmployeeDocumentCaptureException(
        'Camera permission is required to capture W4 photos.',
      ),
      _ => const EmployeeDocumentCaptureException(
        'Unable to capture W4 photo.',
      ),
    };
  }

  @override
  String toString() => message;
}
