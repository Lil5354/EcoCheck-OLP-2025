import 'package:flutter/material.dart';
import 'package:eco_check/core/di/injection_container.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/data/models/api_models.dart';

/// Backend Connection Test Page
class BackendTestPage extends StatefulWidget {
  const BackendTestPage({super.key});

  @override
  State<BackendTestPage> createState() => _BackendTestPageState();
}

class _BackendTestPageState extends State<BackendTestPage> {
  final _repository = sl<EcoCheckRepository>();

  bool _isLoading = false;
  String _result = '';
  Map<String, dynamic>? _healthData;
  Map<String, dynamic>? _statusData;
  List<Alert> _alerts = [];
  List<CheckinPoint> _checkins = [];
  List<Vehicle> _vehicles = [];
  AnalyticsSummary? _analytics;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Đang kiểm tra kết nối...';
    });

    try {
      // Test health
      final health = await _repository.checkHealth();
      setState(() {
        _healthData = health;
        _result =
            '✅ Kết nối backend thành công!\n${health['service']} - ${health['version']}';
      });

      // Load initial data
      await _loadAllData();
    } catch (e) {
      setState(() {
        _result = '❌ Lỗi kết nối: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllData() async {
    try {
      // Load status
      final status = await _repository.getStatus();
      setState(() => _statusData = status);

      // Load alerts
      final alerts = await _repository.getAlerts();
      setState(() => _alerts = alerts);

      // Load check-ins
      final checkins = await _repository.getCheckins(count: 10);
      setState(() => _checkins = checkins);

      // Load vehicles
      final vehicles = await _repository.getRealTimeVehicles();
      setState(() => _vehicles = vehicles);

      // Load analytics
      final analytics = await _repository.getAnalyticsSummary();
      setState(() => _analytics = analytics);
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _testCheckin() async {
    setState(() {
      _isLoading = true;
      _result = 'Đang gửi check-in...';
    });

    try {
      final request = CheckinRequest(
        routeId: 'route-demo-001',
        pointId: 'P1',
        vehicleId: 'V01',
      );

      final response = await _repository.postCheckin(request);

      setState(() {
        _result = '✅ Check-in thành công!\nStatus: ${response.status}';
      });

      // Reload data
      await _loadAllData();
    } catch (e) {
      setState(() {
        _result = '❌ Lỗi check-in: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
        backgroundColor: const Color(0xFF2ECC71),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _testConnection,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Connection Status
                  _buildCard(
                    title: '🔗 Connection Status',
                    child: Text(_result, style: const TextStyle(fontSize: 14)),
                  ),

                  // Health Data
                  if (_healthData != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '❤️ Health Check',
                      child: _buildJsonView(_healthData!),
                    ),
                  ],

                  // Status Data
                  if (_statusData != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '📊 API Status',
                      child: _buildJsonView(_statusData!),
                    ),
                  ],

                  // Analytics
                  if (_analytics != null) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '📈 Analytics Summary',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDataRow(
                            'Routes Active',
                            '${_analytics!.routesActive}',
                          ),
                          _buildDataRow(
                            'Collection Rate',
                            '${(_analytics!.collectionRate * 100).toStringAsFixed(1)}%',
                          ),
                          _buildDataRow(
                            'Today Tons',
                            '${_analytics!.todayTons} tons',
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Alerts
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '🚨 Alerts (${_alerts.length})',
                    child: _alerts.isEmpty
                        ? const Text('No alerts')
                        : Column(
                            children: _alerts.take(3).map((alert) {
                              return ListTile(
                                dense: true,
                                title: Text(alert.alertType),
                                subtitle: Text(
                                  '${alert.severity} - ${alert.status}',
                                ),
                                trailing: Text(
                                  '${alert.createdAt.hour}:${alert.createdAt.minute}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  // Check-ins
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '📍 Recent Check-ins (${_checkins.length})',
                    child: _checkins.isEmpty
                        ? const Text('No check-ins')
                        : Column(
                            children: _checkins.take(5).map((checkin) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  checkin.incident
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  color: checkin.incident
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                title: Text(
                                  '${checkin.type} - ${checkin.level}',
                                ),
                                subtitle: Text(
                                  '${checkin.lat.toStringAsFixed(4)}, ${checkin.lon.toStringAsFixed(4)}',
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  // Vehicles
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '🚛 Vehicles (${_vehicles.length})',
                    child: _vehicles.isEmpty
                        ? const Text('No vehicles')
                        : Column(
                            children: _vehicles.take(3).map((vehicle) {
                              return ListTile(
                                dense: true,
                                title: Text(vehicle.plate),
                                subtitle: Text(
                                  '${vehicle.type} - ${vehicle.status}',
                                ),
                                trailing: Text('${vehicle.capacity} kg'),
                              );
                            }).toList(),
                          ),
                  ),

                  // Test Check-in Button
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCheckin,
                    icon: const Icon(Icons.check_box),
                    label: const Text('Test Check-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadAllData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildJsonView(Map<String, dynamic> json) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: json.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}
