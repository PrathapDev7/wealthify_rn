import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
    Platform,
    Pressable,
    ScrollView,
    StyleSheet,
    Switch,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useRouter } from 'expo-router';
import Toast from 'react-native-toast-message';
import * as Notifications from 'expo-notifications';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Card, CircleIconButton, PillButton, ScreenContainer } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';

// Show notifications while the app is foregrounded.
Notifications.setNotificationHandler({
    handleNotification: async () => ({
        shouldShowBanner: true,
        shouldShowList: true,
        shouldPlaySound: false,
        shouldSetBadge: false,
    }),
});

const STORAGE_KEY = 'wealthify_notif';
const SUPPORTED = Platform.OS !== 'web';

interface NotifSettings {
    dailyReminder: boolean;
    dailyHour: number;
    dailyMinute: number;
    budgetAlerts: boolean;
    billReminders: boolean;
}

const DEFAULT_SETTINGS: NotifSettings = {
    dailyReminder: false,
    dailyHour: 20,
    dailyMinute: 0,
    budgetAlerts: false,
    billReminders: false,
};

interface TimeOption {
    value: number; // hour
    label: string;
}

const TIME_OPTIONS: TimeOption[] = [
    { value: 9, label: '9:00' },
    { value: 12, label: '12:00' },
    { value: 18, label: '18:00' },
    { value: 20, label: '20:00' },
    { value: 21, label: '21:00' },
];

function Segmented({
    options,
    value,
    onChange,
    styles,
    colors,
}: {
    options: TimeOption[];
    value: number;
    onChange: (v: number) => void;
    styles: ReturnType<typeof makeStyles>;
    colors: ColorPalette;
}) {
    return (
        <View style={styles.segment}>
            {options.map((opt) => {
                const active = opt.value === value;
                return (
                    <Pressable
                        key={opt.value}
                        onPress={() => onChange(opt.value)}
                        style={[styles.segmentItem, active && styles.segmentItemActive]}
                    >
                        <Text
                            style={[
                                styles.segmentLabel,
                                { color: active ? colors.textInverse : colors.textSubtle },
                            ]}
                        >
                            {opt.label}
                        </Text>
                    </Pressable>
                );
            })}
        </View>
    );
}

