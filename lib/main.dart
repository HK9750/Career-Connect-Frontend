import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/screens/applications/recruiter_application_screen.dart';
import 'package:frontend/screens/jobs/create_job_screen.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/api_service.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  await apiService.init();

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),

        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: apiService),
        ),
      ],
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
              '/create-job': (context) => const CreateJobScreen(),
              '/applications': (context) => const ApplicationListScreen(),
              '/recruiters-application':
                  (context) => const RecruiterApplicationsScreen(),
              '/applications/detail':
                  (context) => const ApplicationDetailScreen(),
            },
          );
        },
      ),
    );
  }
}
