import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/usecases/auth_usecases.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(
        Get.put(
          AuthPresenter(Get.put(AuthUsecases(Get.find()), permanent: true)),
        ),
      ),
    );
  }
}
