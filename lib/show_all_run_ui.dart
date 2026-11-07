import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'add_run_ui.dart';
import 'update_delete_run_ui.dart';

class ShowAllRunUi extends StatefulWidget {
  final bool hasInitialData;
  const ShowAllRunUi({super.key, required this.hasInitialData});

  @override
  State<ShowAllRunUi> createState() => _ShowAllRunUiState();
}

class _ShowAllRunUiState extends State<ShowAllRunUi> {
  List<dynamic> _runs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRuns();
  }

  Future<void> _fetchRuns() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('run_tb')
          .select()
          .order('id', ascending: false);
      setState(() {
        _runs = List<dynamic>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() {
        _runs = [];
        _isLoading = false;
      });
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
          'Run Tracker',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity, // ขยายให้เต็มจอเพื่อจัดกึ่งกลาง
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // จัดตำแหน่งกึ่งกลางแนวนอน
            children: [
              const SizedBox(height: 22),

              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  size: 58,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'วิ่งกันเถอะ',
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _runs.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            itemCount: _runs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _runs[index];
                              final imageUrl = item['runImageUrl'] ?? item['image_url'];
                              final place = item['runWhere'] ?? item['place'] ?? '-';
                              final distance = item['runDistance'] ?? item['distance'] ?? '0';
                              final hasImg = imageUrl != null && imageUrl.toString().isNotEmpty;

                              final cardColor = index % 2 == 0
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFF5F5F5);

                              return Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: hasImg
                                        ? Image.network(
                                            imageUrl,
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.directions_run,
                                              size: 32,
                                              color: Colors.teal,
                                            ),
                                          )
                                        : Container(
                                            width: 46,
                                            height: 46,
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.directions_run,
                                              size: 30,
                                              color: Colors.teal,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    'วิ่งที่ไหน: $place',
                                    style: GoogleFonts.kanit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'วิ่งไปเท่าไหร่: $distance กม.',
                                    style: GoogleFonts.kanit(
                                      fontSize: 11.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.info,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UpdateDeleteRunUi(runData: item),
                                        ),
                                      );
                                      if (result == true) {
                                        _fetchRuns();
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: Center(
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddRunUi()),
                      );
                      if (result == true) {
                        _fetchRuns();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1244),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
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