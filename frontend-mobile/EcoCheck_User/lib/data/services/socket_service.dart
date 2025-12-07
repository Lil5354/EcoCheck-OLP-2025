/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:eco_check/core/constants/api_constants.dart';
import 'dart:async';

/// Socket.IO Service for real-time communication
class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for events
  final _scheduleUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _scheduleCompletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _pointsEarnedController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;

  // Streams
  Stream<Map<String, dynamic>> get scheduleUpdated =>
      _scheduleUpdatedController.stream;
  Stream<Map<String, dynamic>> get scheduleCompleted =>
      _scheduleCompletedController.stream;
  Stream<Map<String, dynamic>> get pointsEarned =>
      _pointsEarnedController.stream;

  /// Initialize and connect to Socket.IO server
  void connect({String? token, String? userId}) {
    if (_socket != null && _isConnected) {
      return; // Already connected
    }

    try {
      // Use Render production URL
      final baseUrl = ApiConstants.baseUrl;

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
            .setExtraHeaders(
              token != null ? {'Authorization': 'Bearer $token'} : {},
            )
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('✅ Socket.IO connected');

        // Set up event listeners
        _setupEventListeners();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('❌ Socket.IO disconnected');
      });

      _socket!.onError((error) {
        debugPrint('❌ Socket.IO error: $error');
        _isConnected = false;
      });

      // Set up event listeners even if not connected yet
      _setupEventListeners();
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

  /// Set up event listeners for real-time updates
  void _setupEventListeners() {
    if (_socket == null) return;

    // Schedule updated event
    _socket!.on('schedule:updated', (data) {
      if (data is Map) {
        _scheduleUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });

    // Schedule completed event
    _socket!.on('schedule:completed', (data) {
      if (data is Map) {
        _scheduleCompletedController.add(Map<String, dynamic>.from(data));
      }
    });

    // Points earned event
    _socket!.on('points:earned', (data) {
      if (data is Map) {
        _pointsEarnedController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  void dispose() {
    _scheduleUpdatedController.close();
    _scheduleCompletedController.close();
    _pointsEarnedController.close();
    disconnect();
  }
}
