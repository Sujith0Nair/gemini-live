import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gemini_live_app/services/permission_service.dart';
import 'package:gemini_live_app/application/live_screen.dart';

/// The initial screen of the application.
///
/// This screen is responsible for checking and requesting necessary permissions
/// before allowing the user to proceed to the [LiveScreen].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Checks the status of all required permissions.
  Future<void> _checkPermissions() async {
    setState(() => _checking = true);

    final statuses = await _permissionService.checkAllPermissions();

    setState(() {
      _permissionStatuses = statuses;
      _checking = false;
    });
  }

  /// Requests a single permission from the user.
  ///
  /// After the permission is requested, it re-checks all permissions to update
  /// the UI.
  Future<void> _requestSinglePermission(Permission permission) async {
    final status = await _permissionService.requestPermission(permission);

    // Add a small delay to let iOS update permission state
    await Future.delayed(const Duration(milliseconds: 500));

    // Recheck all permissions after delay
    final recheckStatuses = await _permissionService.checkAllPermissions();

    setState(() {
      _permissionStatuses = recheckStatuses;
    });

    if (status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_permissionService.getPermissionName(permission)} permission granted!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (status.isDenied) {
      await _permissionService.requestPermission(permission);
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_permissionService.getPermissionName(permission)} permission denied. Please enable it in Settings.',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Open Settings',
              textColor: Colors.white,
              onPressed: () {
                _permissionService.openSettings();
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// Navigates to the [LiveScreen].
  ///
  /// This method is called when all required permissions have been granted.
  /// After returning from the [LiveScreen], it refreshes the permission statuses.
  void _navigateToLive() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LiveScreen()));
    // Refresh permissions when returning
    _checkPermissions();
  }

  /// Returns `true` if all required permissions are granted.
  bool get _allPermissionsGranted {
    if (_permissionStatuses.isEmpty) return false;
    final allGranted = _permissionStatuses.values.every(
      (status) => status.isGranted,
    );
    return allGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Gemini Live',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Experience real-time voice conversations with AI',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
              const SizedBox(height: 48),
              const Text(
                'Required Permissions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              if (_checking)
                const Center(child: CircularProgressIndicator())
              else
                ..._buildPermissionItems(),
              const Spacer(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _allPermissionsGranted ? _navigateToLive : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allPermissionsGranted
                        ? const Color(0xFFA8C7FA)
                        : Colors.grey[800],
                    foregroundColor: _allPermissionsGranted
                        ? Colors.black
                        : Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Conversation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the list of permission items.
  List<Widget> _buildPermissionItems() {
    final permissions = _permissionService.getRequiredPermissions();
    return permissions.map((permission) {
      final status = _permissionStatuses[permission];
      final granted = status?.isGranted ?? false;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildPermissionItem(
          icon: _getIconData(permission),
          title: _permissionService.getPermissionName(permission),
          description: _permissionService.getPermissionDescription(permission),
          granted: granted,
          permission: permission,
        ),
      );
    }).toList();
  }

  /// Returns the appropriate icon for a given [Permission].
  IconData _getIconData(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return Icons.mic;
      case Permission.camera:
        return Icons.camera_alt;
      case Permission.photos:
        return Icons.photo_library;
      case Permission.notification:
        return Icons.notifications;
      default:
        return Icons.settings;
    }
  }

  /// Builds a single permission item widget.
  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required Permission permission,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted
              ? const Color(0xFFA8C7FA).withAlpha(76)
              : Colors.grey.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: granted
                  ? const Color(0xFFA8C7FA).withAlpha(51)
                  : Colors.grey.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: granted ? const Color(0xFFA8C7FA) : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (granted)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
          else
            ElevatedButton(
              onPressed: () => _requestSinglePermission(permission),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA8C7FA),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: const Size(70, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Grant',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
