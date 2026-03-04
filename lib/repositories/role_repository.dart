import '../core/services/api_client.dart';
import '../models/role.dart';

class RoleRepository {
  ApiClient _api;

  RoleRepository({required ApiClient api}) : _api = api;

  void updateApi(ApiClient api) {
    _api = api;
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
      final Object? next = cur['roles'] ?? cur['items'] ?? cur['results'] ?? cur['data'];
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

  Future<List<Role>> listCreatedByMe() async {
    final Map<String, dynamic> res = await _api.getJson('/roles/created-by-me');
    final List<Map<String, dynamic>> list = _extractList(res);

    return list
        .map(Role.fromJson)
        .where((Role r) => r.id.trim().isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _extractObject(Map<String, dynamic> res) {
    final Object? data = res['data'] ?? res;
    if (data is Map<String, dynamic>) return data;
    return const <String, dynamic>{};
  }

  Future<Role> registerCreatedByMe({
    required String name,
    required String description,
    required List<String> permissionIds,
  }) async {
    final Map<String, dynamic> res = await _api.postJson(
      '/roles/register/created-by-me',
      body: <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'permissions': permissionIds,
      },
    );

    final Map<String, dynamic> obj = _extractObject(res);
    final Role role = Role.fromJson(obj);
    if (role.id.trim().isEmpty) {
      throw const ApiClientException('Invalid role response');
    }
    return role;
  }
}
