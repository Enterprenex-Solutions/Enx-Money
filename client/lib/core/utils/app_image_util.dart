import 'dart:io';
import 'package:flutter/material.dart';

/// Transparently returns an [ImageProvider] for either web URLs (http/https)
/// or local files selected from device storage, Google Drive, or camera.
ImageProvider? getAppImageProvider(String? pathOrUrl) {
  if (pathOrUrl == null) return null;
  final trimmed = pathOrUrl.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }

  try {
    final file = File(trimmed);
    return FileImage(file);
  } catch (_) {
    return null;
  }
}
