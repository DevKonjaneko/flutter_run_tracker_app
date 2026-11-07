class Run{
  // สร้างตัวแปรให้ล้อกับชื่อคอลัมน์ใน Table ของ Supabase
  String? id;
  String? runWhere;
  String? runPerson;
  int? runDistance;
  String? runImageUrl;

  // สร้าง Constructor
  Run({
    this.id,
    this.runWhere,
    this.runPerson,
    this.runDistance,
    this.runImageUrl,
  });

  // แปลงข้อมูลจาก Supabase เพื่อมาใช้ใน Flutter -> From JSON
  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'] as String?,
      runWhere: json['runWhere'] as String?,
      runPerson: json['runPerson'] as String?,
      runDistance: json['runDistance'] as int?,
      runImageUrl: json['runImageUrl'] as String?,
    );
  }

  // แปลงข้อมูลจาก Flutter เพื่อส่งไปเก็บใน Supabase -> To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'runWhere': runWhere,
      'runPerson': runPerson,
      'runDistance': runDistance,
      'runImageUrl': runImageUrl,
    };
  }
}