part of 'playlist_cubit.dart';

abstract class PlaylistState {}

class PlaylistInitial extends PlaylistState {}

class PlaylistLoaded extends PlaylistState {
  final List<PlaylistModel> playlists;

  PlaylistLoaded(this.playlists);
}

class PlaylistError extends PlaylistState {
  final String message;

  PlaylistError(this.message);
}