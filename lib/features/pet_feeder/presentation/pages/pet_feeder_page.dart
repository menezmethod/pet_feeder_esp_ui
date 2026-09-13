import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pet_feeder_esp_ui/locale_keys.g.dart';
import 'package:provider/provider.dart';
import '../../application/providers/pet_feeder_provider.dart';
import '../../domain/models/schedule.dart';
import '../../domain/models/last_fed.dart';
import 'settings_page.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/theme/glass.dart';

String _feedStatusLabel(FeedRequestState state) {
  switch (state) {
    case FeedRequestState.sending:
      return 'Sending...';
    case FeedRequestState.awaitingConfirmation:
      return 'Waiting for feeder to confirm...';
    case FeedRequestState.confirmed:
      return 'Fed!';
    case FeedRequestState.timedOut:
      return 'No confirmation received -- check the feeder';
    case FeedRequestState.idle:
      return LocaleKeys.PetFeederPage_feedTextLabel.tr();
  }
}

String _lastFedLabel(LastFed? lastFed) {
  if (lastFed == null) return 'Not fed yet this session';
  final triggerLabel = switch (lastFed.trigger) {
    'scheduled' => 'scheduled',
    'button' => 'manual button',
    _ => 'app',
  };
  if (lastFed.fedAt == null) {
    // Firmware fed before its clock synced -- a real time isn't known yet.
    return 'Just fed ($triggerLabel, time unknown)';
  }
  final t = lastFed.fedAt!.toLocal();
  final timeStr = formatTime(t.hour, t.minute);
  return 'Last fed $timeStr ($triggerLabel)';
}

class _FeedButton extends StatelessWidget {
  final PetFeederProvider provider;
  const _FeedButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final state = provider.feedRequestState;
    final busy = state == FeedRequestState.sending || state == FeedRequestState.awaitingConfirmation;

    final IconData icon;
    final Color glow;
    switch (state) {
      case FeedRequestState.confirmed:
        icon = Icons.check_circle_rounded;
        glow = const Color(0xFF3DA35D);
        break;
      case FeedRequestState.timedOut:
        icon = Icons.error_outline_rounded;
        glow = const Color(0xFFCC7A2E);
        break;
      default:
        icon = Icons.pets_rounded;
        glow = t.accent;
    }

    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            Color.lerp(glow, Colors.white, 0.55)!,
            glow,
            Color.lerp(glow, Colors.black, 0.18)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 40, offset: const Offset(0, 18)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(icon, size: 64, color: Colors.white),
            // Disabled while a request is genuinely in flight -- this is the
            // double-feed guard, not a blind debounce: feedNow() itself also
            // refuses to send a second request, this just keeps the button
            // from looking tappable while one is already running.
            onPressed: busy ? null : provider.feedNow,
          ),
          if (busy)
            const SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class PetFeederPage extends StatelessWidget {
  const PetFeederPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PetFeederProvider>(context);
    final t = GlassTokens.of(context);

    return Scaffold(
      backgroundColor: t.bg1,
      body: GlassBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CrawFeed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: t.ink),
                  ),
                  GlassCard(
                    radius: 14,
                    child: IconButton(
                      icon: Icon(Icons.settings_rounded, color: t.ink, size: 20),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<bool>(
                stream: provider.connectionStatusStream,
                initialData: provider.isConnected,
                builder: (context, snapshot) {
                  final isConnected = snapshot.data ?? false;
                  return Row(
                    children: [
                      GlassStatusPill(
                        label: isConnected ? LocaleKeys.PetFeederPage_connectionState.tr(args: ['Connected']) : LocaleKeys.PetFeederPage_connectionState.tr(args: ['Disconnected']),
                        dotColor: isConnected ? const Color(0xFF3DA35D) : const Color(0xFFB3453B),
                      ),
                      if (!isConnected) ...[
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: provider.connect,
                          child: Text(LocaleKeys.PetFeederPage_reconnectButtonTitle.tr(), style: TextStyle(color: t.accent, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              GlassCard(
                radius: 32,
                padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
                child: Column(
                  children: [
                    _FeedButton(provider: provider),
                    const SizedBox(height: 18),
                    Text(
                      _feedStatusLabel(provider.feedRequestState),
                      style: TextStyle(color: t.ink, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: t.inkSoft),
                        const SizedBox(width: 6),
                        Text(_lastFedLabel(provider.lastFed), style: TextStyle(color: t.inkSoft, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const GlassSectionTitle('Feeding Schedule'),
              const SizedBox(height: 10),
              StreamBuilder<List<Schedule>>(
                stream: provider.scheduleStream,
                initialData: provider.schedules,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        LocaleKeys.PetFeederPage_scheduleStreamError.tr(args: [snapshot.error.toString()]),
                        style: TextStyle(color: t.ink),
                      ),
                    );
                  }
                  final schedules = snapshot.data ?? [];
                  if (schedules.isEmpty) {
                    return GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(18),
                      child: Text('Waiting for the feeder\'s schedule...', style: TextStyle(color: t.inkSoft, fontSize: 14)),
                    );
                  }
                  return Column(
                    children: [
                      GlassCard(
                        radius: 20,
                        child: Column(
                          children: schedules.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final schedule = entry.value;
                            return GlassRow(
                              showDivider: idx > 0,
                              icon: const GlassIconChip(icon: Icons.schedule_rounded),
                              title: formatTime(schedule.hour, schedule.minute),
                              subtitle: describeDays(schedule.days),
                              onTap: () => _showScheduleEditDialog(context, idx, schedule, provider),
                              trailing: Switch(
                                value: schedule.enabled,
                                activeColor: t.accent,
                                onChanged: (value) => provider.toggleSchedule(idx, value),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (schedules.length < PetFeederProvider.maxSchedules) ...[
                        const SizedBox(height: 10),
                        GlassCard(
                          radius: 20,
                          child: GlassRow(
                            icon: Icon(Icons.add_rounded, size: 18, color: t.accent),
                            title: 'Add feeding time',
                            onTap: () => provider.addSchedule(),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleEditDialog(BuildContext context, int index, Schedule schedule, PetFeederProvider provider) async {
    int hour = schedule.hour;
    int minute = schedule.minute;
    int days = schedule.days;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Feeding Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(formatTime(hour, minute), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () async {
                      final result = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: hour, minute: minute),
                      );
                      if (result != null) {
                        setState(() {
                          hour = result.hour;
                          minute = result.minute;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    alignment: WrapAlignment.center,
                    children: List.generate(7, (i) {
                      final bit = 1 << i;
                      final active = (days & bit) != 0;
                      return ChoiceChip(
                        label: Text(weekdayLabels[i]),
                        selected: active,
                        onSelected: (_) => setState(() => days ^= bit),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    provider.removeSchedule(index);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: days == 0
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          provider.updateScheduleTimeAndDays(index, hour, minute, days);
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
}
