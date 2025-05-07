import 'package:bus_tracker/screens/home.dart';
import 'package:bus_tracker/screens/d_login_Page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges() , 
      builder:(context, snapshot){
        if (snapshot.hasData ){
          return ActiveVehiclesPage();
        }

        else{
          return const LoginPage();
          
        }
      }
      
      ),
    );
  }
}