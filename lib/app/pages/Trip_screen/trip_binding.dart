import 'package:bam_bam_driver/app/pages/Trip_screen/trip_page.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:get/get.dart';

class TripBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure dependencies are registered in order
    Get.lazyPut<TripUsecases>(() => TripUsecases(Get.find()), fenix: true);

    Get.lazyPut<TripPresenter>(
      () => TripPresenter(Get.find<TripUsecases>()),
      fenix: true,
    );

    Get.lazyPut<TripController>(
      () => TripController(Get.find<TripPresenter>()),
    );
  }
}
