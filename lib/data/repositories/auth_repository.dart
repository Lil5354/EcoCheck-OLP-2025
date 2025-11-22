import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';
import '../services/mock_data_service.dart';

/// Repository cho xác thực - tách logic API/Storage ra khỏi BLoC
class AuthRepository {
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  /// Đăng nhập
  Future<Worker> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock validation
    if (email == 'worker@ecocheck.com' && password == '123456') {
      final worker = MockDataService.getCurrentWorker();

      // Save credentials
      await _prefs.setString('worker_id', worker.id);
      await _prefs.setString('worker_email', email);

      return worker;
    } else {
      throw Exception('Email hoặc mật khẩu không đúng');
    }
  }

  /// Auto login từ saved credentials
  Future<Worker?> autoLogin() async {
    final workerId = _prefs.getString('worker_id');

    if (workerId != null) {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      return MockDataService.getCurrentWorker();
    }

    return null;
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _prefs.remove('worker_id');
    await _prefs.remove('worker_email');
  }

  /// Cập nhật profile
  Future<Worker> updateProfile(Worker worker) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Call API to update worker profile
    // final response = await api.put('/workers/${worker.id}', data: worker.toJson());

    return worker;
  }
}
