import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/text_constants.dart';
import 'core/di/injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/checkin/checkin_bloc.dart';
import 'presentation/blocs/schedule/schedule_bloc.dart';
import 'presentation/blocs/gamification/gamification_bloc.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await initializeDependencies();

  runApp(const EcoCheckApp());
}

class EcoCheckApp extends StatelessWidget {
  const EcoCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthStatusChecked()),
        ),
        BlocProvider(create: (_) => sl<CheckinBloc>()),
        BlocProvider(create: (_) => sl<ScheduleBloc>()),
        BlocProvider(create: (_) => sl<GamificationBloc>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) {
            // Don't rebuild when RegistrationSuccess to preserve Navigator stack
            if (current is RegistrationSuccess) return false;

            // Don't rebuild when AuthLoading comes from registration
            // (previous was Unauthenticated/AuthError = user on LoginPage/RegisterPage)
            if (current is AuthLoading &&
                (previous is Unauthenticated ||
                    previous is AuthError ||
                    previous is RegistrationSuccess)) {
              return false;
            }

            return true;
          },
          builder: (context, state) {
            if (state is Authenticated) {
              return const HomePage();
            } else if (state is Unauthenticated || state is AuthError) {
              return const LoginPage();
            } else {
              // AuthLoading or AuthInitial
              return const SplashPage();
            }
          },
        ),
      ),
    );
  }
}

/// Temporary Splash Page
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Check auth status after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Auth status will be checked by AuthBloc
        // BlocListener in MaterialApp will handle navigation
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon Placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.recycling,
                  size: 80,
                  color: Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                AppStrings.appName,
                style: AppTextStyles.h1.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              // App Tagline
              Text(
                AppStrings.appTagline,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 48),
              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