export default function NotificationsScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);

    const [settings, setSettings] = useState<NotifSettings>(DEFAULT_SETTINGS);
    const [granted, setGranted] = useState(false);
    const [checkedPermission, setCheckedPermission] = useState(false);

    // Load saved settings + current permission status on mount.
    useEffect(() => {
        (async () => {
            try {
                const saved = await AsyncStorage.getItem(STORAGE_KEY);
                if (saved) {
                    setSettings({ ...DEFAULT_SETTINGS, ...JSON.parse(saved) });
                }
            } catch {
                // ignore — keep defaults
            }
            if (SUPPORTED) {
                try {
                    const perm = await Notifications.getPermissionsAsync();
                    setGranted(perm.granted);
                } catch {
                    setGranted(false);
                }
            }
            setCheckedPermission(true);
        })();
    }, []);

    const persist = useCallback((next: NotifSettings) => {
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
    }, []);

    // Ensure we have permission, requesting it if needed. Returns whether granted.
    const ensurePermission = useCallback(async (): Promise<boolean> => {
        if (!SUPPORTED) {
            Toast.show({ type: 'info', text1: "Notifications aren't available here" });
            return false;
        }
        try {
            const current = await Notifications.getPermissionsAsync();
            if (current.granted) {
                setGranted(true);
                return true;
            }
            const req = await Notifications.requestPermissionsAsync();
            setGranted(req.granted);
            if (!req.granted) {
                Toast.show({ type: 'info', text1: 'Notification permission denied' });
            }
            return req.granted;
        } catch {
            Toast.show({ type: 'info', text1: "Notifications aren't available here" });
            return false;
        }
    }, []);

    // Cancel everything then re-schedule the daily reminder if enabled.
    const syncSchedule = useCallback(async (next: NotifSettings) => {
        if (!SUPPORTED) {
            Toast.show({ type: 'info', text1: "Notifications aren't available here" });
            return;
        }
        try {
            await Notifications.cancelAllScheduledNotificationsAsync();
            if (next.dailyReminder) {
                await Notifications.scheduleNotificationAsync({
                    content: {
                        title: 'Wealthify',
                        body: "Don't forget to log today's spending.",
                    },
                    trigger: {
                        type: Notifications.SchedulableTriggerInputTypes.DAILY,
                        hour: next.dailyHour,
                        minute: next.dailyMinute,
                    },
                });
            }
        } catch {
            Toast.show({ type: 'info', text1: "Notifications aren't available here" });
        }
    }, []);

    const update = useCallback(
        (patch: Partial<NotifSettings>) => {
            setSettings((prev) => {
                const next = { ...prev, ...patch };
                persist(next);
                return next;
            });
        },
        [persist],
    );

    const onToggleDaily = useCallback(
        async (value: boolean) => {
            if (value) {
                const ok = await ensurePermission();
                if (!ok) return; // leave the switch off if permission was refused
            }
            const next = { ...settings, dailyReminder: value };
            update({ dailyReminder: value });
            await syncSchedule(next);
            if (value) {
                Toast.show({ type: 'success', text1: 'Daily reminder scheduled' });
            }
        },
        [settings, ensurePermission, update, syncSchedule],
    );

    const onChangeTime = useCallback(
        async (hour: number) => {
            const next = { ...settings, dailyHour: hour, dailyMinute: 0 };
            update({ dailyHour: hour, dailyMinute: 0 });
            if (next.dailyReminder) {
                await syncSchedule(next);
            }
        },
        [settings, update, syncSchedule],
    );

    const onEnableNotifications = useCallback(async () => {
        await ensurePermission();
    }, [ensurePermission]);

    const onSendTest = useCallback(async () => {
        const ok = await ensurePermission();
        if (!ok) return;
        try {
            await Notifications.scheduleNotificationAsync({
                content: { title: 'Wealthify', body: 'This is a test reminder.' },
                trigger: {
                    type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
                    seconds: 2,
                },
            });
            Toast.show({ type: 'success', text1: 'Test notification sent' });
        } catch {
            Toast.show({ type: 'info', text1: "Notifications aren't available here" });
        }
    }, [ensurePermission]);

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Reminders</Text>
                <View style={{ width: 40 }} />
            </View>

            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
            >
                {/* Permission status */}
                {checkedPermission && SUPPORTED && !granted ? (
                    <Card style={styles.permCard}>
                        <View style={styles.permTop}>
                            <Icon name="notifications-off-outline" size={18} color={colors.warning} />
                            <Text style={styles.permTitle}>Notifications are off</Text>
                        </View>
                        <Text style={styles.permBody}>
                            Allow notifications so Wealthify can remind you to log spending and warn you
                            about budgets.
                        </Text>
                        <PillButton
                            label="Enable notifications"
                            variant="secondary"
                            onPress={onEnableNotifications}
                            style={{ marginTop: space.sm }}
                        />
                    </Card>
                ) : null}

                {checkedPermission && SUPPORTED && granted ? (
                    <View style={styles.statusRow}>
                        <Icon name="checkmark-circle" size={16} color={colors.accentDark} />
                        <Text style={styles.statusText}>Notifications are enabled</Text>
                    </View>
                ) : null}

                {!SUPPORTED ? (
                    <View style={styles.statusRow}>
                        <Icon name="information-circle-outline" size={16} color={colors.textSubtle} />
                        <Text style={styles.statusText}>Notifications aren't available here</Text>
                    </View>
                ) : null}

                {/* Daily reminder */}
                <Text style={styles.sectionLabel}>Daily reminder</Text>
                <Card style={styles.card}>
                    <View style={styles.rowBetween}>
                        <View style={styles.rowTextWrap}>
                            <Text style={styles.rowLabel}>Daily logging reminder</Text>
                            <Text style={styles.rowHint}>A nudge to record today's spending</Text>
                        </View>
                        <Switch
                            value={settings.dailyReminder}
                            onValueChange={onToggleDaily}
                            trackColor={{ true: colors.primary, false: colors.surfaceMuted }}
                            thumbColor={colors.surface}
                        />
                    </View>

                    {settings.dailyReminder ? (
                        <View style={styles.timeWrap}>
                            <Text style={styles.rowHint}>Remind me at</Text>
                            <Segmented
                                options={TIME_OPTIONS}
                                value={settings.dailyHour}
                                onChange={onChangeTime}
                                styles={styles}
                                colors={colors}
                            />
                        </View>
                    ) : null}
                </Card>

                {/* Other alerts */}
                <Text style={styles.sectionLabel}>Other alerts</Text>
                <Card style={styles.card}>
                    <View style={styles.rowBetween}>
                        <View style={styles.rowTextWrap}>
                            <Text style={styles.rowLabel}>Budget threshold alerts</Text>
                            <Text style={styles.rowHint}>Alerts when you near a category limit</Text>
                        </View>
                        <Switch
                            value={settings.budgetAlerts}
                            onValueChange={(v) => update({ budgetAlerts: v })}
                            trackColor={{ true: colors.primary, false: colors.surfaceMuted }}
                            thumbColor={colors.surface}
                        />
                    </View>

                    <View style={styles.divider} />

                    <View style={styles.rowBetween}>
                        <View style={styles.rowTextWrap}>
                            <Text style={styles.rowLabel}>Bill / recurring due reminders</Text>
                            <Text style={styles.rowHint}>Reminds you before a recurring charge</Text>
                        </View>
                        <Switch
                            value={settings.billReminders}
                            onValueChange={(v) => update({ billReminders: v })}
                            trackColor={{ true: colors.primary, false: colors.surfaceMuted }}
                            thumbColor={colors.surface}
                        />
                    </View>
                </Card>

                <PillButton
                    label="Send test notification"
                    variant="secondary"
                    onPress={onSendTest}
                    style={{ marginTop: space.lg }}
                />
                <View style={{ height: 60 }} />
            </ScrollView>
        </ScreenContainer>
    );
}

