import 'package:flutter/material.dart';
import '../models/person.dart';

class AddEditScreen extends StatefulWidget {
  final Person? memberToEdit;
  final List<Person> allMembers;
  final Function(Person) onSave;

  const AddEditScreen({
    Key? key,
    this.memberToEdit,
    required this.allMembers,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddEditScreenState createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _fatherName;
  late String _branchColorName;
  late TextEditingController _fatherController;

  final List<String> availableColors = [
    'Blue',
    'Purple',
    'Green',
    'Orange',
    'Red'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.memberToEdit != null) {
      _name = widget.memberToEdit!.name;
      _fatherName = widget.memberToEdit!.fatherName;
      _branchColorName = widget.memberToEdit!.branchColorName;
    } else {
      _name = '';
      _fatherName = '';
      _branchColorName = 'Blue';
    }
    _fatherController = TextEditingController(text: _fatherName);
  }

  @override
  void dispose() {
    _fatherController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _fatherName = _fatherController.text.trim();

      // اگر والد کا نام خالی ہے تو خود "Root Ancestor" مان لیں
      if (_fatherName.isEmpty) {
        _fatherName = 'Root Ancestor';
      }

      // چیک کریں کہ والد لسٹ میں موجود ہے یا نہیں
      bool fatherExists = widget.allMembers.any(
        (m) => m.name.trim().toLowerCase() == _fatherName.toLowerCase(),
      );

      // اگر والد کا نام نیا ہے (اور Root Ancestor نہیں) تو خود بخود باکس بنا دیں
      if (!fatherExists &&
          _fatherName.isNotEmpty &&
          _fatherName.toLowerCase() != 'root ancestor') {
        double currentX = widget.memberToEdit?.x ?? 500.0;
        double currentY = widget.memberToEdit?.y ?? 500.0;

        final newFatherMember = Person(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_father',
          name: _fatherName,
          fatherName: 'Root Ancestor',
          branchColorName: _branchColorName,
          childrenIds: [widget.memberToEdit?.id ?? ''],
          x: currentX,
          y: currentY - 150.0,
        );
        widget.onSave(newFatherMember);
      }

      // موجودہ فرد کی پوزیشن
      double newX = widget.memberToEdit?.x ?? 500.0;
      double newY = widget.memberToEdit?.y ?? 500.0;

      if (widget.memberToEdit == null) {
        // نیا فرد - والد کے نیچے
        if (_fatherName.toLowerCase() != 'root ancestor') {
          var parentList = widget.allMembers.where(
            (m) =>
                m.name.trim().toLowerCase() == _fatherName.toLowerCase(),
          );
          if (parentList.isNotEmpty) {
            var parent = parentList.first;
            newX = parent.x;
            newY = parent.y + 150.0;
          } else {
            newX = 500.0;
            newY = 500.0;
          }
        } else {
          // Root ancestor - اوپر
          newX = 500.0;
          newY = 100.0;
        }
      }

      final updatedMember = Person(
        id: widget.memberToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.trim(),
        fatherName: _fatherName,
        branchColorName: _branchColorName,
        childrenIds: widget.memberToEdit?.childrenIds ?? [],
        x: newX,
        y: newY,
      );

      widget.onSave(updatedMember);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memberToEdit != null;
    List<String> sortedNames =
        widget.allMembers.map((m) => m.name).toList();
    sortedNames.sort((a, b) => a.compareTo(b));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),
        title: Text(
          isEditing ? 'فرد میں ترمیم کریں' : 'نیا فرد شامل کریں',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // نام
              TextFormField(
                initialValue: _name,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'فرد کا نام',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF004D40))),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'براہ کرم نام درج کریں'
                        : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),

              // والد (Autocomplete) - Optional
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return sortedNames;
                  return sortedNames.where((option) => option
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) =>
                    _fatherController.text = selection,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  if (controller.text.isEmpty &&
                      _fatherController.text.isNotEmpty) {
                    controller.text = _fatherController.text;
                  }
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText:
                          'ولدیت (اختیاری - پرانا نام تلاش کریں یا نیا نام لکھیں)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF004D40))),
                    ),
                    // یہاں validator ہٹا دیا - Optional
                  );
                },
              ),
              const SizedBox(height: 16),

              // شاخ کا رنگ
              DropdownButtonFormField<String>(
                value: _branchColorName,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'شاخ کا رنگ (Branch Color)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF004D40))),
                ),
                items: availableColors
                    .map((color) =>
                        DropdownMenuItem(value: color, child: Text(color)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _branchColorName = value!),
              ),
              const SizedBox(height: 24),

              // محفوظ کریں
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveForm,
                child: Text(
                  isEditing ? 'تبدیلیاں محفوظ کریں' : 'محفوظ کریں',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
