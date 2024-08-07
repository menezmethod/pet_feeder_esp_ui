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
              broker: '192.168.0.221',
              port: 9001,
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
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building MyApp...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Connecting MqttService...');
      Provider.of<MqttService>(context, listen: false).connect();
    });

    return MaterialApp(
      title: 'Pet Feeder Control',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => PetFeederPage(),
      },
    );
  }
}