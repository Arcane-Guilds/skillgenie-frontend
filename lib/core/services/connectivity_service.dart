import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';


/// Service that monitors and provides information about the device's network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool> connectionStatusController = StreamController<bool>.broadcast();
  bool _hasConnection = true;

  ConnectivityService() {
    // Initialize connection status
    _checkConnection();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((_) {
      _checkConnection();
    });
  }

  /// Initialize the connectivity stream
  Stream<bool> get connectionStatus => connectionStatusController.stream;

  /// Check if the device is currently connected to the internet
  Future<bool> get hasConnection async {
    await _checkConnection();
    return _hasConnection;
  }

  /// Check the current connection status and update the stream
  Future<void> _checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = _isConnected(result);

      if (_hasConnection != isConnected) {
        _hasConnection = isConnected;
        connectionStatusController.add(isConnected);
      }
    } catch (e) {
      connectionStatusController.add(false);
    }
  }

  /// Determine if the device is connected based on the connectivity result
  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  /// Dispose of resources
  void dispose() {
    connectionStatusController.close();
  }
}