import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import { PieChart } from 'react-native-gifted-charts';
import Icon from 'react-native-vector-icons/Ionicons';
import moment from 'moment';
import { useFocusEffect } from 'expo-router';
import APIService from '@/src/ApiService/api.service';
import {
    Card,
    IconBadge,
    ScreenContainer,
    SectionHeader,
} from '@/src/components/ui';
import {
    Colors,
    Fonts,
    Shadows,
    Typography,
    radius,
    space,
} from '@/src/styles/theme';
import { formatNumberWithCommas } from '@/src/utils/helper';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';

const api = new APIService();

interface Txn {
    _id?: string;
    type?: 'income' | 'expense';
    title?: string;
    category?: string;
    sub_category?: string;
    date?: string;
    createdAt?: string;
    amount?: number;
}

type RangeKey = 'today' | 'yesterday' | 'last3Days' | 'thisWeek' | 'thisMonth' | 'thisYear';

const RANGE_OPTIONS: { key: RangeKey; label: string }[] = [
    { key: 'today', label: 'Today' },
    { key: 'yesterday', label: 'Yesterday' },
    { key: 'last3Days', label: 'Last 3 days' },
    { key: 'thisWeek', label: 'This week' },
    { key: 'thisMonth', label: 'This month' },
    { key: 'thisYear', label: 'This year' },
];

const buildDateRange = (key: RangeKey) => {
    const today = moment();
    let start = today.clone().startOf('day');
    let end = today.clone().endOf('day');
    let previousStart = start.clone().subtract(1, 'day');
    let previousEnd = end.clone().subtract(1, 'day');

    if (key === 'yesterday') {
        start = today.clone().subtract(1, 'day').startOf('day');
        end = today.clone().subtract(1, 'day').endOf('day');
        previousStart = start.clone().subtract(1, 'day');
        previousEnd = end.clone().subtract(1, 'day');
    } else if (key === 'last3Days') {
        start = today.clone().subtract(2, 'days').startOf('day');
        end = today.clone().endOf('day');
        previousStart = start.clone().subtract(3, 'days');
        previousEnd = end.clone().subtract(3, 'days');
    } else if (key === 'thisWeek') {
        start = today.clone().startOf('isoWeek');
        end = today.clone().endOf('isoWeek');
        previousStart = start.clone().subtract(1, 'week');
        previousEnd = end.clone().subtract(1, 'week');
    } else if (key === 'thisMonth') {
        start = today.clone().startOf('month');
        end = today.clone().endOf('month');
        previousStart = start.clone().subtract(1, 'month').startOf('month');
        previousEnd = start.clone().subtract(1, 'month').endOf('month');
    } else if (key === 'thisYear') {
        start = today.clone().startOf('year');
        end = today.clone().endOf('year');
        previousStart = start.clone().subtract(1, 'year');
        previousEnd = end.clone().subtract(1, 'year');
    }

    return { start, end, previousStart, previousEnd };
};

const readTransactions = (res: any, collectionKey: 'incomes' | 'expenses') =>
    Array.isArray(res.data) ? res.data : res.data?.[collectionKey] || [];

const getTxnSortTime = (txn: Txn) => {
    const timestamp = moment(txn.createdAt || txn.date).valueOf();
    return Number.isFinite(timestamp) ? timestamp : 0;
};

