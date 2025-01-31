import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/init_service.dart';
import 'config/routes/app_pages.dart';  // Update this import
import 'firebase_options.dart';
import 'features/presentation/pages/home/home_page.dart';
import 'config/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Then initialize app services
  await InitService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Get.find<ThemeProvider>();
    
    return GetMaterialApp(
      title: 'Iqbal Literature',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: Routes.home,
      getPages: AppPages.routes,
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Page Not Found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.offAllNamed(Routes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('Please try again later', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
