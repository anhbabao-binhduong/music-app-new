import 'package:equatable/equatable.dart';

class UserSearchResultEntity extends Equatable {
  final String id;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final String? website;
  final String? email;

  const UserSearchResultEntity({
    required this.id,
    this.name,
    this.avatarUrl,
    this.bio,
    this.location,
    this.website,
    this.email,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, bio, location, website, email];
}
