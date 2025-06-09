import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:tution/providers/payment_provider.dart';
import 'package:tution/providers/tuition_info_provider.dart';
import 'package:tution/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tution/config/supabase_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ouetjtymbjvmdkomqxkd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91ZXRqdHltYmp2bWRrb21xeGtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc4NDUzMzIsImV4cCI6MjA2MzQyMTMzMn0.yY0TdhvCAzy1dJ7oo9KDryEF4Rf11yN5Mq5SvhmaJZM',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StudentProvider()),
        ChangeNotifierProvider(create: (context) => PaymentProvider()),
        ChangeNotifierProvider(create: (context) => TuitionInfoProvider()),
      ],
      child: MaterialApp(
        title: 'Tuition Management App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: Color(0xFFF7F9FB),
          cardColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 2,
            iconTheme: IconThemeData(color: Colors.blue),
            titleTextStyle: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
