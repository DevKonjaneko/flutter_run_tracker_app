import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateDeleteRunUi extends StatefulWidget {
  final Map<String, dynamic> runData;

  const UpdateDeleteRunUi({super.key, required this.runData});

  @override
  State<UpdateDeleteRunUi> createState() => _UpdateDeleteRunUiState();
}

class _UpdateDeleteRunUiState extends State<UpdateDeleteRunUi> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placeController;
  late TextEditingController _withWhoController;
  late TextEditingController _distanceController;

  XFile? _newPickedImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _placeController = TextEditingController(text: widget.runData['place'] ?? '');
    _withWhoController = TextEditingController(text: widget.runData['with_who'] ?? '');
    _distanceController = TextEditingController(
      text: widget.runData['distance'] != null ? widget.runData['distance'].toString() : '',
    );
    _currentImageUrl = widget.runData['image_url'];
  }

  @override
  void dispose() {
    _placeController.dispose();
    _withWhoController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  String? _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.last;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (picked != null) {
      setState(() {
        _newPickedImage = picked;
      });
    }
  }

  Future<void> _updateRun() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? updatedImageUrl = _currentImageUrl;

      if (_newPickedImage != null) {
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          final oldFileName = _getFileNameFromUrl(_currentImageUrl!);
          if (oldFileName != null) {
            try {
              await _supabase.storage.from('run_images').remove([oldFileName]);
            } catch (e) {
              debugPrint('Error removing old image: $e');
            }
          }
        }

        final newFileName = 'run_${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (kIsWeb) {
          final bytes = await _newPickedImage!.readAsBytes();
          await _supabase.storage.from('run_images').uploadBinary(newFileName, bytes);
        } else {
          final file = File(_newPickedImage!.path);
          await _supabase.storage.from('run_images').upload(newFileName, file);
        }
        updatedImageUrl = _supabase.storage.from('run_images').getPublicUrl(newFileName);
      }

      await _supabase.from('runs').update({
        'place': _placeController.text.trim(),
        'with_who': _withWhoController.text.trim(),
        'distance': double.parse(_distanceController.text.trim()),
        'image_url': updatedImageUrl,
      }).eq('id', widget.runData['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('แก้ไขข้อมูลสำเร็จ', style: GoogleFonts.kanit()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการแก้ไข: $e', style: GoogleFonts.kanit()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRun() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการลบ', style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบข้อมูลการวิ่งนี้ใช่หรือไม่?', style: GoogleFonts.kanit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: GoogleFonts.kanit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ลบข้อมูล', style: GoogleFonts.kanit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
        final fileName = _getFileNameFromUrl(_currentImageUrl!);
        if (fileName != null) {
          try {
            await _supabase.storage.from('run_images').remove([fileName]);
          } catch (e) {
            debugPrint('Error removing image on delete: $e');
          }
        }
      }

      await _supabase.from('runs').delete().eq('id', widget.runData['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบข้อมูลเรียบร้อยแล้ว', style: GoogleFonts.kanit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถลบข้อมูลได้: $e', style: GoogleFonts.kanit()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1244),
        foregroundColor: Colors.white,
        title: Text(
          'Run Tracker (แก้ไข/ลบ)',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _newPickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: kIsWeb
                                ? Image.network(_newPickedImage!.path, fit: BoxFit.cover)
                                : Image.file(File(_newPickedImage!.path), fit: BoxFit.cover),
                          )
                        : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.directions_run_rounded,
                                    size: 55,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.directions_run_rounded,
                                size: 55,
                                color: Color(0xFF0284C7),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'วิ่งที่ไหน',
                style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _placeController,
                style: GoogleFonts.kanit(fontSize: 13),
                decoration: _inputDecoration('สถานที่วิ่ง'),
                validator: (val) => val == null || val.trim().isEmpty ? 'กรุณากรอกสถานที่วิ่ง' : null,
              ),
              const SizedBox(height: 14),

              Text(
                'วิ่งกับใคร',
                style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _withWhoController,
                style: GoogleFonts.kanit(fontSize: 13),
                decoration: _inputDecoration('เช่น คนเดียว, เพื่อน, ชมรม'),
              ),
              const SizedBox(height: 14),

              Text(
                'ระยะทาง (กม.)',
                style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.kanit(fontSize: 13),
                decoration: _inputDecoration('เช่น 2, 5, 10'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'กรุณากรอกระยะทาง';
                  if (double.tryParse(val.trim()) == null) return 'กรุณากรอกเป็นตัวเลข';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _updateRun,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'บันทึกแก้ไขข้อมูล',
                        style: GoogleFonts.kanit(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _deleteRun,
                child: Text(
                  'ลบข้อมูล',
                  style: GoogleFonts.kanit(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.kanit(fontSize: 12, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}