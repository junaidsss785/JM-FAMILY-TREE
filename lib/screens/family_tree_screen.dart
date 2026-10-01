import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:graphview/GraphView.dart';
import 'dart:convert';
import '../models/person.dart';
import '../data/family_data.dart';

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<Person> members = [];
  bool loading = true;
  String? highlightId;

  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = 30
      ..levelSeparation = 80
      ..subtreeSeparation = 50
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
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
    _buildGraph();
    setState(() => loading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(members.map((e) => e.toJson()).toList());
    await prefs.setString('family_data', data);
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();
    final Map<String, Node> nodeMap = {};

    for (var member in members) {
      final node = Node.Id(member.id);
      nodeMap[member.id] = node;
      graph.addNode(node);
    }

    for (var member in members) {
      if (member.parentId != null && nodeMap.containsKey(member.parentId)) {
        graph.addEdge(nodeMap[member.parentId]!, nodeMap[member.id]!);
      }
    }
  }

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red.shade400;
      case 'blue':
        return Colors.blue.shade400;
      case 'green':
        return Colors.green.shade400;
      case 'orange':
        return Colors.orange.shade400;
      case 'purple':
        return Colors.purple.shade400;
      case 'teal':
        return Colors.teal.shade400;
      case 'pink':
        return Colors.pink.shade400;
      case 'amber':
        return Colors.amber.shade600;
      default:
        return Colors.grey.shade400;
    }
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

  // ==================== MASTER BACKUP ====================
  Future<void> _showMasterBackupDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('master_password');

    if (savedPassword == null) {
      _showSetPasswordDialog(prefs);
    } else {
      _showPasswordOptionsDialog(prefs);
    }
  }

  void _showSetPasswordDialog(SharedPreferences prefs) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.teal),
            SizedBox(width: 8),
            Text('Set Master Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'یہ پاسورڈ Master Backup کے لیے ہے۔\nیاد رکھیں، بھول گئے تو ریکوری نہیں ہوگی۔',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final p1 = passCtrl.text.trim();
              final p2 = confirmCtrl.text.trim();
              if (p1.isEmpty || p1.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be 4+ characters')),
                );
                return;
              }
              if (p1 != p2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              await prefs.setString('master_password', p1);
              final data =
                  jsonEncode(members.map((e) => e.toJson()).toList());
              await prefs.setString('master_data', data);

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('✅ Master Backup created successfully!'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            },
            child: const Text('Set Default'),
          ),
        ],
      ),
    );
  }

  void _showPasswordOptionsDialog(SharedPreferences prefs) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.teal),
            SizedBox(width: 8),
            Text('Master Backup'),
          ],
        ),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.key),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final savedPassword = prefs.getString('master_password');
              if (passCtrl.text.trim() != savedPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Wrong password!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (mounted) {
                Navigator.pop(ctx);
                _showMasterActionsDialog(prefs);
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _showMasterActionsDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Master Backup Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save, color: Colors.teal),
              title: const Text('Update Master'),
              subtitle: const Text('Save current data as Master'),
              onTap: () async {
                final data =
                    jsonEncode(members.map((e) => e.toJson()).toList());
                await prefs.setString('master_data', data);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Master updated!'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Restore from Master'),
              subtitle: const Text('Reset to Master backup'),
              onTap: () async {
                final masterData = prefs.getString('master_data');
                if (masterData != null) {
                  final List decoded = jsonDecode(masterData);
                  setState(() {
                    members =
                        decoded.map((e) => Person.fromJson(e)).toList();
                  });
                  await _saveData();
                  _buildGraph();
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Restored from Master!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Remove Master'),
              subtitle: const Text('Delete Master backup & password'),
              onTap: () async {
                await prefs.remove('master_data');
                await prefs.remove('master_password');
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Master removed!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ==================== PDF ====================
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
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
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Name', "Father's Name"],
              data: List.generate(members.length, (i) {
                final m = members[i];
                final parent = m.parentId != null
                    ? members.firstWhere(
                        (x) => x.id == m.parentId,
                        orElse: () => Person(id: '', name: '-'),
                      )
                    : null;
                return [
                  '${i + 1}',
                  m.name,
                  parent?.name ?? '-',
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 12,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.teal900),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              border:
                  pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Mughal_Barlas_Family_Tree.pdf',
    );
  }

  // ==================== ADD/EDIT ====================
  void _showAddEditDialog({Person? person}) {
    final nameCtrl = TextEditingController(text: person?.name ?? '');
    String? selectedParent = person?.parentId;
    String selectedColor = person?.branchColor ?? 'teal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(person == null ? 'Add New Member' : 'Edit Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Name / نام'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedParent,
                  decoration: const InputDecoration(
                      labelText: 'Father / والد'),
                  items: members
                      .where((m) =>
                          person == null || m.id != person.id)
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedParent = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration:
                      const InputDecoration(labelText: 'Branch Color'),
                  items: const [
                    DropdownMenuItem(
                        value: 'red', child: Text('Red / سرخ')),
                    DropdownMenuItem(
                        value: 'blue', child: Text('Blue / نیلا')),
                    DropdownMenuItem(
                        value: 'green', child: Text('Green / سبز')),
                    DropdownMenuItem(
                        value: 'orange',
                        child: Text('Orange / نارنجی')),
                    DropdownMenuItem(
                        value: 'purple',
                        child: Text('Purple / جامنی')),
                    DropdownMenuItem(
                        value: 'teal', child: Text('Teal / ٹیل')),
                    DropdownMenuItem(
                        value: 'pink', child: Text('Pink / گلابی')),
                    DropdownMenuItem(
                        value: 'amber',
                        child: Text('Amber / سنہری')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedColor = v!),
                ),
              ],
            ),
          ),
          actions: [
            if (person != null)
              TextButton(
                onPressed: () {
                  setState(() => members
                      .removeWhere((m) => m.id == person.id));
                  _saveData();
                  _buildGraph();
                  Navigator.pop(ctx);
                },
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
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
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: nameCtrl.text.trim(),
                      parentId: selectedParent,
                      branchColor: selectedColor,
                    ));
                  } else {
                    final idx =
                        members.indexWhere((m) => m.id == person.id);
                    members[idx] = Person(
                      id: person.id,
                      name: nameCtrl.text.trim(),
                      parentId: selectedParent,
                      branchColor: selectedColor,
                    );
                  }
                });
                _saveData();
                _buildGraph();
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
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mughal Barlas Family Tree'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Master Backup',
            onPressed: _showMasterBackupDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(2000),
        minScale: 0.05,
        maxScale: 3.0,
        child: GraphView(
          graph: graph,
          algorithm: BuchheimWalkerAlgorithm(
              builder, TreeEdgeRenderer(builder)),
          paint: Paint()
            ..color = Colors.teal.shade800
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            var id = node.key!.value as String;
            var member = members.firstWhere(
              (m) => m.id == id,
              orElse: () => Person(id: id, name: id),
            );
            final parent = member.parentId != null
                ? members.firstWhere(
                    (x) => x.id == member.parentId,
                    orElse: () => Person(id: '', name: ''),
                  )
                : null;

            final borderColor = _getColor(member.branchColor);
            final isHighlighted = highlightId == member.id;

            return GestureDetector(
              onTap: () => _showAddEditDialog(person: member),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                constraints:
                    const BoxConstraints(minWidth: 110, maxWidth: 160),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.yellow.shade100
                      : Colors.white,
                  border: Border.all(
                    color: isHighlighted
                        ? Colors.amber.shade700
                        : borderColor,
                    width: isHighlighted ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isHighlighted
                          ? Colors.amber.withOpacity(0.7)
                          : borderColor.withOpacity(0.5),
                      blurRadius: isHighlighted ? 16 : 8,
                      spreadRadius: isHighlighted ? 3 : 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    if (parent != null && parent.id.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'ولدیت: ${parent.name}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
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