export default function TransactionsScreen() {
    const [selectedRangeKey, setSelectedRangeKey] = useState<RangeKey>('thisMonth');
    const [rangeMenuOpen, setRangeMenuOpen] = useState(false);
    const [selectedDonutIndex, setSelectedDonutIndex] = useState<number | null>(null);
    const [incomes, setIncomes] = useState<Txn[]>([]);
    const [expenses, setExpenses] = useState<Txn[]>([]);

    const selectedRange = useMemo(
        () => RANGE_OPTIONS.find((option) => option.key === selectedRangeKey) || RANGE_OPTIONS[5],
        [selectedRangeKey],
    );
    const sectionTitle = useMemo(
        () => `All transactions from ${selectedRange.label.toLowerCase()}`,
        [selectedRange.label],
    );
    const emptyRangeLabel = useMemo(
        () =>
            selectedRangeKey === 'last3Days'
                ? 'the last 3 days'
                : selectedRange.label.toLowerCase(),
        [selectedRange.label, selectedRangeKey],
    );
    const rangeConfig = useMemo(() => buildDateRange(selectedRangeKey), [selectedRangeKey]);

    const load = useCallback(() => {
        const currentRange = {
            start_date: rangeConfig.start.format('YYYY-MM-DD'),
            end_date: rangeConfig.end.format('YYYY-MM-DD'),
        };
        api.getIncomes(currentRange)
            .then((res) => {
                const list = readTransactions(res, 'incomes');
                setIncomes(list.map((t: Txn) => ({ ...t, type: 'income' })));
            })
            .catch(() => {});
        api.getExpenses(currentRange)
            .then((res) => {
                const list = readTransactions(res, 'expenses');
                setExpenses(list.map((t: Txn) => ({ ...t, type: 'expense' })));
            })
            .catch(() => {});
    }, [rangeConfig]);


    useEffect(() => {
        load();
    }, [load]);

    useFocusEffect(
        useCallback(() => {
            load();
        }, [load]),
    );

    const totals = useMemo(() => {
        const sum = (list: Txn[]) => list.reduce((a, b) => a + Number(b.amount || 0), 0);
        const curIncome = sum(incomes);
        const curExpense = sum(expenses);

        return {
            curIncome,
            curExpense,
        };
    }, [incomes, expenses]);

    const all = useMemo(
        () =>
            [...incomes, ...expenses]
                .sort((a, b) => getTxnSortTime(b) - getTxnSortTime(a))
                .slice(0, 30),
        [incomes, expenses],
    );
    const incomeExpenseTotals = useMemo(
        () => [
            {
                value: totals.curIncome,
                color: Colors.primary,
                label: 'Income',
            },
            {
                value: totals.curExpense,
                color: Colors.accentDark,
                label: 'Expense',
            },
        ].filter((item) => item.value > 0),
        [totals.curExpense, totals.curIncome],
    );
    const incomeExpenseBalance = totals.curIncome - totals.curExpense;
    const selectedDonutItem =
        selectedDonutIndex === null ? null : incomeExpenseTotals[selectedDonutIndex];

    useEffect(() => {
        setSelectedDonutIndex(null);
    }, [incomeExpenseTotals]);

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
                onTouchStart={() => {
                    if (rangeMenuOpen) setRangeMenuOpen(false);
                    setSelectedDonutIndex(null);
                }}
            >
                <View style={styles.headerRow}>
                    <Text style={styles.title}>Transactions</Text>
                </View>

                <Card style={styles.donutCard}>
                    <View style={[styles.chartHeader, rangeMenuOpen && styles.chartHeaderMenuOpen]}>
                        <View
                            style={styles.rangeControl}
                            onTouchStart={(event) => event.stopPropagation()}
                        >
                            <Pressable
                                accessibilityRole="button"
                                onPress={() => setRangeMenuOpen((open) => !open)}
                                style={styles.rangePill}
                            >
                                <Text style={styles.rangeText}>{selectedRange.label}</Text>
                                <Icon
                                    name={rangeMenuOpen ? 'chevron-up' : 'chevron-down'}
                                    size={14}
                                    color={Colors.text}
                                />
                            </Pressable>
                            {rangeMenuOpen ? (
                                <View style={styles.rangeMenu}>
                                    {RANGE_OPTIONS.map((option) => {
                                        const active = option.key === selectedRangeKey;
                                        return (
                                            <Pressable
                                                key={option.key}
                                                accessibilityRole="button"
                                                onPress={() => {
                                                    setSelectedRangeKey(option.key);
                                                    setRangeMenuOpen(false);
                                                }}
                                                style={[
                                                    styles.rangeOption,
                                                    active && styles.rangeOptionActive,
                                                ]}
                                            >
                                                <Text
                                                    style={[
                                                        styles.rangeOptionText,
                                                        active && styles.rangeOptionTextActive,
                                                    ]}
                                                >
                                                    {option.label}
                                                </Text>
                                            </Pressable>
                                        );
                                    })}
                                </View>
                            ) : null}
                        </View>
                    </View>
                    <View style={styles.donutWrap}>
                        {incomeExpenseTotals.length > 0 ? (
                            <>
                                <PieChart
                                    donut
                                    data={incomeExpenseTotals as any}
                                    radius={86}
                                    innerRadius={62}
                                    innerCircleColor={Colors.surface}
                                    paddingHorizontal={72}
                                    onPress={(_item: unknown, index: number) => {
                                        setRangeMenuOpen(false);
                                        setSelectedDonutIndex(index);
                                    }}
                                    centerLabelComponent={() => (
                                        <View style={styles.donutCenter}>
                                            <Text style={styles.donutCenterSmall}>Balance</Text>
                                            <Text style={styles.donutCenterBig}>
                                                {incomeExpenseBalance < 0 ? '-' : ''}₹{formatNumberWithCommas(
                                                    Math.abs(incomeExpenseBalance).toFixed(0),
                                                )}
                                            </Text>
                                        </View>
                                    )}
                                />
                                {selectedDonutItem ? (
                                    <View pointerEvents="none" style={styles.donutTooltipOverlay}>
                                        <View style={styles.donutTooltip}>
                                            <Text style={styles.donutTooltipLabel}>
                                                {selectedDonutItem.label}
                                            </Text>
                                            <Text style={styles.donutTooltipValue}>
                                                ₹{formatNumberWithCommas(
                                                    selectedDonutItem.value.toFixed(0),
                                                )}
                                            </Text>
                                        </View>
                                    </View>
                                ) : null}
                            </>
                        ) : (
                            <EmptyDonutState rangeLabel={emptyRangeLabel} />
                        )}
                    </View>
                    {incomeExpenseTotals.length > 0 ? (
                        <View style={styles.donutLegendRow}>
                            <Legend dot={Colors.primary} label="Income" />
                            <Legend dot={Colors.accentDark} label="Expense" />
                        </View>
                    ) : null}
                </Card>

                <SectionHeader title={sectionTitle} />

                {all.length === 0 ? (
                    <EmptyTransactionsState />
                ) : (
                    <View style={styles.txnList}>
                        {all.map((t, idx) => (
                            <TxnRow key={t._id || idx} txn={t} isFirst={idx === 0} />
                        ))}
                    </View>
                )}

                <View style={styles.bottomSpacer} />
            </ScrollView>
        </ScreenContainer>
    );
}

