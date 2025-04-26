import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/resume/resume_list_screen.dart';
import 'screens/resume/resume_detail_screen.dart';
import 'screens/resume/upload_resume_screen.dart';
import 'screens/jobs/job_list_screen.dart';
import 'screens/jobs/job_detail_screen.dart';
import 'screens/applications/application_list_screen.dart';
import 'screens/applications/application_detail_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Resume Builder',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/resumes': (context) => const ResumeListScreen(),
              '/resumes/detail': (context) => const ResumeDetailScreen(),
              '/resumes/upload': (context) => const UploadResumeScreen(),
              '/jobs': (context) => const JobListScreen(),
              '/jobs/detail': (context) => const JobDetailScreen(),
              '/applications': (context) => const ApplicationListScreen(),
              '/applications/detail':
                  (context) => const ApplicationDetailScreen(),
            },
          );
        },
      ),
    );
  }
}
