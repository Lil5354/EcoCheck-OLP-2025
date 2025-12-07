/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Worker - Socket.IO Service
 * Manages realtime WebSocket connections for route updates
 */

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

/// Socket.IO Service for realtime updates
class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  /// Connect to Socket.IO server
  void connect({required String userId}) {
    if (_isConnected && _socket != null) {
      if (kDebugMode) {
        print('🔌 Socket already connected');
      }
      return;
    }

    try {
      // Connect to backend Socket.IO server
      // Use Render production URL
      final baseUrl = ApiConstants.baseUrl;

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        if (kDebugMode) {
          print('✅ Socket.IO connected');
        }

        // Join driver room for personalized updates
        _socket!.emit('join', 'driver:$userId');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        if (kDebugMode) {
          print('🔌 Socket.IO disconnected');
        }
      });

      _socket!.onError((error) {
        if (kDebugMode) {
          print('❌ Socket.IO error: $error');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect Socket.IO: $e');
      }
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      if (kDebugMode) {
        print('🔌 Socket.IO disconnected');
      }
    }
  }

  /// Listen for new route events
  void onRouteNew(Function(dynamic) callback) {
    _socket?.on('route:new', (data) {
      if (kDebugMode) {
        print('🆕 Route new event: $data');
      }
      callback(data);
    });
  }

  /// Listen for route assigned events
  void onRouteAssigned(Function(dynamic) callback) {
    _socket?.on('route:assigned', (data) {
      if (kDebugMode) {
        print('📍 Route assigned event: $data');
      }
      callback(data);
    });
  }

  /// Listen for route started events
  void onRouteStarted(Function(dynamic) callback) {
    _socket?.on('route:started', (data) {
      if (kDebugMode) {
        print('▶️ Route started event: $data');
      }
      callback(data);
    });
  }

  /// Listen for route completed events
  void onRouteCompleted(Function(dynamic) callback) {
    _socket?.on('route:completed', (data) {
      if (kDebugMode) {
        print('✅ Route completed event: $data');
      }
      callback(data);
    });
  }

  /// Listen for route stop completed events
  void onRouteStopCompleted(Function(dynamic) callback) {
    _socket?.on('route:stop_completed', (data) {
      if (kDebugMode) {
        print('✅ Route stop completed event: $data');
      }
      callback(data);
    });
  }

  /// Remove all listeners
  void removeAllListeners() {
    _socket?.clearListeners();
  }

  /// Check if socket is connected
  bool get isConnected => _isConnected;
}
