// main.dart
// Entry point for CoinPath Finance App with modern design system
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_page.dart';
import 'theme.dart';
import 'models/budget.dart';
import 'services/firestore_service.dart';

// Test Firestore connection
void testFirestore() async {
  try {
    await FirebaseFirestore.instance.collection('test').add({'timestamp': DateTime.now()});
    final snapshot = await FirebaseFirestore.instance.collection('test').get();
    for (var doc in snapshot.docs) {
      print('Document ID: ${doc.id}, Data: ${doc.data()}');
    }
    print('Firestore test completed successfully.');
  } catch (e) {
    print('Error testing Firestore: $e');
  }
}

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

  // Run Firestore test
  testFirestore();

  runApp(const CoinPathApp());
}

class CoinPathApp extends StatelessWidget {
  const CoinPathApp({Key? key}) : super(key: key);

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
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
