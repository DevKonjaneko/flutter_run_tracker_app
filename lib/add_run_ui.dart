import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/run.dart';

class AddRunUi extends StatefulWidget {
  const AddRunUi({super.key});

  @override
  State<AddRunUi> createState() => _AddRunUiState();
}

class _AddRunUiState extends State<AddRunUi> {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();
  final _withWhoController = TextEditingController();
  final _distanceController = TextEditingController();

  XFile? _pickedImage;
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _placeController.dispose();
    _withWhoController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera, // หรือ ImageSource.gallery ตามต้องการ
      maxWidth: 800,
      maxHeight: 800,
    );

    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _placeController.clear();
    _withWhoController.clear();
    _distanceController.clear();
    setState(() {
      _pickedImage = null;
    });
  }

  Future<void> _saveRun() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 1. ถ้ามีรูปภาพ ให้อัปโหลดเข้า bucket: run_bk
      if (_pickedImage != null) {
        final fileName = 'run_${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          await _supabase.storage.from('run_bk').uploadBinary(fileName, bytes);
        } else {
          final file = File(_pickedImage!.path);
          await _supabase.storage.from('run_bk').upload(fileName, file);
        }
        imageUrl = _supabase.storage.from('run_bk').getPublicUrl(fileName);
      }

      // 2. สร้าง Run Model โดยไม่ส่ง id เข้าไปเพื่อให้ Supabase สร้างอัตโนมัติ
      final newRun = Run(
        runWhere: _placeController.text.trim(),
        runPerson: _withWhoController.text.trim(),
        runDistance: int.tryParse(_distanceController.text.trim()),
        runImageUrl: imageUrl,
      );

      final Map<String, dynamic> insertData = newRun.toJson();
      insertData.remove('id'); // ตัด id ออก ป้องกันข้อผิดพลาดกรณี id เป็น null

      // 3. บันทึกลงตาราง run_tb
      await _supabase.from('run_tb').insert(insertData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกข้อมูลเรียบร้อยแล้ว', style: GoogleFonts.kanit()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึก: $e', style: GoogleFonts.kanit()),
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
          'Run Tracker (เพิ่ม)',
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
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: kIsWeb
                                ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                                : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 48,
                                color: Color(0xFFCBD5E1),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Text(
                'วิ่งที่ไหน',
                style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _placeController,
                style: GoogleFonts.kanit(fontSize: 13),
                decoration: _inputDecoration('เช่น สวนสาธารณะ, สนามกีฬา หรือ อื่นๆ'),
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
                decoration: _inputDecoration('เช่น เพื่อน 3 คน, แฟน หรือ อื่นๆ'),
              ),
              const SizedBox(height: 14),

              Text(
                'ระยะทาง',
                style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.kanit(fontSize: 13),
                decoration: _inputDecoration('เช่น 1, 5, 11 หรือ อื่นๆ'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'กรุณากรอกระยะทาง';
                  if (int.tryParse(val.trim()) == null) return 'กรุณากรอกเป็นตัวเลขจำนวนเต็ม';
                  return null;
                },
              ),
              const SizedBox(height: 26),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _saveRun,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'บันทึกข้อมูล',
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
                onPressed: _isLoading ? null : _clearForm,
                child: Text(
                  'ยกเลิก',
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