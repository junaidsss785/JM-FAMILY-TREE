import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String appColor = 'teal';
  String lineColor = 'teal';
  double lineThickness = 2.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      appColor = prefs.getString('app_color') ?? 'teal';
      lineColor = prefs.getString('line_color') ?? 'teal';
      lineThickness = prefs.getDouble('line_thickness') ?? 2.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDarkMode);
    await prefs.setString('app_color', appColor);
    await prefs.setString('line_color', lineColor);
    await prefs.setDouble('line_thickness', lineThickness);
  }

  MaterialColor _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'teal':
        return Colors.teal;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      case 'amber':
        return Colors.amber;
      default:
        return Colors.teal;
    }
  }

  // ==================== EXPORT DATA ====================
  Future<void> _exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('family_data');

      if (data == null || data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ کوئی ڈیٹا نہیں ملا / No data found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final List decoded = jsonDecode(data);
      final count = decoded.length;
      final prettyJson =
          const JsonEncoder.withIndent('  ').convert(decoded);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('📤 Export Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('کل نام: $count'),
                const SizedBox(height: 10),
                const Text(
                  'یہ ڈیٹا فائل میں محفوظ کر کے بھیجیں گے\n'
                  'تاکہ کوئی نام نہ چھوٹے',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final directory = await getTemporaryDirectory();
                    final file = File(
                        '${directory.path}/family_tree_data.json');
                    await file.writeAsString(prettyJson);

                    await Share.shareXFiles(
                      [XFile(file.path)],
                      subject:
                          'Mughal Barlas Family Tree Data ($count members)',
                      text: 'کل نام: $count',
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== IMPORT DATA ====================
  Future<void> _importData() async {
    try {
      // فائل چننے کا ڈائیلاگ
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = File(result.files.first.path!);
      final content = await file.readAsString();

      // JSON validate کریں
      final List decoded = jsonDecode(content);

      if (decoded.isEmpty) {
        throw Exception('فائل خالی ہے / File is empty');
      }

      // تصدیق کا ڈائیلاگ
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('📥 Import Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('کل نام: ${decoded.length}'),
                const SizedBox(height: 10),
                const Text(
                  '⚠️ خبردار: موجودہ ڈیٹا ہٹ جائے گا\n'
                  'اور یہ ڈیٹا لوڈ ہو جائے گا',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
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
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    // SharedPreferences میں محفوظ کریں
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('family_data', content);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✅ ${decoded.length} نام لوڈ ہو گئے / '
                              '${decoded.length} members imported!'),
                          backgroundColor: Colors.teal,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Import'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== SHARE APP ====================
  Future<void> _shareApp() async {
    await Share.share(
      '🌳 Mughal Barlas Family Tree\n\n'
      'یہ ایپ ہمارے خاندان کا شجرہ نسب ہے۔\n\n'
      'بنانے والا: جنید صدیق ولد غلام صدیق\n'
      'رابطہ: junaidjmsss786@gmail.com\n\n'
      '❤️ محبت کے ساتھ',
      subject: 'Mughal Barlas Family Tree',
    );
  }

  // ==================== ABOUT DIALOG ====================
  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.teal),
            SizedBox(width: 8),
            Text('About'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text('🌳', style: TextStyle(fontSize: 50)),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Mughal Barlas Family Tree',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 5),
              const Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'بنانے والا / Created by:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 5),
              const Text('جنید صدیق ولد غلام صدیق'),
              const Text('Junaid Siddique son of Ghulam Siddique'),
              const SizedBox(height: 15),
              const Text(
                'رابطہ / Contact:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 5),
              const SelectableText(
                '📧 junaidjmsss786@gmail.com',
                style: TextStyle(color: Colors.blue),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  '© 2026 - All Rights Reserved',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  '❤️ محبت کے ساتھ',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
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
    );
  }

  // ==================== WELCOME MESSAGE ====================
  void _showWelcome() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🌳 خوش آمدید / Welcome'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'السلام علیکم ورحمۃ اللہ وبرکاتہ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 15),
              const Text('🌳 Mughal Barlas Family Tree'),
              const SizedBox(height: 15),
              const Text(
                'یہ ہمارے خاندان کا شجرہ نسب ہے۔\n'
                'اسے محبت اور دعاؤں کے ساتھ بنایا گیا ہے۔\n\n'
                'اسے دیکھیں، اپنے بزرگوں کو یاد کریں،\n'
                'اور اپنے بچوں کو بتائیں۔\n\n'
                'ہمارا خاندان — ہماری پہچان۔',
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                '📖 دعا کی اپیل:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              const Text(
                  'یہ ایپ\nجنید صدیق ولد غلام صدیق\nنے بنائی ہے۔'),
              const SizedBox(height: 10),
              const Text(
                'ہم سب کے لیے دعا کریں:\n'
                'اللہ ہمارے بزرگوں کی مغفرت فرمائے،\n'
                'ہمارے والدین کو صحت و عافیت دے،\n'
                'ہماری اولاد کو نیک بنائے،\n'
                'اور ہمارے خاندان کو آباد رکھے۔\n\n'
                'آمین!',
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Assalamu Alaikum Wa Rahmatullahi Wa Barakatuh',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              const Text(
                'This is our family tree.\n'
                'It has been made with love and prayers.\n\n'
                'Look at it, remember your elders,\n'
                'and tell your children about them.\n\n'
                'Our family — our identity.',
              ),
              const SizedBox(height: 15),
              const Text(
                '📖 A Request for Prayers:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app has been created by\n'
                'Junaid Siddique son of Ghulam Siddique',
              ),
              const SizedBox(height: 10),
              const Text(
                'Please pray for us all:\n'
                'May Allah forgive our elders,\n'
                'grant health to our parents,\n'
                'make our children righteous,\n'
                'and keep our family united.\n\n'
                'Ameen!',
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  '📧 junaidjmsss786@gmail.com',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  '❤️ With Love / محبت کے ساتھ',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MaterialColor primaryColor = _getColorFromName(appColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ========== THEME MODE ==========
          _buildSectionTitle('🎨 Theme Mode', primaryColor),
          Card(
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text('☀️ Light Mode'),
                  value: false,
                  groupValue: isDarkMode,
                  onChanged: (val) {
                    setState(() => isDarkMode = false);
                    _saveSettings();
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('🌙 Dark Mode'),
                  value: true,
                  groupValue: isDarkMode,
                  onChanged: (val) {
                    setState(() => isDarkMode = true);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ========== APP COLOR ==========
          _buildSectionTitle('🎨 App Color', primaryColor),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildColorCircle('teal', Colors.teal),
                  _buildColorCircle('blue', Colors.blue),
                  _buildColorCircle('purple', Colors.purple),
                  _buildColorCircle('orange', Colors.orange),
                  _buildColorCircle('red', Colors.red),
                  _buildColorCircle('green', Colors.green),
                  _buildColorCircle('pink', Colors.pink),
                  _buildColorCircle('amber', Colors.amber),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ========== LINE COLOR ==========
          _buildSectionTitle('📏 Line Color', primaryColor),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildLineColorCircle('teal', Colors.teal),
                  _buildLineColorCircle('blue', Colors.blue),
                  _buildLineColorCircle('purple', Colors.purple),
                  _buildLineColorCircle('orange', Colors.orange),
                  _buildLineColorCircle('red', Colors.red),
                  _buildLineColorCircle('green', Colors.green),
                  _buildLineColorCircle('pink', Colors.pink),
                  _buildLineColorCircle('amber', Colors.amber),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ========== LINE THICKNESS ==========
          _buildSectionTitle('📏 Line Thickness', primaryColor),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Slider(
                    value: lineThickness,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: '${lineThickness.toStringAsFixed(1)} px',
                    activeColor: primaryColor,
                    onChanged: (val) {
                      setState(() => lineThickness = val);
                      _saveSettings();
                    },
                  ),
                  Text(
                    '${lineThickness.toStringAsFixed(1)} pixels',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: lineThickness,
                    width: 200,
                    color: _getColorFromName(lineColor),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),

          // ========== DATA & SHARING ==========
          _buildSectionTitle('📤 Data & Sharing', primaryColor),

          // Export Data
          Card(
            child: ListTile(
              leading: Icon(Icons.upload_file, color: primaryColor),
              title: const Text('Export Data / ڈیٹا ایکسپورٹ'),
              subtitle: const Text('تمام نام فائل میں محفوظ کریں'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _exportData,
            ),
          ),

          const SizedBox(height: 10),

          // Import Data
          Card(
            child: ListTile(
              leading: Icon(Icons.download, color: primaryColor),
              title: const Text('Import Data / ڈیٹا درآمد کریں'),
              subtitle: const Text('فائل سے ڈیٹا لوڈ کریں'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _importData,
            ),
          ),

          const SizedBox(height: 10),

          // Share App
          Card(
            child: ListTile(
              leading: Icon(Icons.share, color: primaryColor),
              title: const Text('Share App / ایپ شیئر کریں'),
              subtitle: const Text('WhatsApp، Email وغیرہ'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _shareApp,
            ),
          ),

          const SizedBox(height: 20),

          // ========== INFO ==========
          _buildSectionTitle('ℹ️ معلومات / Information', primaryColor),

          // Welcome Message
          Card(
            child: ListTile(
              leading: Icon(Icons.message, color: primaryColor),
              title: const Text('Welcome Message'),
              subtitle: const Text('خوش آمدید پیغام دیکھیں'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showWelcome,
            ),
          ),

          const SizedBox(height: 10),

          // About
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: primaryColor),
              title: const Text('About / تعارف'),
              subtitle: const Text('ایپ کی معلومات'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showAbout,
            ),
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              '🌳 Mughal Barlas Family Tree\nVersion 1.0.0\n© 2026',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildColorCircle(String name, Color color) {
    final isSelected = appColor == name;
    return GestureDetector(
      onTap: () {
        setState(() => appColor = name);
        _saveSettings();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildLineColorCircle(String name, Color color) {
    final isSelected = lineColor == name;
    return GestureDetector(
      onTap: () {
        setState(() => lineColor = name);
        _saveSettings();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}
