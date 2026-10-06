import 'package:flutter/services.dart';

abstract class NativeOverlayService {
  static const MethodChannel _channel = MethodChannel('com.bambam.driver/overlay');

  /// Forces MainActivity to come to front over lock screen / home screen and wake up device
  static Future<void> bringToForeground([Map<String, dynamic>? rideData]) async {
    try {
      await _channel.invokeMethod('bringToForeground', rideData);
      print('📱 [NATIVE] Driver app brought to foreground over lock screen / background!');
    } catch (e) {
      print('📱 [NATIVE] Error bringing driver app to foreground: $e');
    }
  }

  /// Disables lock screen flags so the app doesn't show over lock screen during normal usage
  static Future<void> disableLockScreenAlert() async {
    try {
      await _channel.invokeMethod('disableLockScreenAlert');
    } catch (_) {}
  }

  /// Checks if device is currently locked with keyguard
  static Future<bool> isDeviceLocked() async {
    try {
      final bool? locked = await _channel.invokeMethod<bool>('isDeviceLocked');
      return locked ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts Android Keyguard (PIN / Fingerprint / Pattern). Returns true if unlocked.
  static Future<bool> requestUnlockDevice() async {
    try {
      final bool? unlocked = await _channel.invokeMethod<bool>('requestUnlockDevice');
      return unlocked ?? true;
    } catch (e) {
      print('📱 [NATIVE] Error requesting device unlock: $e');
      return true;
    }
  }

  /// Checks if "Display over other apps" permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool? isGranted = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return isGranted ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens Android Settings for user to enable "Display over other apps"
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print('📱 [NATIVE] Error requesting overlay permission: $e');
    }
  }

  /// Retrieves pending action (e.g. ride accepted from native RideAlertActivity)
  static Future<Map<String, dynamic>?> getPendingAction() async {
    try {
      final res = await _channel.invokeMethod<dynamic>('getPendingAction');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      print('📱 [NATIVE] Error getting pending action: $e');
    }
    return null;
  }
}
