class Run {
  String? id;
  String? runWhere;
  String? runPerson;
  int? runDistance;
  String? runImageUrl;

  Run({
    this.id,
    this.runWhere,
    this.runPerson,
    this.runDistance,
    this.runImageUrl,
  });

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'],
      runWhere: json['runWhere'],
      runPerson: json['runPerson'],
      runDistance: json['runDistance'] != null
          ? int.tryParse(json['runDistance'].toString())
          : null,
      runImageUrl: json['runImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (runWhere != null) 'runWhere': runWhere,
      if (runPerson != null) 'runPerson': runPerson,
      if (runDistance != null) 'runDistance': runDistance,
      if (runImageUrl != null) 'runImageUrl': runImageUrl,
    };
  }
}