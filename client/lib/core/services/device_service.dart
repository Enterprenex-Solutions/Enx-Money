import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Native Device Metrics and Information Provider
class DeviceInfo {
  static const MethodChannel _channel = MethodChannel('com.enxmoney.app/device_info');
  static String? _cachedModel;

  /// Dynamically fetch the current device info using native device metrics (Build.MODEL / Build.MANUFACTURER)
  static Future<String> getModel() async {
    if (_cachedModel != null && _cachedModel!.isNotEmpty) {
      return _cachedModel!;
    }
    if (kIsWeb) {
      _cachedModel = 'Web Browser';
      return _cachedModel!;
    }
    try {
      if (Platform.isAndroid) {
        final String? model = await _channel.invokeMethod<String>('getModel');
        if (model != null && model.trim().isNotEmpty) {
          _cachedModel = model.trim();
          return _cachedModel!;
        }
      } else if (Platform.isIOS) {
        _cachedModel = 'Apple iPhone';
        return _cachedModel!;
      } else if (Platform.isWindows) {
        _cachedModel = 'Windows PC';
        return _cachedModel!;
      } else if (Platform.isMacOS) {
        _cachedModel = 'Apple Mac';
        return _cachedModel!;
      } else if (Platform.isLinux) {
        _cachedModel = 'Linux Workstation';
        return _cachedModel!;
      }
    } catch (_) {}

    _cachedModel = 'Android Device';
    return _cachedModel!;
  }
}

class DeviceService {
  static const String _deviceIdKey = 'enx_device_id';
  static const String _deviceNameKey = 'enx_device_name';

  static String? _cachedDeviceId;

  /// Retrieves or initializes a unique persistent device ID
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    _cachedDeviceId = id;
    return id;
  }

  /// Retrieves human-readable device name dynamically
  static Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    String? customName = prefs.getString(_deviceNameKey);
    if (customName != null && customName.isNotEmpty) {
      return customName;
    }

    final nativeModel = await DeviceInfo.getModel();
    if (nativeModel.isNotEmpty && nativeModel != 'Android Device' && nativeModel != 'Mobile Device') {
      return nativeModel;
    }

    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return nativeModel;
      if (Platform.isIOS) return 'Apple iPhone';
      if (Platform.isWindows) return 'Windows PC';
      if (Platform.isMacOS) return 'Apple Mac';
      if (Platform.isLinux) return 'Linux Workstation';
    } catch (_) {
      return 'Mobile Device';
    }
    return 'ENX Device';
  }

  /// Retrieves platform identifier (android, ios, web, windows, etc.)
  static String getDevicePlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      return 'unknown';
    }
    return 'unknown';
  }

  /// Bundles device metadata for auth requests
  static Future<Map<String, String>> getDevicePayload() async {
    final id = await getDeviceId();
    final name = await getDeviceName();
    final platform = getDevicePlatform();

    return {
      'deviceId': id,
      'deviceName': name,
      'devicePlatform': platform,
    };
  }
}
