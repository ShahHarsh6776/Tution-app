import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/models/student.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;

  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _standardController = TextEditingController();
  final _totalFeesController = TextEditingController();
  final _parentNumberController = TextEditingController();
  final _additionalParentNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _feesSubmittedController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _pickedImage;
  bool _isEditing = false;
  String? _selectedMedium;
  final List<String> _mediumOptions = ['English', 'Gujarati'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.student != null;
    if (_isEditing) {
      _nameController.text = widget.student!.name;
      _schoolNameController.text = widget.student!.schoolName;
      _standardController.text = widget.student!.standard;
      _totalFeesController.text = widget.student!.totalFees.toString();
      _parentNumberController.text = widget.student!.parentNumber;
      _additionalParentNumberController.text =
          widget.student!.additionalParentNumber ?? '';
      _addressController.text = widget.student!.address ?? '';
      _feesSubmittedController.text = widget.student!.feesSubmitted.toString();
      _descriptionController.text = widget.student!.description ?? '';
      _selectedMedium = widget.student!.medium;
    } else {
      _feesSubmittedController.text = '0';
      _selectedMedium = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolNameController.dispose();
    _standardController.dispose();
    _totalFeesController.dispose();
    _parentNumberController.dispose();
    _additionalParentNumberController.dispose();
    _addressController.dispose();
    _feesSubmittedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<StudentProvider>(context, listen: false);

    final student = Student(
      id: _isEditing ? widget.student!.id : const Uuid().v4(),
      name: _nameController.text,
      photoUrl: _isEditing ? widget.student!.photoUrl : null,
      schoolName: _schoolNameController.text,
      standard: _standardController.text,
      totalFees: double.parse(_totalFeesController.text),
      parentNumber: _parentNumberController.text,
      additionalParentNumber: _additionalParentNumberController.text.isEmpty
          ? null
          : _additionalParentNumberController.text,
      address: _addressController.text,
      feesSubmitted: double.parse(_feesSubmittedController.text),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      medium: _selectedMedium,
      createdAt: _isEditing ? widget.student!.createdAt : DateTime.now(),
    );

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (_isEditing) {
        await provider.updateStudent(student, photoFile: _pickedImage);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Student updated successfully')),
        );
      } else {
        await provider.addStudent(student, photoFile: _pickedImage);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
      }
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Student' : 'Add Student'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : (_isEditing && widget.student!.photoUrl != null
                            ? NetworkImage(widget.student!.photoUrl!)
                            : null) as ImageProvider<Object>?,
                    child: (_pickedImage == null &&
                            (!_isEditing || widget.student!.photoUrl == null))
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _schoolNameController,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter school name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _standardController,
                decoration: const InputDecoration(
                  labelText: 'Class/Standard',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter class/standard';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalFeesController,
                decoration: const InputDecoration(
                  labelText: 'Total Fees (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total fees';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Parent Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter parent phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _additionalParentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Additional Parent Phone Number (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feesSubmittedController,
                decoration: const InputDecoration(
                  labelText: 'Fees Submitted (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter fees submitted';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMedium,
                decoration: const InputDecoration(
                  labelText: 'Medium',
                  border: OutlineInputBorder(),
                ),
                items: _mediumOptions
                    .map((medium) => DropdownMenuItem<String>(
                          value: medium,
                          child: Text(medium),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMedium = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select medium';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveStudent,
                  child: Text(
                    _isEditing ? 'Update Student' : 'Add Student',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
