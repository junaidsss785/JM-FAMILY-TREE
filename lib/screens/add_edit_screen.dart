import 'package:flutter/material.dart';
import '../models/family_member.dart';

class AddEditScreen extends StatefulWidget {
  final FamilyMember? memberToEdit;
  final List<FamilyMember> allMembers;
  final Function(FamilyMember) onSave;
  final Function(String)? onDelete;

  const AddEditScreen({
    Key? key,
    this.memberToEdit,
    required this.allMembers,
    required this.onSave,
    this.onDelete,
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
    _fatherController = TextEditingController(
      text: _fatherName == 'Root Ancestor' ? '' : _fatherName,
    );
  }

  @override
  void dispose() {
    _fatherController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String enteredFather = _fatherController.text.trim();
      _fatherName =
          enteredFather.isEmpty ? 'Root Ancestor' : enteredFather;

      double newX = widget.memberToEdit?.x ?? 500.0;
      double newY = widget.memberToEdit?.y ?? 500.0;

      if (widget.memberToEdit == null &&
          _fatherName != 'Root Ancestor') {
        bool fatherExists = widget.allMembers.any(
          (m) =>
              m.name.trim().toLowerCase() == _fatherName.toLowerCase(),
        );

        if (!fatherExists) {
          final newFatherMember = FamilyMember(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                '_father',
            name: _fatherName,
            fatherName: 'Root Ancestor',
            branchColorName: _branchColorName,
            childrenIds: [],
            x: newX,
            y: newY - 150.0,
          );
          widget.onSave(newFatherMember);
        } else {
          final parent = widget.allMembers.firstWhere(
            (m) =>
                m.name.trim().toLowerCase() ==
                _fatherName.toLowerCase(),
            orElse: () => widget.allMembers.first,
          );
          newX = parent.x;
          newY = parent.y + 150.0;
        }
      }

      final updatedMember = FamilyMember(
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

  void _deleteMember() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member?'),
        content: Text(
          'کیا آپ واقعی "${widget.memberToEdit!.name}" کو حذف کرنا چاہتے ہیں؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onDelete != null) {
                widget.onDelete!(widget.memberToEdit!.id);
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: 'Delete',
              onPressed: _deleteMember,
            ),
        ],
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
                      borderSide:
                          BorderSide(color: Color(0xFF004D40))),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'براہ کرم نام درج کریں'
                        : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),

              // والد (Autocomplete) - اختیاری
              Autocomplete<String>(
                optionsBuilder:
                    (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return sortedNames;
                  }
                  return sortedNames.where((option) => option
                      .toLowerCase()
                      .contains(
                          textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) =>
                    _fatherController.text = selection,
                fieldViewBuilder: (context, controller, focusNode,
                    onFieldSubmitted) {
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
                          'ولدیت (خالی چھوڑ سکتے ہیں اگر سب سے اوپر کا بزرگ ہو)',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF004D40))),
                    ),
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
                      borderSide:
                          BorderSide(color: Color(0xFF004D40))),
                ),
                items: availableColors
                    .map((color) => DropdownMenuItem(
                        value: color, child: Text(color)))
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
                  isEditing
                      ? 'تبدیلیاں محفوظ کریں'
                      : 'محفوظ کریں',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),

              // ڈیلیٹ بٹن (صرف ایڈٹ میں)
              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _deleteMember,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text(
                    'اس فرد کو حذف کریں',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
