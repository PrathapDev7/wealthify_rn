import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    ScrollView,
    StyleSheet,
    Text,
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
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

interface Contribution {
    amount: number;
    date: string;
    note?: string;
}

interface Goal {
    _id: string;
    name: string;
    targetAmount: number;
    savedAmount: number;
    targetDate?: string;
    icon?: string;
    color?: string;
    note?: string;
    completed: boolean;
    contributions: Contribution[];
}

const formatDate = (iso?: string) => {
    if (!iso) return '';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return '';
    return d.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });
};

export default function GoalsScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();

    const [loading, setLoading] = useState(true);
    const [goals, setGoals] = useState<Goal[]>([]);

    const load = useCallback(() => {
        setLoading(true);
        api.getGoals()
            .then((res) => {
                const list: Goal[] = res.data?.data || [];
                setGoals(list);
            })
            .catch(() => {
                Toast.show({ type: 'error', text1: 'Failed to load goals' });
            })
            .finally(() => setLoading(false));
    }, []);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const totalSaved = goals.reduce((sum, g) => sum + (g.savedAmount || 0), 0);

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Savings goals</Text>
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
                    {goals.length > 0 ? (
                        <Card style={styles.totalCard}>
                            <Text style={styles.totalLabel}>Total saved across goals</Text>
                            <Text style={styles.totalValue}>{formatCurrency(totalSaved)}</Text>
                        </Card>
                    ) : null}

                    {goals.length === 0 ? (
                        <Card style={styles.empty}>
                            <Icon name="flag-outline" size={34} color={colors.textSubtle} />
                            <Text style={styles.emptyTitle}>No savings goals yet</Text>
                            <Text style={styles.emptyBody}>
                                Set a target to save towards, then track every contribution here.
                            </Text>
                        </Card>
                    ) : (
                        goals.map((goal) => {
                            const target = goal.targetAmount || 0;
                            const ratio = target > 0 ? Math.min(goal.savedAmount / target, 1) : 0;
                            const percent = Math.round(ratio * 100);
                            const date = formatDate(goal.targetDate);
                            return (
                                <Card
                                    key={goal._id}
                                    style={styles.row}
                                    onPress={() =>
                                        router.push({ pathname: '/goal-detail', params: { id: goal._id } })
                                    }
                                >
                                    <View style={styles.rowTop}>
                                        <Text style={styles.rowTitle} numberOfLines={1}>{goal.name}</Text>
                                        {goal.completed ? (
                                            <View style={styles.badge}>
                                                <Icon name="checkmark" size={12} color={colors.textInverse} />
                                                <Text style={styles.badgeText}>Completed</Text>
                                            </View>
                                        ) : (
                                            <Text style={styles.rowPercent}>{percent}%</Text>
                                        )}
                                    </View>
                                    <ProgressBar value={goal.savedAmount} max={target} colors={colors} styles={styles} />
                                    <Text style={styles.rowSub}>
                                        {formatCurrency(goal.savedAmount)} of {formatCurrency(target)}
                                    </Text>
                                    {date ? (
                                        <Text style={styles.rowDate}>Target date {date}</Text>
                                    ) : null}
                                </Card>
                            );
                        })
                    )}

                    <PillButton
                        label="New goal"
                        onPress={() => router.push('/goal-detail')}
                        style={{ marginTop: space.lg }}
                    />
                    <View style={{ height: 60 }} />
                </ScrollView>
            )}
        </ScreenContainer>
    );
}

const ProgressBar = ({
    value,
    max,
    colors,
    styles,
}: {
    value: number;
    max: number;
    colors: ColorPalette;
    styles: ReturnType<typeof makeStyles>;
}) => {
    const ratio = max > 0 ? Math.min(value / max, 1) : 0;
    const barColor = ratio >= 1 ? colors.accentDark : colors.primary;
    return (
        <View style={styles.track}>
            <View style={[styles.fill, { width: `${ratio * 100}%`, backgroundColor: barColor }]} />
        </View>
    );
};

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
        scroll: { paddingHorizontal: space.xl, paddingTop: space.sm, paddingBottom: space['3xl'] },
        totalCard: { marginBottom: space.lg, gap: space.xs },
        totalLabel: { ...Typography.label, color: colors.textSubtle },
        totalValue: { ...Typography.titleLg, color: colors.text },
        row: { marginBottom: space.md, gap: space.sm },
        rowTop: { flexDirection: 'row', alignItems: 'center' },
        rowTitle: { ...Typography.bodyMedium, color: colors.text, flex: 1 },
        rowPercent: { ...Typography.bodySm, color: colors.textSubtle, fontFamily: Typography.bodyMedium.fontFamily },
        rowSub: { ...Typography.caption, color: colors.textSubtle },
        rowDate: { ...Typography.caption, color: colors.textSubtle },
        badge: {
            flexDirection: 'row',
            alignItems: 'center',
            gap: 3,
            paddingHorizontal: space.sm,
            paddingVertical: 3,
            borderRadius: radius.xs,
            backgroundColor: colors.accentDark,
        },
        badgeText: { ...Typography.caption, color: colors.textInverse, fontFamily: Typography.bodyMedium.fontFamily },
        track: {
            height: 8, borderRadius: 4, backgroundColor: colors.surfaceMuted, overflow: 'hidden',
        },
        fill: { height: '100%', borderRadius: 4 },
        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
    });
