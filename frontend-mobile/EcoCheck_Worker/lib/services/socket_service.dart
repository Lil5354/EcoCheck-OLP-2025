/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:eco_check_worker/core/constants/api_constants.dart';
import 'dart:io';

/// Socket.IO Service for real-time communication
class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Initialize and connect to Socket.IO server
  void connect({String? token, String? userId}) {
    if (_socket != null && _isConnected) {
      return; // Already connected
    }

    try {
      // Use devBaseUrl for development, baseUrl for production
      final baseUrl = kDebugMode ? ApiConstants.devBaseUrl : ApiConstants.baseUrl;
      
      // Convert http/https to ws/wss for socket.io
      String socketUrl = baseUrl;
      if (baseUrl.startsWith('http://')) {
        socketUrl = baseUrl.replaceFirst('http://', 'ws://');
      } else if (baseUrl.startsWith('https://')) {
        socketUrl = baseUrl.replaceFirst('https://', 'wss://');
      }

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('✅ Socket.IO connected');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('❌ Socket.IO disconnected');
      });

      _socket!.onError((error) {
        debugPrint('❌ Socket.IO error: $error');
        _isConnected = false;
      });
    } catch (e) {
      debugPrint('❌ Error connecting to Socket.IO: $e');
      _isConnected = false;
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  /// Emit an event to the server
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      debugPrint('⚠️ Cannot emit: Socket not connected');
    }
  }

  /// Listen to an event from the server
  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    } else {
      debugPrint('⚠️ Cannot listen: Socket not initialized');
    }
  }

  /// Remove listener for an event
  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  /// Remove all listeners
  void offAll() {
    if (_socket != null) {
      _socket!.clearListeners();
    }
  }
  
  /// Remove all listeners (alias for offAll)
  void removeAllListeners() {
    offAll();
  }
  
  /// Listen for route stop completed event
  void onRouteStopCompleted(Function(dynamic) callback) {
    on('route:stop:completed', callback);
  }
  
  /// Listen for route started event
  void onRouteStarted(Function(dynamic) callback) {
    on('route:started', callback);
  }
  
  /// Listen for route completed event
  void onRouteCompleted(Function(dynamic) callback) {
    on('route:completed', callback);
  }
  
  /// Listen for new route event
  void onRouteNew(Function(dynamic) callback) {
    on('route:new', callback);
  }
  
  /// Listen for route assigned event
  void onRouteAssigned(Function(dynamic) callback) {
    on('route:assigned', callback);
  }
}

