import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/agregarEmprendimiento.dart';
import 'screens/editar_emprendimiento.dart';
import 'screens/detalle_emprendimiento.dart';
import 'screens/mis_emprendimientos.dart';
 
void main() {   
  runApp(const EmprendeApp());
}  


class EmprendeApp extends StatelessWidget {
  const EmprendeApp({super.key});

  @override
  Widget build(BuildContext context) {  
    const primaryColor = Color(0xFF1A3B5D); // Azul marino
    return MaterialApp(       
      debugShowCheckedModeBanner: false,
      title: 'EmprendeApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/agregar_emprendimiento': (context) => const AgregarEmprendimientoPage(),
        '/editar_emprendimiento': (context) => const EditarEmprendimientoScreen(),
        '/detalle_emprendimiento': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as int?;
          return DetalleEmprendimientoScreen(idEmprendimiento: args ?? 0);
        },
        '/mis_emprendimientos': (context) => const MisEmprendimientosScreen(),
      },
    );
  }
}
