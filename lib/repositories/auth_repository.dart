class AuthRepository {
  const AuthRepository();

  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    return true;
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return true;
  }

  Future<void> signOut() async {}

  Future<void> sendPasswordResetLink({required String email}) async {}
}
