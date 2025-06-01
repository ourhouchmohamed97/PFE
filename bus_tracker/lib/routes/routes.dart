import 'package:bus_tracker/screens/home.dart';
import 'package:bus_tracker/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/screens/a_home_Page.dart';
import 'package:bus_tracker/screens/e_forgotPassword_Page.dart';  
import 'package:bus_tracker/screens/d_login_Page.dart';  

class AppRoutes {
  // Defining route names as static constants
  static const String loginPage = '/login';
  static const String homePage = '/home';
  static const String profilePage = '/profile';
  static const String activeVehiclesPage = '/active-vehicles';
  static const String forgotPasswordPage = '/forgot-password';

  // Mapping route names to pages
  static Map<String, WidgetBuilder> get routes {
    return {
      loginPage: (context) => const LoginPage(),
      homePage: (context) => const Homepage(),
      profilePage: (context) => const ProfilePage(),  
      activeVehiclesPage: (context) => const ActiveVehiclesPage(),  
      forgotPasswordPage: (context) => const ForgotPasswordPage(),
    };
  }
}