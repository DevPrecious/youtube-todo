import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todoapp/controllers/auth_controller.dart';
import 'package:todoapp/controllers/todo_controller.dart';
import 'package:todoapp/models/todo.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  final TodoController _todoController = Get.find<TodoController>();

  void _showTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _descriptionController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty &&
                  _descriptionController.text.isNotEmpty) {
                _todoController.createTodo(
                    _titleController.text, _descriptionController.text);
                _titleController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, Todo todo) {
    _titleController.text = todo.title;
    _descriptionController.text = todo.description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _descriptionController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty &&
                  _descriptionController.text.isNotEmpty) {
                todo.title = _titleController.text;
                todo.description = _descriptionController.text;
                _todoController.updateTodo(todo);
                _titleController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(_authController.currentUser.value?.name ?? "Todos"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authController.logout(),
          ),
        ],
      ),
      body: Obx(
        () => _todoController.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _todoController.error.value.isNotEmpty
                ? Center(child: Text(_todoController.error.value))
                : _todoController.todos.isEmpty
                    ? const Center(child: Text('No todos found'))
                    : RefreshIndicator(
                        onRefresh: _todoController.fetchTodos,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _todoController.todos.length,
                          itemBuilder: (context, index) {
                            final todo = _todoController.todos[index];
                            return Dismissible(
                              key: Key(todo.id ?? ''),
                              background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  )),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) =>
                                  _todoController.deleteTodo(todo.id!),
                              child: ListTile(
                                leading: Checkbox(
                                  value: todo.completed,
                                  onChanged: (value) {
                                    _todoController.toggleTodoStatus(todo);
                                  },
                                ),
                                title: Text(
                                  todo.title,
                                  style: TextStyle(
                                    decoration: todo.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(todo.description),
                                onTap: () => _showEditTodoDialog(context, todo),
                              ),
                            );
                          },
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
