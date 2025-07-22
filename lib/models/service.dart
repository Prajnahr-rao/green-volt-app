class Service {
  String? id;
  String name;
  String description;
  double price;
  String imageUrl;
  String category;

  Service({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.category = 'All',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      category: json['category'] ?? 'All',
    );
  }
}
