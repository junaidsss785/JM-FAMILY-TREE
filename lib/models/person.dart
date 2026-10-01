class Person {
  String id;
  String name;
  String fatherName;
  String branchColorName;
  List<String> childrenIds;
  double x;
  double y;

  Person({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.branchColorName,
    required this.childrenIds,
    this.x = 100.0,
    this.y = 100.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fatherName': fatherName,
      'branchColorName': branchColorName,
      'childrenIds': childrenIds,
      'x': x,
      'y': y,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      branchColorName: map['branchColorName'] ?? 'Blue',
      childrenIds: List<String>.from(map['childrenIds'] ?? []),
      x: (map['x'] as num?)?.toDouble() ?? 100.0,
      y: (map['y'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Person copyWith({
    String? id,
    String? name,
    String? fatherName,
    String? branchColorName,
    List<String>? childrenIds,
    double? x,
    double? y,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      branchColorName: branchColorName ?? this.branchColorName,
      childrenIds: childrenIds ?? this.childrenIds,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}
