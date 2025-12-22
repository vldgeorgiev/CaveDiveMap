import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'models/settings.dart';
import 'services/storage_service.dart';
import 'services/magnetometer_service.dart';
import 'services/compass_service.dart';
import 'services/export_service.dart';
import 'services/button_customization_service.dart';
import 'screens/main_screen.dart';
import 'utils/theme_extensions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable Provider type checking for non-Listenable services
  Provider.debugCheckInvalidValueType = null;

  // Initialize storage service and reload all persisted data
  // Survey data automatically loads on startup
  final storageService = StorageService();
  await storageService.initialize();

  // Load settings
  final settings = await storageService.loadSettings();

  // Apply fullscreen mode based on settings
  if (settings.fullscreen) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Initialize and load button customization settings
  final buttonCustomizationService = ButtonCustomizationService(storageService);
  await buttonCustomizationService.loadSettings();

  // Apply wakelock based on settings
  if (settings.keepScreenOn) {
    WakelockPlus.enable();
  }

  runApp(
    CaveDiveMapApp(
      storageService: storageService,
      initialSettings: settings,
      buttonCustomizationService: buttonCustomizationService,
    ),
  );
}

class CaveDiveMapApp extends StatelessWidget {
  final StorageService storageService;
  final Settings initialSettings;
  final ButtonCustomizationService buttonCustomizationService;

  const CaveDiveMapApp({
    super.key,
    required this.storageService,
    required this.initialSettings,
    required this.buttonCustomizationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Storage service (non-listenable service)
        Provider<StorageService>(create: (_) => storageService),

        // Settings
        ChangeNotifierProvider<Settings>(create: (_) => initialSettings),

        // Button customization service
        ChangeNotifierProvider<ButtonCustomizationService>(
          create: (_) => buttonCustomizationService,
        ),

        // Magnetometer service with settings dependency
        ChangeNotifierProxyProvider<Settings, MagnetometerService>(
          create: (context) => MagnetometerService(storageService),
          update: (context, settings, previous) {
            final service = previous ?? MagnetometerService(storageService);
            service.updateSettings(
              wheelCircumference: settings.wheelCircumference,
              minPeakThreshold: settings.minPeakThreshold,
              maxPeakThreshold: settings.maxPeakThreshold,
            );
            return service;
          },
        ),

        // Compass service
        ChangeNotifierProvider(create: (_) => CompassService()),

        // Export service
        Provider(create: (_) => ExportService()),
      ],
      child: MaterialApp(
        title: 'CaveDiveMap',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: AppColors.dataPrimary,
            secondary: AppColors.actionMap,
            surface: AppColors.backgroundCard,
            error: AppColors.actionReset,
          ),
          scaffoldBackgroundColor: AppColors.backgroundMain,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.backgroundCard,
            elevation: 0,
          ),
          textTheme: TextTheme(
            displayLarge: AppTextStyles.largeTitle,
            displayMedium: AppTextStyles.title,
            headlineMedium: AppTextStyles.headline,
            bodyLarge: AppTextStyles.body,
            bodyMedium: AppTextStyles.bodySemibold,
            labelSmall: AppTextStyles.caption,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
