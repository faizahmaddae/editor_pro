import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Use permanent to keep controller alive when navigating back from editor
    Get.put<HomeController>(
      HomeController(),
      permanent: true,
    );
  }
}
