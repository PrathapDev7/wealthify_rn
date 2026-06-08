import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import Toast from 'react-native-toast-message';
import { useFocusEffect, useRouter } from 'expo-router';
import { Card, CircleIconButton, ScreenContainer } from '@/src/components/ui';
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

interface MoverRow {
    name: string;
    current: number;
    previous: number;
    delta: number;
    deltaPct: number;
}

interface InsightsData {
    month: string;
    current: { expense: number; income: number; savings: number; savingsRate: number };
    previous: { expense: number };
    expenseDelta: number;
    expenseDeltaPct: number;
    projectedExpense: number;
    topCategories: MoverRow[];
    movers: MoverRow[];
    categories: any[];
}

export default function InsightsScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();

    const [loading, setLoading] = useState(true);
    const [data, setData] = useState<InsightsData | null>(null);

    const load = useCallback(async () => {
        setLoading(true);
        try {
            const res = await api.getInsights();
            setData(res.data?.data ?? null);
        } catch {
            setData(null);
            Toast.show({ type: 'error', text1: 'Could not load insights' });
        } finally {
            setLoading(false);
        }
    }, []);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const current = data?.current;
    const expenseDeltaPct = data?.expenseDeltaPct ?? 0;
    const spendUp = expenseDeltaPct > 0;
    const spendDown = expenseDeltaPct < 0;
    const maxTopCategory = useMemo(
        () => Math.max(1, ...(data?.topCategories ?? []).map((c) => c.current)),
        [data],
    );

    const hasAnyData =
        !!current &&
        (current.expense > 0 ||
            current.income > 0 ||
            current.savings !== 0 ||
            (data?.topCategories?.length ?? 0) > 0 ||
            (data?.movers?.length ?? 0) > 0);

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Insights</Text>
                <View style={{ width: 40 }} />
            </View>

            {loading ? (
                <View style={styles.center}>
                    <ActivityIndicator color={colors.primary} />
                </View>
            ) : !data ? (
                <View style={styles.center}>
                    <Card style={styles.empty}>
                        <Icon name="bulb-outline" size={34} color={colors.textSubtle} />
                        <Text style={styles.emptyTitle}>No insights yet</Text>
                        <Text style={styles.emptyBody}>
                            We could not load your insights right now. Pull back in a moment.
                        </Text>
                    </Card>
                </View>
            ) : (
                <ScrollView
                    showsVerticalScrollIndicator={false}
                    contentContainerStyle={styles.scroll}
                >
                    {data.month ? <Text style={styles.subtitle}>{data.month}</Text> : null}

                    {!hasAnyData ? (
                        <Card style={styles.empty}>
                            <Icon name="bulb-outline" size={34} color={colors.textSubtle} />
                            <Text style={styles.emptyTitle}>Nothing to show this month</Text>
                            <Text style={styles.emptyBody}>
                                Add some income or expenses and your monthly insights will appear here.
                            </Text>
                        </Card>
                    ) : (
                        <>
                            {/* Hero — this month spend */}
                            <Card style={styles.heroCard}>
                                <Text style={styles.heroLabel}>This month spend</Text>
                                <Text style={styles.heroValue}>
                                    {formatCurrency(current?.expense ?? 0)}
                                </Text>
                                <View
                                    style={[
                                        styles.deltaPill,
                                        {
                                            backgroundColor: spendUp
                                                ? colors.negativeSoft
                                                : spendDown
                                                    ? colors.accentSoft
                                                    : colors.surfaceMuted,
                                        },
                                    ]}
                                >
                                    <Icon
                                        name={
                                            spendUp
                                                ? 'arrow-up'
                                                : spendDown
                                                    ? 'arrow-down'
                                                    : 'remove'
                                        }
                                        size={13}
                                        color={
                                            spendUp
                                                ? colors.negative
                                                : spendDown
                                                    ? colors.accentDark
                                                    : colors.textSubtle
                                        }
                                    />
                                    <Text
                                        style={[
                                            styles.deltaText,
                                            {
                                                color: spendUp
                                                    ? colors.negative
                                                    : spendDown
                                                        ? colors.accentDark
                                                        : colors.textSubtle,
                                            },
                                        ]}
                                    >
                                        {spendUp ? '+' : ''}
                                        {Math.round(expenseDeltaPct)}% vs last month
                                    </Text>
                                </View>
                            </Card>

                            {/* Stat cards row */}
                            <View style={styles.statRow}>
                                <Card style={styles.statCard}>
                                    <Text style={styles.statLabel}>Income</Text>
                                    <Text style={styles.statValue} numberOfLines={1}>
                                        {formatCurrency(current?.income ?? 0)}
                                    </Text>
                                </Card>
                                <Card style={styles.statCard}>
                                    <Text style={styles.statLabel}>Savings</Text>
                                    <Text style={styles.statValue} numberOfLines={1}>
                                        {formatCurrency(current?.savings ?? 0)}
                                    </Text>
                                    <Text style={styles.statSub}>
                                        {Math.round(current?.savingsRate ?? 0)}% saved
                                    </Text>
                                </Card>
                                <Card style={styles.statCard}>
                                    <Text style={styles.statLabel}>Projected</Text>
                                    <Text style={styles.statValue} numberOfLines={1}>
                                        {formatCurrency(data.projectedExpense ?? 0)}
                                    </Text>
                                    <Text style={styles.statSub}>month-end</Text>
                                </Card>
                            </View>

                            {/* Top categories */}
                            {data.topCategories?.length ? (
                                <>
                                    <Text style={styles.sectionLabel}>Top categories</Text>
                                    <Card style={styles.sectionCard}>
                                        {data.topCategories.map((cat, idx) => {
                                            const ratio = Math.min(cat.current / maxTopCategory, 1);
                                            return (
                                                <View
                                                    key={cat.name}
                                                    style={[
                                                        styles.catRow,
                                                        idx > 0 && styles.catRowDivider,
                                                    ]}
                                                >
                                                    <View style={styles.catTop}>
                                                        <Text style={styles.catName} numberOfLines={1}>
                                                            {cat.name}
                                                        </Text>
                                                        <Text style={styles.catAmount}>
                                                            {formatCurrency(cat.current)}
                                                        </Text>
                                                    </View>
                                                    <View style={styles.track}>
                                                        <View
                                                            style={[
                                                                styles.fill,
                                                                {
                                                                    width: `${ratio * 100}%`,
                                                                    backgroundColor: colors.primary,
                                                                },
                                                            ]}
                                                        />
                                                    </View>
                                                </View>
                                            );
                                        })}
                                    </Card>
                                </>
                            ) : null}

                            {/* Biggest changes */}
                            {data.movers?.length ? (
                                <>
                                    <Text style={styles.sectionLabel}>Biggest changes</Text>
                                    <Card style={styles.sectionCard}>
                                        {data.movers.map((mover, idx) => {
                                            const up = mover.delta > 0;
                                            const down = mover.delta < 0;
                                            const moverColor = up
                                                ? colors.negative
                                                : down
                                                    ? colors.accentDark
                                                    : colors.textSubtle;
                                            return (
                                                <View
                                                    key={mover.name}
                                                    style={[
                                                        styles.moverRow,
                                                        idx > 0 && styles.catRowDivider,
                                                    ]}
                                                >
                                                    <Text style={styles.moverName} numberOfLines={1}>
                                                        {mover.name}
                                                    </Text>
                                                    <View style={styles.moverRight}>
                                                        <Icon
                                                            name={
                                                                up
                                                                    ? 'arrow-up'
                                                                    : down
                                                                        ? 'arrow-down'
                                                                        : 'remove'
                                                            }
                                                            size={13}
                                                            color={moverColor}
                                                        />
                                                        <Text style={[styles.moverDelta, { color: moverColor }]}>
                                                            {formatCurrency(Math.abs(mover.delta))}
                                                        </Text>
                                                        <Text style={styles.moverPct}>
                                                            {up ? '+' : down ? '-' : ''}
                                                            {Math.abs(Math.round(mover.deltaPct))}%
                                                        </Text>
                                                    </View>
                                                </View>
                                            );
                                        })}
                                    </Card>
                                </>
                            ) : null}
                        </>
                    )}

                    <View style={{ height: 60 }} />
                </ScrollView>
            )}
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
        center: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: space.xl },
        scroll: { paddingHorizontal: space.xl, paddingTop: space.sm, paddingBottom: space['3xl'] },
        subtitle: { ...Typography.label, color: colors.textSubtle, marginBottom: space.md },

        heroCard: { marginBottom: space.lg, gap: space.sm, alignItems: 'flex-start' },
        heroLabel: { ...Typography.label, color: colors.textSubtle },
        heroValue: { ...Typography.titleLg, color: colors.text },
        deltaPill: {
            flexDirection: 'row',
            alignItems: 'center',
            gap: 4,
            paddingHorizontal: space.sm,
            paddingVertical: 5,
            borderRadius: radius.pill,
        },
        deltaText: { ...Typography.caption, color: colors.textSubtle, fontFamily: Typography.bodyMedium.fontFamily },

        statRow: { flexDirection: 'row', gap: space.sm, marginBottom: space.lg },
        statCard: { flex: 1, gap: 4, paddingHorizontal: space.md },
        statLabel: { ...Typography.caption, color: colors.textSubtle },
        statValue: { ...Typography.moneySm, color: colors.text },
        statSub: { ...Typography.caption, color: colors.textSubtle },

        sectionLabel: { ...Typography.label, color: colors.textSubtle, marginBottom: space.sm },
        sectionCard: { marginBottom: space.lg, paddingVertical: space.xs },

        catRow: { paddingVertical: space.md, gap: space.sm },
        catRowDivider: { borderTopWidth: 1, borderTopColor: colors.divider },
        catTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
        catName: { ...Typography.bodyMedium, color: colors.text, flex: 1, marginRight: space.sm },
        catAmount: { ...Typography.bodySm, color: colors.textSubtle, fontFamily: Typography.bodyMedium.fontFamily },
        track: {
            height: 8, borderRadius: 4, backgroundColor: colors.surfaceMuted, overflow: 'hidden',
        },
        fill: { height: '100%', borderRadius: 4 },

        moverRow: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingVertical: space.md,
        },
        moverName: { ...Typography.bodyMedium, color: colors.text, flex: 1, marginRight: space.sm },
        moverRight: { flexDirection: 'row', alignItems: 'center', gap: 4 },
        moverDelta: { ...Typography.bodySm, fontFamily: Typography.bodyMedium.fontFamily },
        moverPct: { ...Typography.caption, color: colors.textSubtle, marginLeft: 2 },

        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
    });
