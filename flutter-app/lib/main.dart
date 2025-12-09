import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/settings.dart';
import 'services/storage_service.dart';
import 'services/magnetometer_service.dart';
import 'services/compass_service.dart';
import 'services/export_service.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable Provider type checking for non-Listenable services
  Provider.debugCheckInvalidValueType = null;

  // Initialize storage service
  final storageService = StorageService();
  await storageService.initialize();

  // Load settings
  final settings = await storageService.loadSettings();

  runApp(CaveDiveMapApp(
    storageService: storageService,
    initialSettings: settings,
  ));
}

class CaveDiveMapApp extends StatelessWidget {
  final StorageService storageService;
  final Settings initialSettings;

  const CaveDiveMapApp({
    super.key,
    required this.storageService,
    required this.initialSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Storage service (non-listenable service)
        Provider<StorageService>(
          create: (_) => storageService,
        ),

        // Settings
        ChangeNotifierProvider<Settings>(
          create: (_) => initialSettings,
        ),

        // Magnetometer service with settings dependency
        ChangeNotifierProxyProvider<Settings, MagnetometerService>(
          create: (context) => MagnetometerService(storageService),
          update: (context, settings, previous) {
            final service = previous ?? MagnetometerService(storageService);
            service.updateSettings(
              wheelCircumference: settings.wheelCircumference,
              minPeakThreshold: settings.minPeakThreshold,
            );
            return service;
          },
        ),

        // Compass service
        ChangeNotifierProvider(
          create: (_) => CompassService(),
        ),

        // Export service
        Provider(create: (_) => ExportService()),
      ],
      child: MaterialApp(
        title: 'CaveDiveMap',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: Colors.cyan,
            secondary: Colors.blue,
            surface: Colors.grey[900]!,
            error: Colors.red,
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            elevation: 0,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
