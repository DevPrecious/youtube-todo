class Todo {
  final String? id;
  final String userId;
  String title;
  String description;
  bool completed;

  Todo({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.completed = false,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      completed: json['completed'] == 1 || json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'completed': completed,
    };
  }
}
