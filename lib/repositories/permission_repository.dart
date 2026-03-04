import '../core/services/api_client.dart';
import '../models/permission.dart';

class PermissionRepository {
  ApiClient _api;

  PermissionRepository({required ApiClient api}) : _api = api;

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
      final Object? next =
          cur['permissions'] ?? cur['items'] ?? cur['results'] ?? cur['data'];
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

  Future<List<Permission>> listAll() async {
    final Map<String, dynamic> res = await _api.getJson('/permissions');
    final List<Map<String, dynamic>> list = _extractList(res);

    return list
        .map(Permission.fromJson)
        .where((Permission p) => p.id.trim().isNotEmpty)
        .toList();
  }
}
