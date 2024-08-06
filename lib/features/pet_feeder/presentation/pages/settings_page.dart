import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/pet_feeder_provider.dart';
import '../../../../services/bluetooth_service.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PetFeederProvider>(context);
    final bluetoothService = BluetoothService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Set up Bluetooth'),
            trailing: Icon(Icons.bluetooth),
            onTap: () => bluetoothService.connectToBluetoothDevice(),
          ),
          ListTile(
            title: Text('Wi-Fi Settings'),
            trailing: Icon(Icons.wifi),
            onTap: () => _showWifiSettingsDialog(context, bluetoothService),
          ),
          ListTile(
            title: Text('Set Portion Size'),
            trailing: Icon(Icons.food_bank),
            onTap: () => _showPortionSizeDialog(context, provider),
          ),
          SwitchListTile(
            title: Text('Enable Global Scheduling'),
            value: provider.isSchedulingEnabled,
            onChanged: (value) => provider.updateSchedulingEnabled(value),
          ),
        ],
      ),
    );
  }

  void _showWifiSettingsDialog(BuildContext context, BluetoothService bluetoothService) async {
    String ssid = '';
    String password = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Wi-Fi Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'SSID'),
                onChanged: (value) => ssid = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Password'),
                onChanged: (value) => password = value,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                bluetoothService.sendWifiCredentials(ssid, password);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPortionSizeDialog(BuildContext context, PetFeederProvider provider) async {
    int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempPortionSize = provider.portionSize;
        return AlertDialog(
          title: Text('Set Portion Size'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              tempPortionSize = int.tryParse(value) ?? tempPortionSize;
            },
            decoration: InputDecoration(
              hintText: 'Enter portion size',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(tempPortionSize);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      provider.updateServingSize(result);
    }
  }
}