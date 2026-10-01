class Person {
  final String id;
  final String name;
  final String? parentId;
  final String? branchColor;
  final double x;
  final double y;

  Person({
    required this.id,
    required this.name,
    this.parentId,
    this.branchColor,
    this.x = 0,
    this.y = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'branchColor': branchColor,
        'x': x,
        'y': y,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        parentId: json['parentId'] as String?,
        branchColor: json['branchColor'] as String?,
        x: (json['x'] ?? 0).toDouble(),
        y: (json['y'] ?? 0).toDouble(),
      );
}
