import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/validation_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PlanogramValidatorApp());
}

class PlanogramValidatorApp extends StatelessWidget {
  const PlanogramValidatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider(create: (_) => apiService),
        ChangeNotifierProvider(
          create: (_) => ValidationProvider(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Planogram Validator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2ECC71),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2ECC71),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
