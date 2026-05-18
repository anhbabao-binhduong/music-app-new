import '../../domain/entities/user_search_result_entity.dart';

class UserSearchResultModel extends UserSearchResultEntity {
  const UserSearchResultModel({
    required super.id,
    super.name,
    super.avatarUrl,
    super.bio,
    super.location,
    super.website,
    super.email,
  });

  factory UserSearchResultModel.fromMap(Map<String, dynamic> map) {
    return UserSearchResultModel(
      id: map['id'] as String,
      name: (map['display_name'] ?? map['name']) as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      location: map['location'] as String?,
      website: map['website_url'] as String?,
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'website_url': website,
      'email': email,
    };
  }
}
