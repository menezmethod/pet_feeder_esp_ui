import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder_esp_ui/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/pet_feeder/application/providers/pet_feeder_provider.dart';
import 'features/pet_feeder/data/repositories/mqtt_pet_feeder_repository.dart';
import 'features/pet_feeder/presentation/pages/pet_feeder_page.dart';
import 'services/mqtt_service.dart';
import 'services/bluetooth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    MultiProvider(
        providers: [
          Provider<MqttService>(
            create: (_) {
              debugPrint('Creating MqttService...');
              return MqttService(
                broker: '47.203.87.233',
                port: 8883,
              );
            },
            dispose: (_, service) {
              debugPrint('Disposing MqttService...');
              service.disconnect();
            },
          ),
          ProxyProvider<MqttService, MqttPetFeederRepository>(
            update: (_, mqttService, __) {
              debugPrint('Creating MqttPetFeederRepository...');
              return MqttPetFeederRepository(mqttService);
            },
            dispose: (_, repository) {
              debugPrint('Disposing MqttPetFeederRepository...');
              repository.dispose();
            },
          ),
          ChangeNotifierProxyProvider<MqttPetFeederRepository, PetFeederProvider>(
            create: (context) {
              debugPrint('Creating PetFeederProvider...');
              return PetFeederProvider(
                context.read<MqttPetFeederRepository>(),
              );
            },
            update: (_, repository, previous) {
              debugPrint('Updating PetFeederProvider...');
              return previous!..updateRepository(repository);
            },
          ),
          Provider<BluetoothService>(
            create: (_) {
              debugPrint('Creating BluetoothService...');
              return BluetoothService();
            },
            dispose: (_, service) {
              debugPrint('Disposing BluetoothService...');
              service.dispose();
            },
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [
            Locale('en'),
          ],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          saveLocale: true,
          useOnlyLangCode: false,
          child: const CrawFeed(),
        )),
  );
}

class CrawFeed extends StatefulWidget {
  const CrawFeed({super.key});

  @override
  State<CrawFeed> createState() => _CrawFeedState();
}

// MQTT connection is owned by PetFeederProvider (connects in its own
// constructor) -- this widget's only lifecycle job is BLE: start watching
// for the feeder when the app is in the foreground, stop when it isn't.
// That's the entire mechanism behind "pairing is seamless as long as the
// app is open" -- no scanning happens otherwise, and no manual BLE app
// (LightBlue or similar) should be needed for normal WiFi provisioning.
class _CrawFeedState extends State<CrawFeed> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothService>().startWatching();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bluetooth = context.read<BluetoothService>();
    if (state == AppLifecycleState.resumed) {
      bluetooth.startWatching();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      bluetooth.stopWatching();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, notifier, child) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            title: 'CrawFeed',
            theme: notifier.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const PetFeederPage(),
          );
        },
      ),
    );
  }
}
