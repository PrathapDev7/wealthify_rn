import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useFocusEffect, useRouter } from 'expo-router';
import Toast from 'react-native-toast-message';
import { Card, CircleIconButton, PillButton, ScreenContainer } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { usePreferences } from '@/src/context/PreferencesContext';
import ConfirmationModal from '@/src/components/common/ConfirmationModal';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

type Frequency = 'daily' | 'weekly' | 'monthly' | 'yearly';

interface Recurring {
    _id: string;
    kind: 'expense' | 'income';
    amount: number;
    category: string;
    sub_category?: string;
    title?: string;
    description?: string;
    frequency: Frequency;
    interval: number;
    startDate: string;
    nextRunDate: string;
    endDate?: string;
    active: boolean;
}

// Build a human-readable cadence like "Every day", "Every 2 weeks", "Monthly".
const describeFrequency = (interval: number, frequency: Frequency): string => {
    const n = interval && interval > 0 ? interval : 1;
    const unit: Record<Frequency, string> = {
        daily: 'day',
        weekly: 'week',
        monthly: 'month',
        yearly: 'year',
    };
    if (n === 1) {
        switch (frequency) {
            case 'daily':
                return 'Every day';
            case 'weekly':
                return 'Weekly';
            case 'monthly':
                return 'Monthly';
            case 'yearly':
                return 'Yearly';
        }
    }
    return `Every ${n} ${unit[frequency]}s`;
};

