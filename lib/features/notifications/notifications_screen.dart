import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/local_notifications.dart';
import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/bills_repository.dart';

/// Persisted reminder settings (mirrors the RN `NotifSettings` shape stored
/// under `wealthify_notif`).
class _NotifSettings {
  const _NotifSettings({
    this.dailyReminder = false,
    this.dailyHour = 20,
    this.dailyMinute = 0,
    this.budgetAlerts = false,
    this.billReminders = false,
  });

  final bool dailyReminder;
  final int dailyHour;
  final int dailyMinute;
  final bool budgetAlerts;
  final bool billReminders;

  _NotifSettings copyWith({
    bool? dailyReminder,
    int? dailyHour,
    int? dailyMinute,
    bool? budgetAlerts,
    bool? billReminders,
  }) =>
      _NotifSettings(
        dailyReminder: dailyReminder ?? this.dailyReminder,
        dailyHour: dailyHour ?? this.dailyHour,
        dailyMinute: dailyMinute ?? this.dailyMinute,
        budgetAlerts: budgetAlerts ?? this.budgetAlerts,
        billReminders: billReminders ?? this.billReminders,
      );

  factory _NotifSettings.fromJson(Map<String, dynamic> j) => _NotifSettings(
        dailyReminder: j['dailyReminder'] == true,
        dailyHour: (j['dailyHour'] as num?)?.toInt() ?? 20,
        dailyMinute: (j['dailyMinute'] as num?)?.toInt() ?? 0,
        budgetAlerts: j['budgetAlerts'] == true,
        billReminders: j['billReminders'] == true,
      );

  Map<String, dynamic> toJson() => {
        'dailyReminder': dailyReminder,
        'dailyHour': dailyHour,
        'dailyMinute': dailyMinute,
        'budgetAlerts': budgetAlerts,
        'billReminders': billReminders,
      };
}

