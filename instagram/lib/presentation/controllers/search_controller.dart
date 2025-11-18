import 'package:get/get.dart';
import 'package:instagram/domain/entities/user.dart';
import 'package:instagram/domain/usecase/search_usecase.dart';
import 'package:instagram/injection_container.dart';
class UserSearchController extends GetxController {
  final SearchUsersUseCase searchUsersUseCase;

  UserSearchController():
  searchUsersUseCase = locator<SearchUsersUseCase>();

  var isLoading = false.obs;
  var users = <UserEntity>[].obs; // Daftar hasil pencarian

  // Fungsi yang dipanggil saat user mengetik
  Future<void> search(String query) async {
    if (query.isEmpty) {
      users.value = []; // Kosongkan hasil jika query kosong
      return;
    }
    
    isLoading.value = true;
    
    final result = await searchUsersUseCase(SearchUsersParams(query));
    
    isLoading.value = false;

    result.fold(
      (failure) {
        Get.snackbar("Error", failure.message);
      },
      (userList) {
        users.value = userList; // Update daftar hasil
      }
    );
  }
}