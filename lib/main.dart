import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/pet_feeder/application/providers/pet_feeder_provider.dart';
import 'features/pet_feeder/presentation/pages/pet_feeder_page.dart';
import 'services/mqtt_service.dart';
import 'features/pet_feeder/data/repositories/mqtt_pet_feeder_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PetFeederProvider(
            MqttPetFeederRepository(
              MqttService(
                broker: '192.168.0.221',
                port: 9001,
              ),
            ),
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Feeder Control',
      theme: AppTheme.lightTheme,
      home: PetFeederPage(),
    );
  }
}