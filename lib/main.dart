import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder_esp_ui/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/pet_feeder/application/providers/pet_feeder_provider.dart';
import 'features/pet_feeder/data/repositories/mqtt_pet_feeder_repository.dart';
import 'features/pet_feeder/presentation/pages/pet_feeder_page.dart';
import 'services/mqtt_service.dart';

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
                broker: 'broker.hivemq.com',
                port: 8884,
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

class _CrawFeedState extends State<CrawFeed> {
  @override
  void initState() {
    super.initState();
    debugPrint('Building CrawFeed...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mqttService = Provider.of<MqttService>(context, listen: false);
      mqttService.connect().then((_) {
        mqttService.publish('pet_feeder_esp32/v1/status/general', '');
      });
    });
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
