
import 'package:bus_tracker/admin/screens/profile.dart';
import 'package:bus_tracker/driver/driver_home.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/shared/pages/a_home_Page.dart';
import 'package:bus_tracker/shared/pages/e_forgotPassword_Page.dart';  
import 'package:bus_tracker/shared/pages/d_login_Page.dart';  

class AppRoutes {
  // Defining route names as static constants
  static const String loginPage = '/login';
  static const String homePage = '/home';
  static const String profilePage = '/profile';
  static const String activeVehiclesPage = '/active-vehicles';
  static const String forgotPasswordPage = '/forgot-password';
  static const String driverHomePage = '/driverMainPage';

  // Mapping route names to pages
  static Map<String, WidgetBuilder> get routes {
    return {
      loginPage: (context) => const LoginPage(),
      homePage: (context) => const Homepage(),
      profilePage: (context) => const ProfilePage(),   
      forgotPasswordPage: (context) => const ForgotPasswordPage(),
      driverHomePage: (context) => const DriverHomePage(),
    };
  }
}