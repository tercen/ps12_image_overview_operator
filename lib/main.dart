import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/image_overview_provider.dart';
import 'presentation/screens/image_overview_screen.dart';
import 'utils/tercen_url_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse URL to determine deployment mode
  final urlParser = TercenUrlParser();
  print('📋 URL Parser initialized: $urlParser');

  bool useMocks = true;

  // Try to connect to Tercen if we have valid context
  if (urlParser.hasValidContext || urlParser.taskId != null) {
    try {
      print('🔍 Attempting Tercen connection...');
      await createServiceFactoryForWebApp();
      useMocks = false;
      print('✓ Connected to Tercen');
    } catch (e) {
      print('⚠️ Tercen connection failed: $e');
      print('   Falling back to mock data');
    }
  } else {
    print('🔧 No Tercen context detected - using mock data');
  }

  // Register URL parser with DI
  getIt.registerSingleton<TercenUrlParser>(urlParser);

  // Setup service locator (mock or real)
  setupServiceLocator(useMocks: useMocks);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<ThemeProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<ImageOverviewProvider>()..loadImages(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'PS12 Image Overview',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            home: const ImageOverviewScreen(),
          );
        },
      ),
    );
  }
}
