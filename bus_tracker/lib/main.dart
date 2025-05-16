import 'package:bus_tracker/screens/a_home_Page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Ensure Flutter is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Make sure you have the correct options
  );
   await Supabase.initialize(
    url: 'https://zwumxngvwacexmgzcpeg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3dW14bmd2d2FjZXhtZ3pjcGVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxNjUwNzQsImV4cCI6MjA2Mjc0MTA3NH0.25adn7E75ioKuheVKNfc2fW47v6V8s4QXGytUUx7qnA',
  );
  runApp( const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  const Homepage(),
    );
  }
}
