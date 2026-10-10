import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../timetable/timetable_providers.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });
}

class AuthNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final storage = ref.watch(storageProvider);
    final uid = storage.getUserId();
    if (uid == null) return null;
    return UserProfile(
      uid: uid,
      name: storage.getUserName() ?? 'Student',
      email: storage.getUserEmail() ?? '',
      photoUrl: storage.getUserPhotoUrl(),
    );
  }

  void setUser(UserProfile profile) {
    state = profile;
  }

  Future<void> signOut() async {
    final storage = ref.read(storageProvider);
    await AuthService.signOut(storage: storage);
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserProfile?>(AuthNotifier.new);
