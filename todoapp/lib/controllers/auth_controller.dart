import 'package:get/get.dart';
import 'package:todoapp/controllers/todo_controller.dart';
import 'package:todoapp/models/user.dart';
import 'package:todoapp/services/api_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService = ApiService();
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = "".obs;

  bool get isLoggedIn => currentUser.value != null;

  Future<void> register(String name, String email, String password,
      String passwordConfirmation) async {
    try {
      isLoading.value = true;
      error.value = "";
      final newUser = await _apiService.register(
          name, email, password, passwordConfirmation);
      currentUser.value = newUser;
      await Get.find<TodoController>().fetchTodos();
      Get.offAllNamed('/todos');
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = "";
      final user = await _apiService.login(email, password);
      currentUser.value = user;
      await Get.find<TodoController>().fetchTodos();
      Get.offAllNamed('/todos');
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      error.value = "";
      await _apiService.logout();
      currentUser.value = null;
      await _apiService.clearToken();
      Get.find<TodoController>().todos.clear();
      Get.offAllNamed('/login');
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