export default function RecurringScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();

    const [loading, setLoading] = useState(true);
    const [rules, setRules] = useState<Recurring[]>([]);
    const [busyId, setBusyId] = useState<string | null>(null);
    const [pendingDelete, setPendingDelete] = useState<Recurring | null>(null);

    const load = useCallback(() => {
        setLoading(true);
        api.getRecurring()
            .then((res) => {
                setRules(res.data?.data || []);
            })
            .catch((err: any) => {
                Toast.show({
                    type: 'error',
                    text1: err?.response?.data?.message || 'Something went wrong',
                });
            })
            .finally(() => setLoading(false));
    }, []);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const toggleActive = async (rule: Recurring) => {
        setBusyId(rule._id);
        try {
            await api.updateRecurring(rule._id, { active: !rule.active });
            Toast.show({
                type: 'success',
                text1: rule.active ? 'Recurring paused' : 'Recurring resumed',
            });
            load();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err?.response?.data?.message || 'Something went wrong',
            });
        } finally {
            setBusyId(null);
        }
    };

    const confirmDelete = async () => {
        if (!pendingDelete) return;
        const id = pendingDelete._id;
        setPendingDelete(null);
        try {
            await api.deleteRecurring(id);
            Toast.show({ type: 'success', text1: 'Recurring deleted' });
            load();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err?.response?.data?.message || 'Something went wrong',
            });
        }
    };

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Recurring</Text>
                <View style={{ width: 40 }} />
            </View>

            {loading ? (
                <View style={styles.center}>
                    <ActivityIndicator color={colors.primary} />
                </View>
            ) : (
                <ScrollView
                    showsVerticalScrollIndicator={false}
                    contentContainerStyle={styles.scroll}
                >
                    {rules.length === 0 ? (
                        <Card style={styles.empty}>
                            <Icon name="repeat-outline" size={34} color={colors.textSubtle} />
                            <Text style={styles.emptyTitle}>No recurring transactions</Text>
                            <Text style={styles.emptyBody}>
                                Automate bills, subscriptions and regular income. Add a rule and
                                Wealthify will create each entry on schedule.
                            </Text>
                        </Card>
                    ) : (
                        rules.map((rule) => {
                            const isExpense = rule.kind === 'expense';
                            const kindColor = isExpense ? colors.negative : colors.accentDark;
                            const busy = busyId === rule._id;
                            return (
                                <Card
                                    key={rule._id}
                                    style={[styles.row, !rule.active && styles.rowInactive]}
                                    onPress={() =>
                                        router.push({
                                            pathname: '/edit-recurring',
                                            params: { id: rule._id },
                                        })
                                    }
                                >
                                    <View style={styles.rowTop}>
                                        <View
                                            style={[
                                                styles.iconWrap,
                                                { backgroundColor: kindColor + '22' },
                                            ]}
                                        >
                                            <Icon
                                                name={isExpense ? 'arrow-up' : 'arrow-down'}
                                                size={16}
                                                color={kindColor}
                                            />
                                        </View>
                                        <View style={styles.rowBody}>
                                            <Text style={styles.rowTitle} numberOfLines={1}>
                                                {rule.category}
                                            </Text>
                                            {rule.description ? (
                                                <Text style={styles.rowDesc} numberOfLines={1}>
                                                    {rule.description}
                                                </Text>
                                            ) : null}
                                        </View>
                                        <Text style={[styles.rowAmount, { color: kindColor }]}>
                                            {formatCurrency(rule.amount)}
                                        </Text>
                                    </View>

                                    <Text style={styles.rowSub}>
                                        {describeFrequency(rule.interval, rule.frequency)}
                                        {rule.nextRunDate ? ` · next ${rule.nextRunDate}` : ''}
                                    </Text>

                                    <View style={styles.actions}>
                                        <TouchableOpacity
                                            activeOpacity={0.8}
                                            disabled={busy}
                                            onPress={() => toggleActive(rule)}
                                            style={styles.actionBtn}
                                        >
                                            {busy ? (
                                                <ActivityIndicator
                                                    size="small"
                                                    color={colors.primary}
                                                />
                                            ) : (
                                                <>
                                                    <Icon
                                                        name={rule.active ? 'pause' : 'play'}
                                                        size={15}
                                                        color={colors.primary}
                                                    />
                                                    <Text style={styles.actionLabel}>
                                                        {rule.active ? 'Pause' : 'Resume'}
                                                    </Text>
                                                </>
                                            )}
                                        </TouchableOpacity>
                                        <TouchableOpacity
                                            activeOpacity={0.8}
                                            onPress={() => setPendingDelete(rule)}
                                            style={styles.actionBtn}
                                        >
                                            <Icon
                                                name="trash-outline"
                                                size={15}
                                                color={colors.negative}
                                            />
                                            <Text
                                                style={[
                                                    styles.actionLabel,
                                                    { color: colors.negative },
                                                ]}
                                            >
                                                Delete
                                            </Text>
                                        </TouchableOpacity>
                                    </View>
                                </Card>
                            );
                        })
                    )}

                    <PillButton
                        label="Add recurring"
                        onPress={() => router.push('/edit-recurring')}
                        style={{ marginTop: space.lg }}
                    />
                    <View style={{ height: 60 }} />
                </ScrollView>
            )}

            <ConfirmationModal
                visible={!!pendingDelete}
                onClose={() => setPendingDelete(null)}
                onConfirm={confirmDelete}
                message="Delete this recurring transaction? Future entries will no longer be created."
            />
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
        center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
        scroll: {
            paddingHorizontal: space.xl,
            paddingTop: space.sm,
            paddingBottom: space['3xl'],
        },
        row: { marginBottom: space.md, gap: space.sm },
        rowInactive: { opacity: 0.55 },
        rowTop: { flexDirection: 'row', alignItems: 'center' },
        iconWrap: {
            width: 30,
            height: 30,
            borderRadius: 15,
            alignItems: 'center',
            justifyContent: 'center',
            marginRight: space.sm,
        },
        rowBody: { flex: 1 },
        rowTitle: { ...Typography.bodyMedium, color: colors.text },
        rowDesc: { ...Typography.bodySm, color: colors.textSubtle, marginTop: 1 },
        rowAmount: {
            ...Typography.bodyStrong,
            marginLeft: space.sm,
        },
        rowSub: { ...Typography.caption, color: colors.textSubtle },
        actions: {
            flexDirection: 'row',
            gap: space.sm,
            marginTop: space.xs,
            borderTopWidth: StyleSheet.hairlineWidth,
            borderTopColor: colors.border,
            paddingTop: space.sm,
        },
        actionBtn: {
            flex: 1,
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 5,
            paddingVertical: 8,
            borderRadius: radius.sm,
            backgroundColor: colors.surfaceMuted,
        },
        actionLabel: {
            ...Typography.bodySm,
            color: colors.primary,
            fontFamily: Typography.bodyMedium.fontFamily,
        },
        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
    });