const Legend: React.FC<{ dot: string; label: string }> = ({ dot, label }) => (
    <View style={legendStyles.row}>
        <View style={[legendStyles.dot, { backgroundColor: dot }]} />
        <Text style={legendStyles.label}>{label}</Text>
    </View>
);

const EmptyDonutState: React.FC<{ rangeLabel: string }> = ({ rangeLabel }) => (
    <View style={styles.emptyChartState}>
        <View style={styles.emptyChartGraphic}>
            <View style={styles.emptyRingOuter}>
                <View style={styles.emptyRingInner}>
                    <Icon name="pie-chart-outline" size={28} color={Colors.primary} />
                </View>
            </View>
            <View style={[styles.emptySpark, styles.emptySparkIncome]} />
            <View style={[styles.emptySpark, styles.emptySparkExpense]} />
        </View>
        <Text style={styles.emptyTitle}>Nothing to chart yet</Text>
        <Text style={styles.emptySubText}>
            Add income or expenses for {rangeLabel} and your balance breakdown will appear here.
        </Text>
        <View style={styles.emptyMetricRow}>
            <View style={styles.emptyMetric}>
                <View style={[styles.emptyMetricDot, { backgroundColor: Colors.primary }]} />
                <Text style={styles.emptyMetricText}>Income ₹0</Text>
            </View>
            <View style={styles.emptyMetric}>
                <View style={[styles.emptyMetricDot, { backgroundColor: Colors.accentDark }]} />
                <Text style={styles.emptyMetricText}>Expense ₹0</Text>
            </View>
        </View>
    </View>
);

