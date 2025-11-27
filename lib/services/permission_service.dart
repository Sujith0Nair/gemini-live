import 'package:permission_handler/permission_handler.dart';

/// A service that handles all permission requests and status checks.
class PermissionService {
  static const List<Permission> _requiredPermissions = [
    Permission.microphone,
  ];

  /// Checks the status of all required permissions.
  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final Map<Permission, PermissionStatus> statuses = {};

    for (final permission in _requiredPermissions) {
      final status = await permission.status;
      statuses[permission] = status;
    }

    return statuses;
  }

  /// Checks if a specific permission is granted.
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Checks if all required permissions are granted.
  Future<bool> areAllPermissionsGranted() async {
    final statuses = await checkAllPermissions();
    final allGranted = statuses.values.every((status) => status.isGranted);
    return allGranted;
  }

  /// Requests a specific permission.
  Future<PermissionStatus> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status;
  }

  /// Requests all required permissions.
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final Map<Permission, PermissionStatus> results = {};

    for (final permission in _requiredPermissions) {
      final status = await requestPermission(permission);
      results[permission] = status;
    }

    return results;
  }

  /// Opens the app settings.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Returns a list of all required permissions.
  List<Permission> getRequiredPermissions() {
    return List.unmodifiable(_requiredPermissions);
  }

  /// Returns a human-readable name for a given [Permission].
  String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Microphone';
      case Permission.camera:
        return 'Camera';
      case Permission.photos:
        return 'Photos';
      case Permission.notification:
        return 'Notifications';
      default:
        return permission.toString();
    }
  }

  /// Returns a human-readable description for a given [Permission].
  String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Required for voice conversation with AI';
      case Permission.camera:
        return 'Required for video features';
      case Permission.photos:
        return 'Required to save and share media';
      case Permission.notification:
        return 'Required for alerts and updates';
      default:
        return 'Required for app functionality';
    }
  }

  /// Returns an icon name for a given [Permission].
  String getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'mic';
      case Permission.camera:
        return 'camera_alt';
      case Permission.photos:
        return 'photo_library';
      case Permission.notification:
        return 'notifications';
      default:
        return 'settings';
    }
  }
}
