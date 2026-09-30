class Person {
  final String id;
  final String name;
  final String? parentId;
  final String? branchColor;

  Person({
    required this.id,
    required this.name,
    this.parentId,
    this.branchColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'branchColor': branchColor,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        parentId: json['parentId'] as String?,
        branchColor: json['branchColor'] as String?,
      );
}