const makeStyles = (colors: ColorPalette) =>
    StyleSheet.create({
        header: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingHorizontal: space.xl,
            paddingTop: space.md,
            paddingBottom: space.md,
        },
        headerTitle: { ...Typography.screenTitle, color: colors.text },
        scroll: {
            paddingHorizontal: space.xl,
            paddingTop: space.sm,
            paddingBottom: space['3xl'],
        },
        permCard: { gap: space.sm, marginBottom: space.md },
        permTop: { flexDirection: 'row', alignItems: 'center', gap: space.sm },
        permTitle: { ...Typography.bodyMedium, color: colors.text },
        permBody: { ...Typography.bodySm, color: colors.textSubtle },
        statusRow: {
            flexDirection: 'row',
            alignItems: 'center',
            gap: space.xs,
            marginBottom: space.xs,
            paddingHorizontal: space.xs,
        },
        statusText: { ...Typography.bodySm, color: colors.textSubtle },
        sectionLabel: {
            ...Typography.label,
            color: colors.textSubtle,
            marginTop: space.xl,
            marginBottom: space.sm,
        },
        card: { gap: space.md },
        rowBetween: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
        },
        rowTextWrap: { flex: 1, paddingRight: space.md, gap: 2 },
        rowLabel: { ...Typography.bodyMedium, color: colors.text },
        rowHint: { ...Typography.caption, color: colors.textSubtle },
        timeWrap: { gap: space.sm },
        divider: { height: StyleSheet.hairlineWidth, backgroundColor: colors.border },
        segment: {
            flexDirection: 'row',
            backgroundColor: colors.surfaceMuted,
            borderRadius: radius.sm,
            padding: 4,
            gap: 4,
        },
        segmentItem: {
            flex: 1,
            alignItems: 'center',
            justifyContent: 'center',
            paddingVertical: 10,
            borderRadius: radius.xs,
        },
        segmentItemActive: { backgroundColor: colors.primary },
        segmentLabel: {
            ...Typography.bodySm,
            fontFamily: Typography.bodyMedium.fontFamily,
        },
    });
