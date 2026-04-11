class AlbumEntity {
  final String id;
  final String title;
  final String artistName;
  final String? coverUrl;
  final int? releaseYear;
  final String? description;
  final List<String> songIds;

  const AlbumEntity({
    required this.id,
    required this.title,
    required this.artistName,
    this.coverUrl,
    this.releaseYear,
    this.description,
    required this.songIds,
  });
}
