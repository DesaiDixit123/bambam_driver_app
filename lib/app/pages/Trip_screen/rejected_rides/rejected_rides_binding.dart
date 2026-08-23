import 'package:bam_bam_driver/app/pages/Trip_screen/trip_page.dart';
import 'package:bam_bam_driver/domain/domain.dart';
import 'package:get/get.dart';


class RejectedRidesBinding extends Bindings {
  @override
  void dependencies() {
    // Register the shared trip dependencies if not already present
    Get.lazyPut<TripUsecases>(() => TripUsecases(Get.find()), fenix: true);
    Get.lazyPut<TripPresenter>(
      () => TripPresenter(Get.find<TripUsecases>()),
      fenix: true,
    );

    Get.lazyPut<RejectedRidesController>(
      () => RejectedRidesController(Get.find<TripPresenter>()),
    );
  }
}

