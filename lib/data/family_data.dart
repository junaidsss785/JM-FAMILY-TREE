import '../models/person.dart';

final List<Person> initialFamilyMembers = [
  Person(id: 'p1', name: 'Tumanay Khan', x: 0, y: 0),
  Person(id: 'p2', name: 'Qachuli', parentId: 'p1', branchColor: 'red', x: -120, y: 150),
  Person(id: 'p3', name: 'Khabul Khan', parentId: 'p1', branchColor: 'blue', x: 120, y: 150),
  Person(id: 'p4', name: 'Erdemchu Barlas', parentId: 'p2', branchColor: 'red', x: -120, y: 300),
  Person(id: 'p5', name: 'Bartan Baghatur', parentId: 'p3', branchColor: 'blue', x: 120, y: 300),
  Person(id: 'p6', name: 'Suqu Sechen', parentId: 'p4', branchColor: 'red', x: -120, y: 450),
  Person(id: 'p7', name: 'Yesugei Baghatur', parentId: 'p5', branchColor: 'blue', x: 120, y: 450),
  Person(id: 'p8', name: 'Qarachar Noyan', parentId: 'p6', branchColor: 'red', x: -120, y: 600),
  Person(id: 'p9', name: 'Genghis Khan', parentId: 'p7', branchColor: 'blue', x: 120, y: 600),
  Person(id: 'p10', name: 'Ichil', parentId: 'p8', branchColor: 'red', x: -120, y: 750),
  Person(id: 'p11', name: 'Aylangir', parentId: 'p10', branchColor: 'red', x: -120, y: 900),
  Person(id: 'p12', name: 'Barghul Noyan', parentId: 'p11', branchColor: 'red', x: -120, y: 1050),
  Person(id: 'p13', name: 'Taraghai Noyan', parentId: 'p12', branchColor: 'red', x: -120, y: 1200),
  Person(id: 'p14', name: 'Amir Taimur Barlas', parentId: 'p13', branchColor: 'red', x: -120, y: 1350),
];
