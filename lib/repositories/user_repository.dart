import '../core/services/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  ApiClient _api;

  UserRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
  }

  Future<Map<String, dynamic>> registerCreatedByMe({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String companyId,
    required String roleId,
    required bool isActive,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
      'companyId': companyId.trim(),
      'role': roleId.trim(),
      'isActive': isActive,
    };

    return _api.postJson(
      '/user/register/created-by-me',
      body: payload,
    );
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> res) {
    Object? cur = res['data'] ?? res;

    for (int i = 0; i < 4; i++) {
      if (cur is List) {
        return cur.whereType<Map<String, dynamic>>().toList();
      }
      if (cur is! Map<String, dynamic>) {
        return const <Map<String, dynamic>>[];
      }
      final Object? next =
          cur['users'] ?? cur['items'] ?? cur['results'] ?? cur['data'];
      if (next == null) {
        return const <Map<String, dynamic>>[];
      }
      cur = next;
    }

    if (cur is List) {
      return cur.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<UserModel>> listCreatedByMe() async {
    final Map<String, dynamic> res = await _api.getJson('/users/created-by-me');
    final List<Map<String, dynamic>> list = _extractList(res);
    return list
        .map(UserModel.fromJson)
        .where((UserModel u) => u.id.trim().isNotEmpty)
        .toList();
  }
}
