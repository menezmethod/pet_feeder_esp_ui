import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder_esp_ui/core/theme/theme_provider.dart';
import 'package:pet_feeder_esp_ui/core/utils/constants.dart';
import 'package:pet_feeder_esp_ui/features/pet_feeder/presentation/widgets/custom_dropdown.dart';
import 'package:pet_feeder_esp_ui/locale_keys.g.dart';
import 'package:provider/provider.dart';
import '../../application/providers/pet_feeder_provider.dart';
import '../../../../services/bluetooth_service.dart';
import '../../../../core/theme/glass.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PetFeederProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
    final t = GlassTokens.of(context);

    return Scaffold(
      backgroundColor: t.bg1,
      body: GlassBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  GlassCard(
                    radius: 12,
                    child: IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: t.ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    LocaleKeys.SettingPage_appBarTitle.tr(),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: t.ink),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const GlassSectionTitle('Device'),
              const SizedBox(height: 10),
              GlassCard(
                radius: 20,
                child: Column(
                  children: [
                    StreamBuilder<BleConnectionState>(
                      stream: bluetoothService.state,
                      initialData: bluetoothService.currentState,
                      builder: (context, snapshot) {
                        final state = snapshot.data ?? BleConnectionState.disconnected;
                        final (label, dotColor) = switch (state) {
                          BleConnectionState.connected => ('Feeder found nearby', const Color(0xFF3DA35D)),
                          BleConnectionState.connecting => ('Connecting...', const Color(0xFFCC7A2E)),
                          BleConnectionState.scanning => ('Looking for feeder...', const Color(0xFFCC7A2E)),
                          BleConnectionState.disconnected => ('Feeder not nearby', t.inkSoft),
                        };
                        return GlassRow(
                          icon: const GlassIconChip(icon: Icons.bluetooth_rounded),
                          title: LocaleKeys.SettingPage_bluetoothSetup.tr(),
                          subtitle: label,
                          trailing: Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                        );
                      },
                    ),
                    GlassRow(
                      showDivider: true,
                      icon: const GlassIconChip(icon: Icons.wifi_rounded),
                      title: LocaleKeys.SettingPage_wifiSettings.tr(),
                      subtitle: "Configure the feeder's connection",
                      trailing: Icon(Icons.chevron_right_rounded, color: t.inkSoft),
                      onTap: () => _showWifiSettingsDialog(context, bluetoothService),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const GlassSectionTitle('Feeding'),
              const SizedBox(height: 10),
              GlassCard(
                radius: 20,
                child: Column(
                  children: [
                    GlassRow(
                      icon: const GlassIconChip(icon: Icons.timer_outlined),
                      title: LocaleKeys.SettingPage_setPortionSize.tr(),
                      trailing: Icon(Icons.chevron_right_rounded, color: t.inkSoft),
                      onTap: () => _showPortionSizeDialog(context, provider),
                    ),
                    GlassRow(
                      showDivider: true,
                      icon: const GlassIconChip(icon: Icons.event_repeat_rounded),
                      title: LocaleKeys.SettingPage_enableGlobalScheduling.tr(),
                      trailing: Switch(
                        value: provider.isSchedulingEnabled,
                        activeColor: t.accent,
                        onChanged: (value) => provider.updateSchedulingEnabled(value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const GlassSectionTitle('Preferences'),
              const SizedBox(height: 10),
              GlassCard(
                radius: 20,
                child: Column(
                  children: [
                    GlassRow(
                      icon: const GlassIconChip(icon: Icons.translate_rounded),
                      title: LocaleKeys.SettingPage_setLanguage.tr(),
                      trailing: Icon(Icons.chevron_right_rounded, color: t.inkSoft),
                      onTap: () => _showLanguageDialog(context),
                    ),
                    GlassRow(
                      showDivider: true,
                      icon: const GlassIconChip(icon: Icons.dark_mode_rounded),
                      title: (themeProvider.isDark ? LocaleKeys.SettingPage_lightMode : LocaleKeys.SettingPage_darkMode).tr(),
                      trailing: Switch(
                        value: themeProvider.isDark,
                        activeColor: t.accent,
                        onChanged: (value) => themeProvider.isDark = value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWifiSettingsDialog(BuildContext context, BluetoothService bluetoothService) async {
    if (!bluetoothService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feeder not connected over Bluetooth yet -- keep this screen open and it will connect automatically.')),
      );
      return;
    }

    String ssid = '';
    String password = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final canSave = ssid.isNotEmpty && password.isNotEmpty;
            return AlertDialog(
              title: const Text(LocaleKeys.WifiSettingDialog_title).tr(),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: LocaleKeys.WifiSettingDialog_ssIdLabel.tr()),
                    onChanged: (value) => setState(() => ssid = value),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: LocaleKeys.WifiSettingDialog_passwordLabel.tr()),
                    onChanged: (value) => setState(() => password = value),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: !canSave
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final sent = await bluetoothService.sendWifiCredentials(ssid, password);
                          navigator.pop();
                          messenger.showSnackBar(SnackBar(
                            content: Text(sent
                                ? 'WiFi credentials sent -- the feeder will connect shortly.'
                                : 'Could not send WiFi credentials. Move closer and try again.'),
                          ));
                        },
                  child: const Text(LocaleKeys.ButtonCommonTitles_save).tr(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // There's no load cell on this hardware yet, so serving size genuinely is
  // servo runtime, not grams -- showing seconds (and validating against the
  // firmware's own MAX_DISPENSE_DURATION_MS) is the honest unit to expose
  // rather than implying a gram measurement the device can't make.
  static const _minServingMs = 200;
  static const _maxServingMs = 5000; // must match config.h MAX_DISPENSE_DURATION_MS

  void _showPortionSizeDialog(BuildContext context, PetFeederProvider provider) async {
    int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: (provider.portionSize / 1000).toStringAsFixed(1));
        return StatefulBuilder(
          builder: (context, setState) {
            final seconds = double.tryParse(controller.text);
            final ms = seconds == null ? null : (seconds * 1000).round();
            final isValid = ms != null && ms >= _minServingMs && ms <= _maxServingMs;
            return AlertDialog(
              title: const Text(LocaleKeys.SetPortionDialog_title).tr(),
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Feed duration (seconds)',
                  helperText: '${_minServingMs / 1000} - ${_maxServingMs / 1000} seconds',
                  errorText: isValid ? null : 'Enter a value between ${_minServingMs / 1000} and ${_maxServingMs / 1000}',
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: !isValid ? null : () => Navigator.of(context).pop(ms),
                  child: const Text(LocaleKeys.ButtonCommonTitles_save).tr(),
                ),
              ],
            );
          },
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
