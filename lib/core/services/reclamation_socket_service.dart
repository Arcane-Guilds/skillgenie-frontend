import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/models/reclamation_model.dart';
import '../../core/services/notification_service.dart';

class ReclamationSocketService {
  final SecureStorage _secureStorage;
  final NotificationService _notificationService;
  io.Socket? _socket;
  Function(Reclamation)? onReclamationUpdate;

  ReclamationSocketService(this._secureStorage, this._notificationService);

  Future<void> initialize() async {
    final token = await _secureStorage.getToken();
    final userId = await _secureStorage.getUserId();
    if (token == null || userId == null) return;

    // Close existing socket if any
    _socket?.disconnect();

    _socket = io.io('${ApiConstants.baseUrl}/reclamations', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket?.onConnect((_) {
      print('Reclamation socket connected');
      // Subscribe to user-specific channel
      _socket?.emit('subscribe', 'reclamation:$userId');
    });

    _socket?.onDisconnect((_) {
      print('Reclamation socket disconnected');
    });

    _socket?.on('reclamationUpdate', (data) {
      final reclamation = Reclamation.fromJson(data);
      onReclamationUpdate?.call(reclamation);

      // Show notification if admin response was added
      if (reclamation.adminResponse != null && !reclamation.isRead) {
        _notificationService.showLocalNotification(
          title: 'Admin Response to Your Reclamation',
          body: reclamation.adminResponse ?? '',
          payload: reclamation.id,
        );
      }
    });

    _socket?.connect();
  }

  void dispose() {
    _socket?.disconnect();
    _socket = null;
  }
}
