// app_state_manager.dart
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  bool _isAutoScrollEnabled = true;
  bool get isAutoScrollEnabled => _isAutoScrollEnabled;
  set isAutoScrollEnabled(bool value) {
    _isAutoScrollEnabled = value;
  }
}