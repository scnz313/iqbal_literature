import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/user_repository.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final userRepository = Get.find<UserRepository>();
    final user = userRepository.getCurrentUser();
    return null;
  }
}
