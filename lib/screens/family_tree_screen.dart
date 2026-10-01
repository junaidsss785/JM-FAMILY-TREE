import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import '../models/person.dart';
import '../data/family_data.dart';
import '../widgets/person_box.dart';
import 'add_edit_screen.dart';

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<Person> members = [];
  bool loading = true;
  String? highlightId;

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
      members = decoded.map((e) => Person.fromMap(e)).toList();
    } else {
      members = List.from(initialFamilyMembers);
      await _saveData();
    }
    setState(() => loading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(members.map((e) => e.toMap()).toList());
    await prefs.setString('family_data', data);
  }

  // ==================== ADD/EDIT ====================
  void _openAddEditScreen({Person? person}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddEditScreen(
          memberToEdit: person,
          allMembers: members,
          onSave: (savedPerson) {
            setState(() {
              final idx =
                  members.indexWhere((m) => m.id == savedPerson.id);
              if (idx != -1) {
                members[idx] = savedPerson;
              } else {
                members.add(savedPerson);
              }
            });
            _saveData();
          },
        ),
      ),
    );
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
                          leading:
                              const Icon(Icons.person, color: Colors.teal),
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
                  jsonEncode(members.map((e) => e.toMap()).toList());
              await prefs.setString('master_data', data);

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Master Backup created!'),
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
                    jsonEncode(members.map((e) => e.toMap()).toList());
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
                        decoded.map((e) => Person.fromMap(e)).toList();
                  });
                  await _saveData();
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
            pw.Text(
              'Total Members: ${members.length}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Name', "Father's Name"],
              data: List.generate(members.length, (i) {
                final m = members[i];
                return [
                  '${i + 1}',
                  m.name,
                  m.fatherName,
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 12,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.teal900),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              border:
                  pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            ),
            pw.SizedBox(height: 20),
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
        boundaryMargin: const EdgeInsets.all(3000),
        minScale: 0.05,
        maxScale: 3.0,
        child: SizedBox(
          width: 6000,
          height: 6000,
          child: Stack(
            children: [
              // لائنیں (CustomPaint)
              CustomPaint(
                size: const Size(6000, 6000),
                painter: _LinesPainter(members: members),
              ),
              // باکسز (Drag & Drop کے لیے)
              ...members.map((m) {
                return Positioned(
                  left: m.x + 500,
                  top: m.y + 500,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final idx =
                            members.indexWhere((p) => p.id == m.id);
                        if (idx != -1) {
                          members[idx] = m.copyWith(
                            x: m.x + details.delta.dx,
                            y: m.y + details.delta.dy,
                          );
                        }
                      });
                    },
                    onPanEnd: (details) {
                      _saveData();
                    },
                    child: PersonBox(
                      person: m,
                      isHighlighted: highlightId == m.id,
                      onTap: () => _openAddEditScreen(person: m),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade800,
        onPressed: () => _openAddEditScreen(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ==================== LINES PAINTER ====================
class _LinesPainter extends CustomPainter {
  final List<Person> members;

  _LinesPainter({required this.members});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var child in members) {
      if (child.fatherName.isEmpty ||
          child.fatherName.toLowerCase() == 'root ancestor') {
        continue;
      }

      // والد کو تلاش کریں (نام سے)
      final parent = members.firstWhere(
        (p) =>
            p.name.trim().toLowerCase() ==
            child.fatherName.trim().toLowerCase(),
        orElse: () => Person(
          id: '',
          name: '',
          fatherName: '',
          branchColorName: '',
          childrenIds: [],
        ),
      );

      if (parent.id.isEmpty) continue;

      // والد کا نچلا وسط (x + 500، y + 500 آفسیٹ کے ساتھ)
      final pX = parent.x + 500 + 65;
      final pY = parent.y + 500 + 60;

      // بیٹے کا اوپری وسط
      final cX = child.x + 500 + 65;
      final cY = child.y + 500;

      final path = Path();
      path.moveTo(pX, pY);
      path.lineTo(pX, (pY + cY) / 2);
      path.lineTo(cX, (pY + cY) / 2);
      path.lineTo(cX, cY);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
