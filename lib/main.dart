// main.dart
// Entry point for CoinPath Finance App with ultra-modern design system
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home_page.dart';
import 'theme.dart';
import 'models/budget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBPeHXl_S194HYalYctAbnvSpc0JRpoCcQ",
      authDomain: "coinpath789.firebaseapp.com",
      projectId: "coinpath789",
      storageBucket: "coinpath789.appspot.com",
      messagingSenderId: "1023996993497",
      appId: "1:1023996993497:web:91b1609890fa667a4743c8",
      measurementId: "G-3VKGT1XRTW",
    ),
  );

  runApp(const CoinPathApp());
}

class CoinPathApp extends StatelessWidget {
  const CoinPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BudgetModel(
          categoryBudgets: {},
          monthlyBudget: 0.0,
        )),
      ],
      child: MaterialApp(
        title: 'CoinPath Finance',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