/// Hour presets for the daily reminder (24h), matching the RN segmented control.
const List<(int, String)> _timeOptions = [
  (9, '9:00'),
  (12, '12:00'),
  (18, '18:00'),
  (20, '20:00'),
  (21, '21:00'),
];

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotifSettings _settings = const _NotifSettings();
  bool _granted = false;
  bool _checkedPermission = false;

  /// Notifications are unsupported on web (mirrors RN's `Platform.OS !== 'web'`).
  static const bool _supported = !kIsWeb;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Restore saved settings (best-effort; keep defaults on any error).
    final raw = ref.read(prefsProvider).getString(Prefs.kNotifSettings);
    if (raw != null) {
      try {
        _settings =
            _NotifSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // ignore — keep defaults
      }
    }

    // Check current status without prompting: on iOS the system dialog shows
    // at most once, so re-prompting here would burn the one shot on screen
    // open and leave denied users with no path forward.
    bool granted = false;
    try {
      granted = await LocalNotifications.instance.isGranted();
    } catch (_) {
      granted = false;
    }

    if (!mounted) return;
    setState(() {
      _granted = granted;
      _checkedPermission = true;
    });
  }

  void _persist(_NotifSettings next) {
    ref
        .read(prefsProvider)
        .setString(Prefs.kNotifSettings, jsonEncode(next.toJson()));
  }

  Future<void> _enableNotifications() async {
    bool granted = false;
    try {
      granted = await LocalNotifications.instance.isGranted();
      granted =
          granted || await LocalNotifications.instance.requestPermission();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    setState(() => _granted = granted);
    if (!granted) {
      _showOpenSettingsSnack(
          'Notifications are off — enable them in Settings');
    }
  }

  Future<void> _toggleDaily(bool value) async {
    if (value) {
      bool granted = _granted;
      try {
        granted = await LocalNotifications.instance.isGranted();
        granted =
            granted || await LocalNotifications.instance.requestPermission();
      } catch (_) {
        granted = false;
      }
      if (!mounted) return;
      setState(() => _granted = granted);
      if (!granted) {
        // Leave the switch off if permission was refused.
        _showOpenSettingsSnack(
            'Notifications are off — enable them in Settings');
        return;
      }
    }

    final next = _settings.copyWith(dailyReminder: value);
    setState(() => _settings = next);
    _persist(next);

    if (value) {
      await LocalNotifications.instance
          .scheduleDaily(hour: next.dailyHour, minute: next.dailyMinute);
      if (!mounted) return;
      showAppSnack(context, 'Daily reminder scheduled');
    } else {
      await LocalNotifications.instance.cancelAll();
    }
  }

  Future<void> _changeTime(int hour) async {
    final next = _settings.copyWith(dailyHour: hour, dailyMinute: 0);
    setState(() => _settings = next);
    _persist(next);
    if (next.dailyReminder) {
      await LocalNotifications.instance.scheduleDaily(hour: hour, minute: 0);
    }
  }

  void _toggleBudgetAlerts(bool value) {
    final next = _settings.copyWith(budgetAlerts: value);
    setState(() => _settings = next);
    _persist(next);
  }

  void _toggleBillReminders(bool value) {
    final next = _settings.copyWith(billReminders: value);
    setState(() => _settings = next);
    _persist(next);
  }

  Future<void> _sendTest() async {
    bool granted = _granted;
    try {
      granted = await LocalNotifications.instance.isGranted();
      granted =
          granted || await LocalNotifications.instance.requestPermission();
    } catch (_) {
      granted = false;
    }
    if (mounted) setState(() => _granted = granted);
    if (!granted) {
      if (mounted) {
        _showOpenSettingsSnack(
            'Notifications are off — enable them in Settings');
      }
      return;
    }
    var ok = await LocalNotifications.instance.showTest();
    ok = ok || await LocalNotifications.instance.showTestDelayed();
    if (!mounted) return;
    showAppSnack(
      context,
      ok ? 'Test notification sent' : "Notifications aren't available here",
      error: !ok,
    );
  }

  void _showOpenSettingsSnack(String message) {
    final c = context.colors;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.negativeSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: c.negative),
          ),
          content: Row(
            children: [
              Icon(Icons.error, color: c.negative, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(message,
                    style: AppText.bodyMedium.copyWith(color: c.text)),
              ),
              TextButton(
                onPressed: _openAppSettings,
                child: Text('Settings',
                    style: AppText.bodyMedium.copyWith(color: c.primary)),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _openAppSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (_) {
      if (mounted) showAppSnack(context, 'Open Settings manually', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Reminders'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl4),
              children: [
                if (_checkedPermission && _supported && !_granted)
                  _permissionCard(c),
                if (_checkedPermission && _supported && _granted) _statusRow(c),
                if (!_supported) _unsupportedRow(c),

                // Daily reminder
                _sectionLabel(c, 'Daily reminder'),
                AppCard(
                  child: Column(
                    children: [
                      _switchRow(
                        c,
                        title: 'Daily logging reminder',
                        subtitle: "A nudge to record today's spending",
                        value: _settings.dailyReminder,
                        onChanged: _toggleDaily,
                      ),
                      if (_settings.dailyReminder) ...[
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Remind me at',
                            style: AppText.caption.copyWith(color: c.textSubtle),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _segmented(c),
                      ],
                    ],
                  ),
                ),

                // Other alerts
                _sectionLabel(c, 'Other alerts'),
                AppCard(
                  child: Column(
                    children: [
                      _switchRow(
                        c,
                        title: 'Budget threshold alerts',
                        subtitle: 'Alerts when you near a category limit',
                        value: _settings.budgetAlerts,
                        onChanged: _toggleBudgetAlerts,
                      ),
                      Divider(height: AppSpacing.xl2, color: c.divider),
                      _switchRow(
                        c,
                        title: 'Bill / recurring due reminders',
                        subtitle: 'Reminds you before a recurring charge',
                        value: _settings.billReminders,
                        onChanged: _toggleBillReminders,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                PillButton(
                  label: 'Send test notification',
                  variant: PillVariant.secondary,
                  onPressed: _sendTest,
                ),

                _sectionLabel(c, 'Alerts inbox'),
                const _ServerInbox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppColors c, String label) => Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
        child: Text(label, style: AppText.label.copyWith(color: c.textSubtle)),
      );

  Widget _statusRow(AppColors c) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: c.accentDark),
            const SizedBox(width: AppSpacing.xs),
            Text('Notifications are enabled',
                style: AppText.bodySm.copyWith(color: c.textSubtle)),
          ],
        ),
      );

  Widget _unsupportedRow(AppColors c) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: c.textSubtle),
            const SizedBox(width: AppSpacing.xs),
            Text("Notifications aren't available here",
                style: AppText.bodySm.copyWith(color: c.textSubtle)),
          ],
        ),
      );

  Widget _permissionCard(AppColors c) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 18, color: c.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Notifications are off',
                      style: AppText.bodyMedium.copyWith(color: c.text)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Allow notifications so Wealthify can remind you to log '
                'spending and warn you about budgets.',
                style: AppText.bodySm.copyWith(color: c.textSubtle),
              ),
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: 'Enable notifications',
                variant: PillVariant.secondary,
                onPressed: _enableNotifications,
              ),
            ],
          ),
        ),
      );

  Widget _switchRow(
    AppColors c, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyMedium.copyWith(color: c.text)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppText.caption.copyWith(color: c.textSubtle)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: c.primary,
        ),
      ],
    );
  }

  Widget _segmented(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          for (final opt in _timeOptions)
            Expanded(
              child: GestureDetector(
                onTap: () => _changeTime(opt.$1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _settings.dailyHour == opt.$1
                        ? c.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    opt.$2,
                    style: AppText.bodySm.copyWith(
                      color: _settings.dailyHour == opt.$1
                          ? c.textInverse
                          : c.textSubtle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Server-side alerts inbox (bill due, budget, recurring created).
class _ServerInbox extends ConsumerWidget {
  const _ServerInbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(notificationsProvider);

    return async.when(
      loading: () => const AppCard(
        child: Text('Loading alerts...'),
      ),
      error: (_, _) => AppCard(
        child: Text('Alerts unavailable offline',
            style: AppText.bodySm.copyWith(color: c.textSubtle)),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return AppCard(
            child: Text('No alerts yet',
                style: AppText.bodySm.copyWith(color: c.textSubtle)),
          );
        }
        return AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${result.unread} unread',
                        style:
                            AppText.caption.copyWith(color: c.textSubtle)),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await ref
                          .read(notificationsRepositoryProvider)
                          .markAllRead();
                      ref.invalidate(notificationsProvider);
                    },
                    child: Text('Mark all read',
                        style: AppText.caption.copyWith(
                            color: c.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final n in result.items.take(20)) ...[
                Opacity(
                  opacity: n.read ? 0.6 : 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        switch (n.type) {
                          'bill_due' => Icons.receipt_long_outlined,
                          'budget_alert' => Icons.warning_amber_outlined,
                          'recurring_created' => Icons.autorenew,
                          _ => Icons.swap_horiz_outlined,
                        },
                        size: 18,
                        color: n.read ? c.textSubtle : c.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: AppText.bodyMedium
                                    .copyWith(color: c.text)),
                            if (n.body != null)
                              Text(n.body!,
                                  style: AppText.caption.copyWith(
                                      color: c.textSubtle)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .markRead(n.id);
                          ref.invalidate(notificationsProvider);
                        },
                        child: Icon(Icons.check,
                            size: 18, color: c.textSubtle),
                      ),
                    ],
                  ),
                ),
                if (n != result.items.take(20).last)
                  Divider(height: AppSpacing.md, color: c.divider),
              ],
            ],
          ),
        );
      },
    );
  }
}
