import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di/di.dart';
import 'core/theme/colors.dart';
import 'presentation/blocs/settings/settings_cubit.dart';
import 'presentation/blocs/stream/stream_cubit.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Dependency Injection
  await initDI();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>(),
        ),
        BlocProvider<StreamCubit>(
          create: (_) => sl<StreamCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Kora Live',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundDark,
          primaryColor: AppColors.neonCyan,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonCyan,
            secondary: AppColors.neonBlue,
            surface: AppColors.backgroundLightDark,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.textPrimary),
            bodyMedium: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
