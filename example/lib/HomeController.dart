import 'package:get/get.dart';

class Homecontroller extends GetxController {
  static Homecontroller to = Get.find();

  String iddd = "idddd";

  updateIddd() {
    print("__________+++++++============");
    update([iddd]);
  }
}
