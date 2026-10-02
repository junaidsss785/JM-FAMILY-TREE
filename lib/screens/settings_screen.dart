import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Color _getColorFromName(String name) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _getColorFromName(appColor).shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ========== THEME MODE ==========
          _buildSectionTitle('🎨 Theme Mode'),
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
          _buildSectionTitle('🎨 App Color'),
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
          _buildSectionTitle('📏 Line Color'),
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
          _buildSectionTitle('📏 Line Thickness'),
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
                    activeColor: _getColorFromName(appColor),
                    onChanged: (val) {
                      setState(() => lineThickness = val);
                      _saveSettings();
                    },
                  ),
                  Text(
                    '${lineThickness.toStringAsFixed(1)} pixels',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _getColorFromName(appColor).shade800,
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
