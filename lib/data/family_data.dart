import '../models/person.dart';

final List<Person> initialFamilyMembers = [
  Person(id: 'p1', name: 'Tumanay Khan'),
  Person(id: 'p2', name: 'Qachuli', parentId: 'p1', branchColor: 'red'),
  Person(id: 'p3', name: 'Khabul Khan', parentId: 'p1', branchColor: 'blue'),
  Person(id: 'p4', name: 'Erdemchu Barlas', parentId: 'p2', branchColor: 'red'),
  Person(id: 'p5', name: 'Bartan Baghatur', parentId: 'p3', branchColor: 'blue'),
  Person(id: 'p6', name: 'Suqu Sechen', parentId: 'p4', branchColor: 'red'),
  Person(id: 'p7', name: 'Yesugei Baghatur', parentId: 'p5', branchColor: 'blue'),
  Person(id: 'p8', name: 'Qarachar Noyan', parentId: 'p6', branchColor: 'red'),
  Person(id: 'p9', name: 'Genghis Khan', parentId: 'p7', branchColor: 'blue'),
  Person(id: 'p10', name: 'Ichil', parentId: 'p8', branchColor: 'red'),
  Person(id: 'p11', name: 'Aylangir', parentId: 'p10', branchColor: 'red'),
  Person(id: 'p12', name: 'Barghul Noyan', parentId: 'p11', branchColor: 'red'),
  Person(id: 'p13', name: 'Taraghai Noyan', parentId: 'p12', branchColor: 'red'),
  Person(id: 'p14', name: 'Amir Taimur Barlas', parentId: 'p13', branchColor: 'red'),
];
