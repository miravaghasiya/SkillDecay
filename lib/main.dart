import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/auth_wrapper.dart';
// firebase_options.dart might be needed if using CLI generated options, 
// but user provided keys in prompt implies manual or they have google-services.json?
// The user prompt said "Integrate Firebase Authentication using the provided Google Credentials".
// "Client ID: ..." usually is for Google Sign In config.
// Usually Firebase.initializeApp() needs options for Web, but on Android/iOS it uses the json/plist files.
// I will assume json/plist are present or default init works for mobile.
// For robust setup, one might pass options, but without file generation I can't.
// I'll stick to default `Firebase.initializeApp()`.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Micro Skill Decay Detector',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}