const EmptyTransactionsState = () => (
    <Card style={styles.emptyListCard}>
        <View style={styles.emptyListIcon}>
            <Icon name="receipt-outline" size={28} color={Colors.textSubtle} />
        </View>
        <View style={styles.emptyListCopy}>
            <Text style={styles.emptyListTitle}>No transactions yet</Text>
            <Text style={styles.emptyListSubText}>New entries for this period will show here.</Text>
        </View>
    </Card>
);

const TxnRow: React.FC<{ txn: Txn; isFirst?: boolean }> = ({ txn, isFirst }) => {
    const isIncome = txn.type === 'income';
    const sign = isIncome ? '+' : '-';
    const amountColor = isIncome ? Colors.accentDark : Colors.negative;
    const label = txn.title || txn.category || 'Untitled';
    const icon = resolveCategoryIcon(txn.category, txn.type);

    return (
        <View style={[txnStyles.row, !isFirst && txnStyles.rowDivider]}>
            <IconBadge
                name={icon.name}
                color={icon.color}
                bg={`${icon.color}1A`}
                size={42}
                rounded="square"
                elevated={false}
            />
            <View style={txnStyles.middle}>
                <Text style={txnStyles.title} numberOfLines={1}>
                    {label}
                </Text>
                <Text style={txnStyles.date}>
                    {txn.date ? moment(txn.date).format('DD MMM YYYY') : ''}
                </Text>
            </View>
            <View style={txnStyles.right}>
                <Text style={[txnStyles.amount, { color: amountColor }]}>
                    {sign}₹{formatNumberWithCommas(Number(txn.amount || 0).toFixed(2))}
                </Text>
                <View style={txnStyles.chevronBox}>
                    <Icon name="chevron-forward" size={15} color={Colors.textSubtle} />
                </View>
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    scroll: {
        paddingHorizontal: space.xl,
        paddingTop: space.lg,
        paddingBottom: space['3xl'],
    },
    headerRow: {
        alignItems: 'center',
        paddingTop: space.md,
        paddingBottom: space.md,
        marginBottom: space.xl,
    },
    title: {
        ...Typography.screenTitle,
    },
    chartHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        alignSelf: 'stretch',
        zIndex: 5,
        elevation: 5,
    },
    chartHeaderMenuOpen: {
        zIndex: 10,
        elevation: 10,
    },
    rangeControl: {
        position: 'relative',
        zIndex: 2,
    },
    rangePill: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: space.md,
        paddingVertical: 6,
        backgroundColor: Colors.surface,
        borderWidth: 1,
        borderColor: Colors.border,
        borderRadius: radius.pill,
    },
    rangeMenu: {
        position: 'absolute',
        top: 42,
        left: 0,
        width: 164,
        paddingVertical: space.xs,
        backgroundColor: Colors.surface,
        borderWidth: 1,
        borderColor: Colors.border,
        borderRadius: radius.sm,
        ...Shadows.md,
        zIndex: 12,
        elevation: 12,
    },
    rangeOption: {
        paddingHorizontal: space.md,
        paddingVertical: space.sm,
    },
    rangeOptionActive: {
        backgroundColor: Colors.primarySoft,
    },
    rangeOptionText: {
        ...Typography.bodySm,
        fontFamily: Fonts.medium,
        color: Colors.textBody,
    },
    rangeOptionTextActive: {
        color: Colors.primary,
        fontFamily: Fonts.semibold,
    },
    rangeText: {
        ...Typography.bodySm,
        fontFamily: Fonts.medium,
        marginRight: 4,
        color: Colors.text,
    },
    donutLegendRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        alignSelf: 'center',
        marginTop: space.sm,
        marginLeft: -space.md,
    },
    txnList: {
        backgroundColor: Colors.surface,
        borderRadius: radius.md,
        paddingHorizontal: space.lg,
        ...Shadows.sm,
    },
    donutCard: {
        alignItems: 'center',
        marginBottom: space.md,
        paddingBottom: space.lg,
    },
    donutWrap: {
        minHeight: 230,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: space.lg,
        paddingTop: space.md,
        paddingBottom: space.sm,
        position: 'relative',
    },
    emptyChartState: {
        width: '100%',
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: space.sm,
    },
    emptyChartGraphic: {
        width: 104,
        height: 104,
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: space.md,
    },
    emptyRingOuter: {
        width: 92,
        height: 92,
        borderRadius: 46,
        borderWidth: 12,
        borderColor: Colors.primarySoft,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: Colors.surface,
    },
    emptyRingInner: {
        width: 52,
        height: 52,
        borderRadius: 26,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: Colors.primarySoft,
    },
    emptySpark: {
        position: 'absolute',
        width: 18,
        height: 18,
        borderRadius: 9,
        borderWidth: 4,
        borderColor: Colors.surface,
    },
    emptySparkIncome: {
        top: 10,
        right: 12,
        backgroundColor: Colors.primary,
    },
    emptySparkExpense: {
        left: 14,
        bottom: 14,
        backgroundColor: Colors.accentDark,
    },
    emptyTitle: {
        ...Typography.bodyStrong,
        textAlign: 'center',
    },
    emptySubText: {
        ...Typography.bodySm,
        maxWidth: 270,
        marginTop: space.xs,
        textAlign: 'center',
    },
    emptyMetricRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        flexWrap: 'wrap',
        marginTop: space.md,
    },
    emptyMetric: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: space.md,
        paddingVertical: 7,
        marginHorizontal: space.xs,
        marginBottom: space.xs,
        backgroundColor: Colors.surfaceSoft,
        borderRadius: radius.pill,
    },
    emptyMetricDot: {
        width: 8,
        height: 8,
        borderRadius: 4,
        marginRight: 6,
    },
    emptyMetricText: {
        ...Typography.caption,
        color: Colors.textBody,
    },
    emptyListCard: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: space.lg,
    },
    emptyListIcon: {
        width: 48,
        height: 48,
        borderRadius: radius.sm,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: space.md,
        backgroundColor: Colors.surfaceSoft,
    },
    emptyListCopy: {
        flex: 1,
        alignItems: 'flex-start',
    },
    emptyListTitle: {
        ...Typography.bodyStrong,
    },
    emptyListSubText: {
        ...Typography.bodySm,
        marginTop: 2,
    },
    donutTooltipOverlay: {
        position: 'absolute',
        left: 0,
        right: 0,
        bottom: space.sm,
        alignItems: 'center',
        zIndex: 10,
        elevation: 10,
    },
    donutTooltip: {
        width: 128,
        minHeight: 56,
        paddingHorizontal: space.sm,
        paddingVertical: 6,
        backgroundColor: Colors.text,
        borderRadius: radius.xs,
        alignItems: 'center',
        justifyContent: 'center',
        ...Shadows.md,
    },
    donutTooltipLabel: {
        ...Typography.caption,
        color: Colors.textInverse,
        fontFamily: Fonts.medium,
    },
    donutTooltipValue: {
        ...Typography.bodySm,
        color: Colors.textInverse,
        fontFamily: Fonts.semibold,
        marginTop: 2,
    },
    donutCenter: {
        alignItems: 'center',
    },
    donutCenterSmall: {
        ...Typography.caption,
    },
    donutCenterBig: {
        ...Typography.title,
    },
    bottomSpacer: {
        height: 104,
    },
});

const legendStyles = StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        marginLeft: space.md,
    },
    dot: {
        width: 8,
        height: 8,
        borderRadius: 4,
        marginRight: 4,
    },
    label: {
        ...Typography.caption,
    },
});

const txnStyles = StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: space.md,
    },
    rowDivider: {
        borderTopWidth: 1,
        borderTopColor: Colors.divider,
    },
    middle: {
        flex: 1,
        marginLeft: space.md,
    },
    title: {
        ...Typography.bodyStrong,
        marginBottom: 2,
    },
    date: {
        ...Typography.caption,
    },
    amount: {
        ...Typography.moneySm,
        marginLeft: space.sm,
    },
    right: {
        flexDirection: 'row',
        alignItems: 'center',
        marginLeft: space.sm,
    },
    chevronBox: {
        marginLeft: space.sm,
    },
});
