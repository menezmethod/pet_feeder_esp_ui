import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/pet_feeder/application/providers/pet_feeder_provider.dart';
import 'features/pet_feeder/data/repositories/mqtt_pet_feeder_repository.dart';
import 'features/pet_feeder/presentation/pages/pet_feeder_page.dart';
import 'services/mqtt_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<MqttService>(
          create: (_) {
            print('Creating MqttService...');
            return MqttService(
              broker: 'broker.hivemq.com',
              port: 8884,
            );
          },
          dispose: (_, service) {
            print('Disposing MqttService...');
            service.disconnect();
          },
        ),
        ProxyProvider<MqttService, MqttPetFeederRepository>(
          update: (_, mqttService, __) {
            print('Creating MqttPetFeederRepository...');
            return MqttPetFeederRepository(mqttService);
          },
        ),
        ChangeNotifierProxyProvider<MqttPetFeederRepository, PetFeederProvider>(
          create: (context) {
            print('Creating PetFeederProvider...');
            return PetFeederProvider(
              context.read<MqttPetFeederRepository>(),
            );
          },
          update: (_, repository, previous) {
            print('Updating PetFeederProvider...');
            return previous!..updateRepository(repository);
          },
        ),
      ],
      child: CrawFeed(),
    ),
  );
}

class CrawFeed extends StatelessWidget {
  const CrawFeed({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building CrawFeed...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mqttService = Provider.of<MqttService>(context, listen: false);
      mqttService.connect().then((_) {
        mqttService.publish('pet_feeder_esp32/v1/status/general', '');
      });
    });

    return MaterialApp(
      title: 'CrawFeed',
      theme: AppTheme.lightTheme,
      home: PetFeederPage(),
    );
  }
}