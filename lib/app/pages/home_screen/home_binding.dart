import 'package:get/get.dart';
import 'package:bam_bam_driver/app/app.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:bam_bam_driver/app/pages/Trip_screen/trip_binding.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.put(
          HomePresenter(Get.put(HomeUsecases(Get.find()), permanent: true)),
        ),
      ),
    );
    TripBinding().dependencies();
  }
}
