import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:developer' as developer;
   class ReclamationSocketService {
     late io.Socket _socket;
     Function(Map<String, dynamic>)? onReclamationUpdate;

     ReclamationSocketService({required String userId}) {
       _socket = io.io(
         'http://10.0.2.2:3000/reclamations',
         io.OptionBuilder()
             .setTransports(['websocket'])
             .disableAutoConnect()
             .build(),
       );

       _socket.onConnect((_) {
         developer.log('Socket connected', name: 'ReclamationSocketService');
         _socket.emit('join', 'reclamation:$userId');
       });

       _socket.onDisconnect((_) {
         developer.log('Socket disconnected', name: 'ReclamationSocketService');
       });

       _socket.on('reclamationUpdate', (data) {
         developer.log('Received reclamationUpdate: $data',
             name: 'ReclamationSocketService');
         if (onReclamationUpdate != null) {
           onReclamationUpdate!(data);
         }
       });

       _socket.connect();
     }

     void disconnect() {
       _socket.disconnect();
     }
   }