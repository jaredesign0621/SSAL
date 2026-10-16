import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ssal_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final ssalProvider = SsalProvider();
  await ssalProvider.loadInitialData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ssalProvider),
      ],
      child: const SsalApp(),
    ),
  );
}

class SsalApp extends StatelessWidget {
  const SsalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
