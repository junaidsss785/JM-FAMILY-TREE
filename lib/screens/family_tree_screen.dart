import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import '../models/person.dart';
import '../data/family_data.dart';
import '../widgets/person_box.dart';

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<Person> members = [];
  bool loading = true;
  String? highlightId;
  final double boxWidth = 130;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('family_data');
    if (data != null) {
      final List decoded = jsonDecode(data);
      members = decoded.map((e) => Person.fromJson(e)).toList();
    } else {
      members = List.from(initialFamilyMembers);
      await _saveData();
    }
    setState(() => loading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(members.map((e) => e.toJson()).toList());
    await prefs.setString('family_data', data);
  }

  Map<String, Offset> _calculatePositions() {
    final Map<String, Offset> positions = {};
    Map<String, int> depth = {};
    for (var m in members) {
      depth[m.id] = _getDepth(m, members);
    }
    Map<int, List<Person>> byDepth = {};
    for (var m in members) {
      final d = depth[m.id]!;
      byDepth.putIfAbsent(d, () => []).add(m);
    }
    byDepth.forEach((d, list) {
      double totalWidth = list.length * (boxWidth + 20);
      double startX = -totalWidth / 2;
      for (int i = 0; i < list.length; i++) {
        final x = startX + i * (boxWidth + 20) + boxWidth / 2;
        final y = d * 130.0 + 50;
        positions[list[i].id] = Offset(x, y);
      }
    });
    return positions;
  }

  int _getDepth(Person p, List<Person> all) {
    int d = 0;
    String? pid = p.parentId;
    while (pid != null) {
      d++;
      final parent = all.firstWhere(
        (m) => m.id == pid,
        orElse: () => Person(id: '', name: ''),
      );
      if (parent.id.isEmpty) break;
      pid = parent.parentId;
    }
    return d;
  }

  // ==================== SEARCH ====================
  void _showSearchDialog() {
    final searchCtrl = TextEditingController();
    List<Person> results = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Search Name / نام تلاش کریں'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Type name...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val.trim().isEmpty) {
                        results = [];
                      } else {
                        results = members
                            .where((m) => m.name
                                .toLowerCase()
                                .contains(val.toLowerCase().trim()))
                            .toList();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (results.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final p = results[i];
                        return ListTile(
                          leading: const Icon(Icons.person, color: Colors.teal),
                          title: Text(p.name),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              highlightId = p.id;
                            });
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted) {
                                setState(() => highlightId = null);
                              }
                            });
                          },
                        );
                      },
                    ),
                  )
                else if (searchCtrl.text.trim().isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No name found',
                        style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PDF ====================
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Sort members by depth (generation) for better organization
    final sortedMembers = List<Person>.from(members);
    sortedMembers.sort((a, b) {
      final da = _getDepth(a, members);
      final db = _getDepth(b, members);
      if (da != db) return da.compareTo(db);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Mughal Barlas Family Tree',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Complete Family Lineage',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.teal900, thickness: 2),
            pw.SizedBox(height: 10),

            // Info row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Members: ${members.length}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Generated: ${DateTime.now().toString().substring(0, 16)}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Name', "Father's Name", 'Generation'],
              data: List.generate(sortedMembers.length, (i) {
                final m = sortedMembers[i];
                final parent = m.parentId != null
                    ? members.firstWhere(
                        (x) => x.id == m.parentId,
                        orElse: () => Person(id: '', name: '-'),
                      )
                    : null;
                final gen = _getDepth(m, members) + 1;
                return [
                  '${i + 1}',
                  m.name,
                  parent?.name ?? '-',
                  'Gen $gen',
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 12,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal900),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(60),
              },
            ),

            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Mughal Barlas Family Tree © ${DateTime.now().year}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Show print/save dialog - user can choose page size, printer, or save as PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Mughal_Barlas_Family_Tree.pdf',
    );
  }

  // ==================== ADD/EDIT DIALOG ====================
  void _showAddEditDialog({Person? person}) {
    final nameCtrl = TextEditingController(text: person?.name ?? '');
    String? selectedParent = person?.parentId;
    String selectedColor = person?.branchColor ?? 'teal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(person == null ? 'Add New Member' : 'Edit Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name / نام'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedParent,
                  decoration: const InputDecoration(labelText: 'Father / والد'),
                  items: members
                      .where((m) => person == null || m.id != person.id)
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedParent = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(labelText: 'Branch Color'),
                  items: const [
                    DropdownMenuItem(value: 'red', child: Text('Red / سرخ')),
                    DropdownMenuItem(value: 'blue', child: Text('Blue / نیلا')),
                    DropdownMenuItem(value: 'green', child: Text('Green / سبز')),
                    DropdownMenuItem(value: 'orange', child: Text('Orange / نارنجی')),
                    DropdownMenuItem(value: 'purple', child: Text('Purple / جامنی')),
                    DropdownMenuItem(value: 'teal', child: Text('Teal / ٹیل')),
                    DropdownMenuItem(value: 'pink', child: Text('Pink / گلابی')),
                    DropdownMenuItem(value: 'amber', child: Text('Amber / سنہری')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedColor = v!),
                ),
              ],
            ),
          ),
          actions: [
            if (person != null)
              TextButton(
                onPressed: () {
                  setState(() => members.removeWhere((m) => m.id == person.id));
                  _saveData();
                  Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  if (person == null) {
                    members.add(Person(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      parentId: selectedParent,
                      branchColor: selectedColor,
                    ));
                  } else {
                    final idx = members.indexWhere((m) => m.id == person.id);
                    members[idx] = Person(
                      id: person.id,
                      name: nameCtrl.text.trim(),
                      parentId: selectedParent,
                      branchColor: selectedColor,
                    );
                  }
                });
                _saveData();
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final positions = _calculatePositions();
    final Map<String, String?> parents = {
      for (var m in members) m.id: m.parentId
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mughal Barlas Family Tree'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(1000),
        minScale: 0.1,
        maxScale: 3.0,
        child: SizedBox(
          width: 3000,
          height: 5000,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(3000, 5000),
                painter: _LinesPainter(positions: positions, parents: parents),
              ),
              ...members.map((m) {
                final pos = positions[m.id];
                if (pos == null) return const SizedBox();
                final parent = m.parentId != null
                    ? members.firstWhere(
                        (x) => x.id == m.parentId,
                        orElse: () => Person(id: '', name: ''),
                      )
                    : null;
                return Positioned(
                  left: pos.dx + 1500 - boxWidth / 2,
                  top: pos.dy,
                  child: PersonBox(
                    person: m,
                    parent: parent?.id.isEmpty == true ? null : parent,
                    isHighlighted: highlightId == m.id,
                    onTap: () => _showAddEditDialog(person: m),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade800,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final Map<String, Offset> positions;
  final Map<String, String?> parents;

  _LinesPainter({required this.positions, required this.parents});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    parents.forEach((childId, parentId) {
      if (parentId != null &&
          positions.containsKey(childId) &&
          positions.containsKey(parentId)) {
        final child = positions[childId]!;
        final parent = positions[parentId]!;
        final cx = child.dx + 1500;
        final px = parent.dx + 1500;
        final path = Path();
        path.moveTo(px, parent.dy + 60);
        path.lineTo(px, (parent.dy + child.dy) / 2 + 30);
        path.lineTo(cx, (parent.dy + child.dy) / 2 + 30);
        path.lineTo(cx, child.dy);
        canvas.drawPath(path, paint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
