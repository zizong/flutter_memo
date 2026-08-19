class Memo {
  int? id;          // 数据库自增id
  String title;
  String content;
  DateTime createdAt;

  Memo({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  // 从 Map 转为对象（查询时用）
  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // 对象转为 Map（插入/更新时用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}