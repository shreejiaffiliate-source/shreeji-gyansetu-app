class SliderModel {
  final String image;
  final String title;
  final String? link;

  SliderModel({required this.image, required this.title, this.link});

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      image: json['image'], // Django returns full URL if using Request context
      title: json['title'] ?? '',
      link: json['link'],
    );
  }
}