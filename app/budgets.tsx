import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useFocusEffect, useRouter } from 'expo-router';
import { Card, CircleIconButton, PillButton, ScreenContainer } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { usePreferences } from '@/src/context/PreferencesContext';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

interface Txn {
    type?: string;
    category?: string;
    amount?: number;
}

interface BudgetRow {
    category: string;
    limit: number;
    spent: number;
}

export default function BudgetsScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();

    const [loading, setLoading] = useState(true);
    const [overall, setOverall] = useState<{ limit: number; spent: number } | null>(null);
    const [rows, setRows] = useState<BudgetRow[]>([]);

    const load = useCallback(() => {
        setLoading(true);
        Promise.all([api.getBudgets(), api.getStats()])
            .then(([budgetRes, statsRes]) => {
                const budgets: Record<string, number> = budgetRes.data?.response?.budgets || {};
                const stats = statsRes.data?.response || {};
                const allData: Txn[] = stats.allData || [];

                // Sum this-month expense spend per category.
                const spentByCategory: Record<string, number> = {};
                allData.forEach((t) => {
                    if (t.type === 'income') return;
                    const key = t.category || 'Other';
                    spentByCategory[key] = (spentByCategory[key] || 0) + (t.amount || 0);
                });

                if (budgets.Overall != null) {
                    setOverall({ limit: budgets.Overall, spent: stats.total_expenses || 0 });
                } else {
                    setOverall(null);
                }

                const list: BudgetRow[] = Object.keys(budgets)
                    .filter((k) => k !== 'Overall')
                    .map((category) => ({
                        category,
                        limit: budgets[category],
                        spent: spentByCategory[category] || 0,
                    }))
                    .sort((a, b) => b.spent / (b.limit || 1) - a.spent / (a.limit || 1));

                setRows(list);
            })
            .catch(() => {})
            .finally(() => setLoading(false));
    }, []);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Budgets</Text>
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
                    {overall ? (
                        <Card style={styles.overallCard}>
                            <Text style={styles.overallLabel}>Overall this month</Text>
                            <Text style={styles.overallValue}>
                                {formatCurrency(overall.spent)}{' '}
                                <Text style={styles.overallLimit}>/ {formatCurrency(overall.limit)}</Text>
                            </Text>
                            <ProgressBar value={overall.spent} max={overall.limit} colors={colors} styles={styles} />
                        </Card>
                    ) : null}

                    {rows.length === 0 ? (
                        <Card style={styles.empty}>
                            <Icon name="pie-chart-outline" size={34} color={colors.textSubtle} />
                            <Text style={styles.emptyTitle}>No category budgets yet</Text>
                            <Text style={styles.emptyBody}>
                                Set a monthly limit per category to track your spending against it.
                            </Text>
                        </Card>
                    ) : (
                        rows.map((row) => {
                            const icon = resolveCategoryIcon(row.category, 'expense');
                            const remaining = row.limit - row.spent;
                            const over = remaining < 0;
                            return (
                                <Card
                                    key={row.category}
                                    style={styles.row}
                                    onPress={() => router.push({ pathname: '/set-budget', params: { category: row.category } })}
                                >
                                    <View style={styles.rowTop}>
                                        <View style={[styles.iconWrap, { backgroundColor: (icon.color || colors.primary) + '22' }]}>
                                            <Icon name="pricetag" size={16} color={icon.color || colors.primary} />
                                        </View>
                                        <Text style={styles.rowTitle} numberOfLines={1}>{row.category}</Text>
                                        <Text style={[styles.rowAmount, over && { color: colors.negative }]}>
                                            {over ? `${formatCurrency(Math.abs(remaining))} over` : `${formatCurrency(remaining)} left`}
                                        </Text>
                                    </View>
                                    <ProgressBar value={row.spent} max={row.limit} colors={colors} styles={styles} />
                                    <Text style={styles.rowSub}>
                                        {formatCurrency(row.spent)} of {formatCurrency(row.limit)}
                                    </Text>
                                </Card>
                            );
                        })
                    )}

                    <PillButton
                        label="Set / edit a budget"
                        variant="secondary"
                        onPress={() => router.push('/set-budget')}
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
    const barColor = ratio >= 1 ? colors.negative : ratio >= 0.8 ? colors.warning : colors.accentDark;
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
        overallCard: { marginBottom: space.lg, gap: space.sm },
        overallLabel: { ...Typography.label, color: colors.textSubtle },
        overallValue: { ...Typography.titleLg, color: colors.text },
        overallLimit: { ...Typography.body, color: colors.textSubtle },
        row: { marginBottom: space.md, gap: space.sm },
        rowTop: { flexDirection: 'row', alignItems: 'center' },
        iconWrap: {
            width: 30, height: 30, borderRadius: 15,
            alignItems: 'center', justifyContent: 'center', marginRight: space.sm,
        },
        rowTitle: { ...Typography.bodyMedium, color: colors.text, flex: 1 },
        rowAmount: { ...Typography.bodySm, color: colors.textSubtle, fontFamily: Typography.bodyMedium.fontFamily },
        rowSub: { ...Typography.caption, color: colors.textSubtle },
        track: {
            height: 8, borderRadius: 4, backgroundColor: colors.surfaceMuted, overflow: 'hidden',
        },
        fill: { height: '100%', borderRadius: 4 },
        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
    });
