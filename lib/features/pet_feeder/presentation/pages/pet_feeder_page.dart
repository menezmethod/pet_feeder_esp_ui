import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/pet_feeder_provider.dart';
import '../../domain/models/schedule.dart';
import '../widgets/custom_time_picker.dart';
import 'settings_page.dart';
import '../../../../core/utils/time_utils.dart';

class PetFeederPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PetFeederProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Crawler Pet Feeder'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.pets, size: 80, color: Theme.of(context).colorScheme.primaryContainer),
                        onPressed: provider.feedNow,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Feed Now',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                StreamBuilder<List<Schedule>>(
                  stream: provider.scheduleStream,
                  initialData: provider.schedules,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                    final schedules = snapshot.data ?? [];
                    return Column(
                      children: schedules.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Schedule schedule = entry.value;
                        return ListTile(
                          title: Text(formatTime(schedule.hour, schedule.minute)),
                          trailing: Switch(
                            value: schedule.enabled,
                            onChanged: (value) => provider.toggleSchedule(idx, value),
                          ),
                          onTap: () => _showCustomTimePicker(context, idx, schedule, provider),
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 20),
                StreamBuilder<bool>(
                  stream: provider.connectionStatusStream,
                  initialData: provider.isConnected,
                  builder: (context, snapshot) {
                    final isConnected = snapshot.data ?? false;
                    return Column(
                      children: [
                        Text('Connection Status: ${isConnected ? 'Connected' : 'Disconnected'}'),
                        if (!isConnected) ...[
                          SizedBox(height: 10),
                          Icon(Icons.sync_problem, color: Colors.red, size: 50),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: provider.connect,
                            child: Text('Reconnect'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomTimePicker(BuildContext context, int index, Schedule schedule, PetFeederProvider provider) async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return CustomTimePicker(
          initialTime: TimeOfDay(hour: schedule.hour, minute: schedule.minute),
        );
      },
    );

    if (result != null) {
      provider.updateScheduleTime(index, result.hour, result.minute);
    }
  }
}