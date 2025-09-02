class NewsItem {
  final int id;
  final String title;
  final String imageUrl;
  final String date; // dd/MM/yyyy vindo do ACF
  final String link; // opcional para uso futuro

  const NewsItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.link,
  });
}
