class Product {
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final double rating;

  Product({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      description: json['description'] ?? '',
      price: json['price'].toDouble(),
      imageUrl: 'http://192.168.1.2:9090/' + json['image_url'],
      rating: json['rating'].toDouble(),
    );
  }
}
