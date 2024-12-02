import 'package:get/get.dart';
import 'package:todoapp/models/todo.dart';
import 'package:todoapp/services/api_service.dart';

class TodoController extends GetxController {
  final RxList<Todo> todos = <Todo>[].obs;
  final ApiService _apiService = ApiService();
  final RxString error = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    try {
      isLoading.value = true;
      error.value = "";
      final fetchedTodos = await _apiService.getTodos();
      todos.value = fetchedTodos;
    } catch (e) {
      print("error fetching todos: $e");
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTodo(String title, String description) async {
    try {
      isLoading.value = true;
      error.value = "";
      final newTodo = await _apiService.createTodo(title, description);
      await fetchTodos();
    } catch (e) {
      print("error creating todo: $e");
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      isLoading.value = true;
      error.value = "";
      final updatedTodo = await _apiService.updateTodo(todo);
      final index = todos.indexWhere((t) => t.id == updatedTodo.id);
      if (index != -1) {
        todos[index] = updatedTodo;
      }
    } catch (e) {
      print("error updating todo: $e");
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      isLoading.value = true;
      error.value = "";
      await _apiService.deleteTodo(id);
      todos.removeWhere((todo) => todo.id == id);
    } catch (e) {
      print("error deleting todo: $e");
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleTodoStatus(Todo todo) async {
    todo.completed = !todo.completed;
    await updateTodo(todo);
  }
}
