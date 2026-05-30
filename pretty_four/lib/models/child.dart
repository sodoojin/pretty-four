class Child {
  final String id;
  final String userId;
  final String name;
  final DateTime birthDate;
  final DateTime createdAt;

  const Child({
    required this.id,
    required this.userId,
    required this.name,
    required this.birthDate,
    required this.createdAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        birthDate: DateTime.parse(json['birthDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'birthDate': birthDate.toIso8601String().split('T')[0],
        'createdAt': createdAt.toIso8601String(),
      };
}
