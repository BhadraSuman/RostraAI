import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../timetable/timetable_providers.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? gender;
  final String? institution;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.gender,
    this.institution,
  });

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? gender,
    String? institution,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      institution: institution ?? this.institution,
    );
  }
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
      gender: storage.getUserGender(),
      institution: storage.getUserInstitution(),
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
