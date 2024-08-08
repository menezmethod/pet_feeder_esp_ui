import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder_esp_ui/core/theme/theme_provider.dart';
import 'package:pet_feeder_esp_ui/core/utils/constants.dart';
import 'package:pet_feeder_esp_ui/features/pet_feeder/presentation/widgets/custom_dropdown.dart';
import 'package:pet_feeder_esp_ui/locale_keys.g.dart';
import 'package:provider/provider.dart';
import '../../application/providers/pet_feeder_provider.dart';
import '../../../../services/bluetooth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PetFeederProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bluetoothService = BluetoothService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(LocaleKeys.SettingPage_appBarTitle).tr(),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text(LocaleKeys.SettingPage_bluetoothSetup).tr(),
            trailing: const Icon(Icons.bluetooth),
            onTap: () => bluetoothService.connectToBluetoothDevice(),
          ),
          ListTile(
            title: const Text(LocaleKeys.SettingPage_wifiSettings).tr(),
            trailing: const Icon(Icons.wifi),
            onTap: () => _showWifiSettingsDialog(context, bluetoothService),
          ),
          ListTile(
            title: const Text(LocaleKeys.SettingPage_setPortionSize).tr(),
            trailing: const Icon(Icons.food_bank),
            onTap: () => _showPortionSizeDialog(context, provider),
          ),
          SwitchListTile(
            title: const Text(LocaleKeys.SettingPage_enableGlobalScheduling).tr(),
            value: provider.isSchedulingEnabled,
            onChanged: (value) => provider.updateSchedulingEnabled(value),
          ),
          ListTile(
            title: const Text(LocaleKeys.SettingPage_setLanguage).tr(),
            trailing: const Icon(Icons.translate),
            onTap: () => _showLanguageDialog(context),
          ),
          SwitchListTile(
            title: Text(themeProvider.isDark ? LocaleKeys.SettingPage_lightMode : LocaleKeys.SettingPage_darkMode).tr(),
            value: themeProvider.isDark,
            onChanged: (value) => themeProvider.isDark = value,
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
          title: const Text(LocaleKeys.WifiSettingDialog_title).tr(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: LocaleKeys.WifiSettingDialog_ssIdLabel.tr()),
                onChanged: (value) => ssid = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: LocaleKeys.WifiSettingDialog_passwordLabel.tr()),
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
              child: const Text(LocaleKeys.ButtonCommonTitles_save).tr(),
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
          title: const Text(LocaleKeys.SetPortionDialog_title).tr(),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              tempPortionSize = int.tryParse(value) ?? tempPortionSize;
            },
            decoration: InputDecoration(
              hintText: LocaleKeys.SetPortionDialog_portionSizeHint.tr(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(tempPortionSize);
              },
              child: const Text(LocaleKeys.ButtonCommonTitles_save).tr(),
            ),
          ],
        );
      },
    );
    if (result != null) {
      provider.updateServingSize(result);
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text(LocaleKeys.SetLanguageDialog_title).tr(),
              content: Row(children: [
                const Text(LocaleKeys.SetLanguageDialog_languageLabel).tr(),
                CustomDropDown<Locale>(
                    context.supportedLocales
                        .map((locale) => DropdownMenuItem<Locale>(
                              value: locale,
                              child: Text((Constants.languageMap[locale.languageCode] ?? Constants.languageMap["en"])!).tr(),
                            ))
                        .toList(),
                    context.locale, (Locale? locale) async {
                  await context.setLocale(locale!);
                })
              ]));
        });
  }
}
