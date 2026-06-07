import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import Svg, { Circle, Defs, LinearGradient, Stop } from 'react-native-svg';
import Icon from 'react-native-vector-icons/Ionicons';
import moment from 'moment';
import { useFocusEffect, useRouter } from 'expo-router';
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
import {
    getTransactionDate,
    readTransactionList,
} from '@/src/utils/transactions';
import SkeletonBlock from '@/src/components/skeletons/SkeletonBlock';

const api = new APIService();

interface Txn {
    _id?: string;
    type?: 'income' | 'expense' | string;
    title?: string;
    category?: string;
    sub_category?: string;
    date?: string;
    createdAt?: string;
    updatedAt?: string;
    description?: string;
    amount?: number;
}

type RangeKey =
    | 'today'
    | 'yesterday'
    | 'last3Days'
    | 'thisWeek'
    | 'thisMonth'
    | 'thisYear';
type CashflowKey = 'income' | 'expense';

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

const getTxnSortTime = (txn: Txn) => {
    const timestamp = moment(getTransactionDate(txn)).valueOf();
    return Number.isFinite(timestamp) ? timestamp : 0;
};

export default function TransactionsScreen() {
    const router = useRouter();
    const [selectedRangeKey, setSelectedRangeKey] =
        useState<RangeKey>('thisMonth');
    const [rangeMenuOpen, setRangeMenuOpen] = useState(false);
    const [selectedCashflowKey, setSelectedCashflowKey] =
        useState<CashflowKey | null>(null);
    const [incomes, setIncomes] = useState<Txn[]>([]);
    const [expenses, setExpenses] = useState<Txn[]>([]);
    const [loading, setLoading] = useState(true);

    const selectedRange = useMemo(
        () =>
            RANGE_OPTIONS.find((option) => option.key === selectedRangeKey) ||
            RANGE_OPTIONS[5],
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
    const rangeConfig = useMemo(
        () => buildDateRange(selectedRangeKey),
        [selectedRangeKey],
    );

    const load = useCallback(async () => {
        const currentRange = {
            start_date: rangeConfig.start.format('YYYY-MM-DD'),
            end_date: rangeConfig.end.format('YYYY-MM-DD'),
        };

        setLoading(true);
        const [incomeResult, expenseResult] = await Promise.allSettled([
            api.getIncomes(currentRange),
            api.getExpenses(currentRange),
        ]);

        if (incomeResult.status === 'fulfilled') {
            const list = readTransactionList(incomeResult.value, 'incomes');
            setIncomes(list.map((t: Txn) => ({ ...t, type: 'income' })));
        } else {
            setIncomes([]);
        }

        if (expenseResult.status === 'fulfilled') {
            const list = readTransactionList(expenseResult.value, 'expenses');
            setExpenses(list.map((t: Txn) => ({ ...t, type: 'expense' })));
        } else {
            setExpenses([]);
        }

        setLoading(false);
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
        const sum = (list: Txn[]) =>
            list.reduce((a, b) => a + Number(b.amount || 0), 0);
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
        () =>
            [
                {
                    key: 'income' as const,
                    value: totals.curIncome,
                    color: Colors.primary,
                    label: 'Income',
                },
                {
                    key: 'expense' as const,
                    value: totals.curExpense,
                    color: Colors.accentDark,
                    label: 'Expense',
                },
            ].filter((item) => item.value > 0),
        [totals.curExpense, totals.curIncome],
    );
    const incomeExpenseBalance = totals.curIncome - totals.curExpense;
    const selectedCashflowItem = selectedCashflowKey
        ? incomeExpenseTotals.find((item) => item.key === selectedCashflowKey)
        : null;
    const hasCashflow = incomeExpenseTotals.length > 0;

    useEffect(() => {
        setSelectedCashflowKey(null);
    }, [incomeExpenseTotals]);

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
                onTouchStart={() => {
                    if (rangeMenuOpen) setRangeMenuOpen(false);
                    setSelectedCashflowKey(null);
                }}
            >
                <View style={styles.headerRow}>
                    <Text style={styles.title}>Transactions</Text>
                </View>

                {loading ? (
                    <TransactionsSkeleton />
                ) : (
                    <>
                        <Card style={styles.donutCard}>
                            <View
                                style={[
                                    styles.chartHeader,
                                    rangeMenuOpen && styles.chartHeaderMenuOpen,
                                ]}
                            >
                                <View
                                    style={styles.rangeControl}
                                    onTouchStart={(event) =>
                                        event.stopPropagation()
                                    }
                                >
                                    <Pressable
                                        accessibilityRole="button"
                                        onPress={() =>
                                            setRangeMenuOpen((open) => !open)
                                        }
                                        style={styles.rangePill}
                                    >
                                        <Text style={styles.rangeText}>
                                            {selectedRange.label}
                                        </Text>
                                        <Icon
                                            name={
                                                rangeMenuOpen
                                                    ? 'chevron-up'
                                                    : 'chevron-down'
                                            }
                                            size={14}
                                            color={Colors.text}
                                        />
                                    </Pressable>
                                    {rangeMenuOpen ? (
                                        <View style={styles.rangeMenu}>
                                            {RANGE_OPTIONS.map((option) => {
                                                const active =
                                                    option.key ===
                                                    selectedRangeKey;
                                                return (
                                                    <Pressable
                                                        key={option.key}
                                                        accessibilityRole="button"
                                                        onPress={() => {
                                                            setSelectedRangeKey(
                                                                option.key,
                                                            );
                                                            setRangeMenuOpen(
                                                                false,
                                                            );
                                                        }}
                                                        style={[
                                                            styles.rangeOption,
                                                            active &&
                                                                styles.rangeOptionActive,
                                                        ]}
                                                    >
                                                        <Text
                                                            style={[
                                                                styles.rangeOptionText,
                                                                active &&
                                                                    styles.rangeOptionTextActive,
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
                                {hasCashflow ? (
                                    <CashflowArcMeter
                                        income={totals.curIncome}
                                        expense={totals.curExpense}
                                        balance={incomeExpenseBalance}
                                        selectedKey={selectedCashflowKey}
                                        selectedItem={selectedCashflowItem}
                                        onSelect={(key) => {
                                            setRangeMenuOpen(false);
                                            setSelectedCashflowKey((current) =>
                                                current === key ? null : key,
                                            );
                                        }}
                                    />
                                ) : (
                                    <EmptyDonutState
                                        rangeLabel={emptyRangeLabel}
                                    />
                                )}
                            </View>
                        </Card>

                        <SectionHeader title={sectionTitle} />

                        {all.length === 0 ? (
                            <EmptyTransactionsState />
                        ) : (
                            <View style={styles.txnList}>
                                {all.map((t, idx) => (
                                    <TxnRow
                                        key={t._id || idx}
                                        txn={t}
                                        isFirst={idx === 0}
                                        onPress={() =>
                                            router.push({
                                                pathname: '/transaction-detail',
                                                params: getTransactionRouteParams(t),
                                            })
                                        }
                                    />
                                ))}
                            </View>
                        )}

                        <View style={styles.bottomSpacer} />
                    </>
                )}
            </ScrollView>
        </ScreenContainer>
    );
}

const TransactionsSkeleton = () => (
    <>
        <Card style={styles.donutCard}>
            <View style={styles.chartHeader}>
                <SkeletonBlock width={96} height={32} radius={16} />
            </View>
            <View style={styles.donutWrap}>
                <SkeletonBlock width={172} height={172} radius={86} />
                <View style={skeletonStyles.donutHole}>
                    <SkeletonBlock
                        width={66}
                        height={12}
                        radius={6}
                        style={skeletonStyles.centered}
                    />
                    <SkeletonBlock
                        width={92}
                        height={22}
                        radius={11}
                        style={skeletonStyles.donutCenterValue}
                    />
                </View>
            </View>
            <View style={styles.donutLegendRow}>
                <LegendSkeleton />
                <LegendSkeleton />
            </View>
        </Card>

        <View style={skeletonStyles.sectionHeader}>
            <SkeletonBlock width={214} height={20} radius={10} />
        </View>

        <View style={styles.txnList}>
            {Array.from({ length: 6 }).map((_, index) => (
                <View
                    key={index}
                    style={[txnStyles.row, index > 0 && txnStyles.rowDivider]}
                >
                    <SkeletonBlock width={42} height={42} radius={10} />
                    <View style={txnStyles.middle}>
                        <SkeletonBlock
                            width={index % 2 ? 148 : 108}
                            height={17}
                            radius={8}
                        />
                        <SkeletonBlock
                            width={86}
                            height={13}
                            radius={6}
                            style={skeletonStyles.txnSubline}
                        />
                    </View>
                    <View style={txnStyles.right}>
                        <SkeletonBlock width={82} height={17} radius={8} />
                        <SkeletonBlock
                            width={15}
                            height={15}
                            radius={8}
                            style={skeletonStyles.chevron}
                        />
                    </View>
                </View>
            ))}
        </View>

        <View style={styles.bottomSpacer} />
    </>
);

const LegendSkeleton = () => (
    <View style={legendStyles.row}>
        <SkeletonBlock width={8} height={8} radius={4} />
        <SkeletonBlock
            width={52}
            height={12}
            radius={6}
            style={skeletonStyles.legendLabel}
        />
    </View>
);

const ARC_SIZE = 214;
const ARC_CENTER = ARC_SIZE / 2;
const METER_SWEEP = 0.76;
const METER_ROTATION = 132;

const arcDash = (radiusValue: number, progress: number) => {
    const circumference = 2 * Math.PI * radiusValue;
    const visibleProgress = Math.min(Math.max(progress, 0), 1) * METER_SWEEP;

    return {
        circumference,
        dash: `${visibleProgress * circumference} ${circumference}`,
    };
};

const CashflowArcMeter: React.FC<{
    income: number;
    expense: number;
    balance: number;
    selectedKey: CashflowKey | null;
    selectedItem?: { label: string; value: number } | null;
    onSelect: (key: CashflowKey) => void;
}> = ({ income, expense, balance, selectedKey, selectedItem, onSelect }) => {
    const maxValue = Math.max(income, expense, 1);
    const incomeArc = arcDash(88, income / maxValue);
    const expenseArc = arcDash(66, expense / maxValue);
    const safeBalance = Math.max(balance, 0);
    const savedPercent =
        income > 0 ? Math.round((safeBalance / income) * 100) : 0;
    const spentPercent =
        income > 0 ? Math.min(Math.round((expense / income) * 100), 999) : 0;
    const balanceIsNegative = balance < 0;
    const signalColor = balanceIsNegative ? Colors.negative : Colors.accentDark;
    const signalBg = balanceIsNegative
        ? Colors.negativeSoft
        : Colors.accentSoft;
    const signalLabel = balanceIsNegative ? 'Over by' : 'Saved';
    const signalValue = balanceIsNegative
        ? `₹${formatNumberWithCommas(Math.abs(balance).toFixed(0))}`
        : `${savedPercent}%`;
    const balanceAmount = formatNumberWithCommas(Math.abs(balance).toFixed(0));

    return (
        <View style={styles.cashflowMeter}>
            <View style={styles.arcStage}>
                <Svg
                    width={ARC_SIZE}
                    height={ARC_SIZE}
                    viewBox={`0 0 ${ARC_SIZE} ${ARC_SIZE}`}
                >
                    <Defs>
                        <LinearGradient
                            id="incomeArcGradient"
                            x1="0"
                            y1="0"
                            x2="1"
                            y2="1"
                        >
                            <Stop
                                offset="0"
                                stopColor={Colors.primaryGradientStart}
                            />
                            <Stop offset="1" stopColor={Colors.primaryDarker} />
                        </LinearGradient>
                        <LinearGradient
                            id="expenseArcGradient"
                            x1="0"
                            y1="0"
                            x2="1"
                            y2="1"
                        >
                            <Stop offset="0" stopColor={Colors.accent} />
                            <Stop offset="1" stopColor={Colors.accentDark} />
                        </LinearGradient>
                    </Defs>
                    <Circle
                        cx={ARC_CENTER}
                        cy={ARC_CENTER}
                        r={88}
                        fill="transparent"
                        stroke={Colors.primarySoft}
                        strokeWidth={18}
                        strokeLinecap="round"
                        strokeDasharray={arcDash(88, 1).dash}
                        transform={`rotate(${METER_ROTATION} ${ARC_CENTER} ${ARC_CENTER})`}
                    />
                    <Circle
                        cx={ARC_CENTER}
                        cy={ARC_CENTER}
                        r={66}
                        fill="transparent"
                        stroke={Colors.accentSoft}
                        strokeWidth={16}
                        strokeLinecap="round"
                        strokeDasharray={arcDash(66, 1).dash}
                        transform={`rotate(${METER_ROTATION} ${ARC_CENTER} ${ARC_CENTER})`}
                    />
                    <Circle
                        cx={ARC_CENTER}
                        cy={ARC_CENTER}
                        r={88}
                        fill="transparent"
                        stroke="url(#incomeArcGradient)"
                        strokeWidth={18}
                        strokeLinecap="round"
                        strokeDasharray={incomeArc.dash}
                        strokeDashoffset={0}
                        transform={`rotate(${METER_ROTATION} ${ARC_CENTER} ${ARC_CENTER})`}
                        opacity={selectedKey === 'expense' ? 0.48 : 1}
                        onPress={() => onSelect('income')}
                    />
                    <Circle
                        cx={ARC_CENTER}
                        cy={ARC_CENTER}
                        r={66}
                        fill="transparent"
                        stroke="url(#expenseArcGradient)"
                        strokeWidth={16}
                        strokeLinecap="round"
                        strokeDasharray={expenseArc.dash}
                        strokeDashoffset={0}
                        transform={`rotate(${METER_ROTATION} ${ARC_CENTER} ${ARC_CENTER})`}
                        opacity={selectedKey === 'income' ? 0.48 : 1}
                        onPress={() => onSelect('expense')}
                    />
                </Svg>
                <View pointerEvents="none" style={styles.arcCenter}>
                    <Text style={styles.arcCenterLabel}>Balance</Text>
                    <Text
                        style={[
                            styles.arcCenterValue,
                            balanceIsNegative && styles.arcCenterValueNegative,
                        ]}
                        numberOfLines={1}
                        adjustsFontSizeToFit
                    >
                        {balanceIsNegative ? '-' : ''}₹{balanceAmount}
                    </Text>
                    <View
                        style={[
                            styles.arcSignal,
                            { backgroundColor: signalBg },
                        ]}
                    >
                        <Text
                            style={[
                                styles.arcSignalText,
                                { color: signalColor },
                            ]}
                        >
                            {signalLabel} {signalValue}
                        </Text>
                    </View>
                </View>
            </View>

            {selectedItem ? (
                <View pointerEvents="none" style={styles.cashflowTooltip}>
                    <Text style={styles.cashflowTooltipLabel}>
                        {selectedItem.label}
                    </Text>
                    <Text style={styles.cashflowTooltipValue}>
                        ₹{formatNumberWithCommas(selectedItem.value.toFixed(0))}
                    </Text>
                </View>
            ) : null}

            <View style={styles.flowMetricRow}>
                <CashflowMetric
                    keyName="income"
                    icon="arrow-down"
                    label="Income"
                    value={income}
                    color={Colors.primary}
                    active={selectedKey === 'income'}
                    onPress={onSelect}
                />
                <CashflowMetric
                    keyName="expense"
                    icon="arrow-up"
                    label="Expense"
                    value={expense}
                    color={Colors.accentDark}
                    active={selectedKey === 'expense'}
                    caption={`${spentPercent}% spent`}
                    onPress={onSelect}
                />
            </View>
        </View>
    );
};

const CashflowMetric: React.FC<{
    keyName: CashflowKey;
    icon: string;
    label: string;
    value: number;
    color: string;
    active: boolean;
    caption?: string;
    onPress: (key: CashflowKey) => void;
}> = ({ keyName, icon, label, value, color, active, caption, onPress }) => (
    <Pressable
        accessibilityRole="button"
        onPress={() => onPress(keyName)}
        style={[
            styles.flowMetric,
            keyName === 'expense' && styles.flowMetricOffset,
            active && styles.flowMetricActive,
        ]}
    >
        <View
            style={[styles.flowMetricIcon, { backgroundColor: `${color}1A` }]}
        >
            <Icon name={icon} size={14} color={color} />
        </View>
        <View style={styles.flowMetricCopy}>
            <Text style={styles.flowMetricLabel}>{label}</Text>
            <Text
                style={styles.flowMetricValue}
                numberOfLines={1}
                adjustsFontSizeToFit
            >
                ₹{formatNumberWithCommas(value.toFixed(0))}
            </Text>
            {caption ? (
                <Text style={styles.flowMetricCaption}>{caption}</Text>
            ) : null}
        </View>
    </Pressable>
);

const EmptyDonutState: React.FC<{ rangeLabel: string }> = ({ rangeLabel }) => (
    <View style={styles.emptyChartState}>
        <View style={styles.emptyChartGraphic}>
            <View style={styles.emptyRingOuter}>
                <View style={styles.emptyRingInner}>
                    <Icon
                        name="pie-chart-outline"
                        size={28}
                        color={Colors.primary}
                    />
                </View>
            </View>
            <View style={[styles.emptySpark, styles.emptySparkIncome]} />
            <View style={[styles.emptySpark, styles.emptySparkExpense]} />
        </View>
        <Text style={styles.emptyTitle}>Nothing to chart yet</Text>
        <Text style={styles.emptySubText}>
            Add income or expenses for {rangeLabel} and your balance breakdown
            will appear here.
        </Text>
        <View style={styles.emptyMetricRow}>
            <View style={styles.emptyMetric}>
                <View
                    style={[
                        styles.emptyMetricDot,
                        { backgroundColor: Colors.primary },
                    ]}
                />
                <Text style={styles.emptyMetricText}>Income ₹0</Text>
            </View>
            <View style={styles.emptyMetric}>
                <View
                    style={[
                        styles.emptyMetricDot,
                        { backgroundColor: Colors.accentDark },
                    ]}
                />
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
            <Text style={styles.emptyListSubText}>
                New entries for this period will show here.
            </Text>
        </View>
    </Card>
);

const getTransactionKind = (txn: Txn) =>
    txn.type === 'income' ? 'income' : 'expense';

const getTransactionRouteParams = (txn: Txn) => {
    const transactionType = getTransactionKind(txn);

    return {
        id: txn._id || '',
        transactionType,
        title: txn.title || '',
        category: txn.category || '',
        subCategory: txn.sub_category || '',
        expenseType:
            transactionType === 'expense' && txn.type !== 'expense'
                ? txn.type || 'self'
                : 'self',
        date: txn.date || '',
        description: txn.description || '',
        amount: String(txn.amount || 0),
        createdAt: txn.createdAt || '',
        updatedAt: txn.updatedAt || '',
    };
};

const TxnRow: React.FC<{
    txn: Txn;
    isFirst?: boolean;
    onPress?: () => void;
}> = ({
    txn,
    isFirst,
    onPress,
}) => {
    const isIncome = txn.type === 'income';
    const sign = isIncome ? '+' : '-';
    const amountColor = isIncome ? Colors.accentDark : Colors.negative;
    const label = txn.title || txn.category || 'Untitled';
    const icon = resolveCategoryIcon(txn.category, isIncome ? 'income' : 'expense');

    return (
        <Pressable
            accessibilityRole="button"
            onPress={onPress}
            style={[
                txnStyles.row,
                !isFirst && txnStyles.rowDivider,
            ]}
        >
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
                    {sign}₹
                    {formatNumberWithCommas(Number(txn.amount || 0).toFixed(2))}
                </Text>
                <View style={txnStyles.chevronBox}>
                    <Icon
                        name="chevron-forward"
                        size={15}
                        color={Colors.textSubtle}
                    />
                </View>
            </View>
        </Pressable>
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
        minHeight: 314,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: space.lg,
        paddingTop: space.sm,
        paddingBottom: 0,
        position: 'relative',
    },
    cashflowMeter: {
        width: '100%',
        alignItems: 'center',
    },
    arcStage: {
        width: ARC_SIZE,
        height: ARC_SIZE,
        alignItems: 'center',
        justifyContent: 'center',
    },
    arcCenter: {
        position: 'absolute',
        width: 128,
        minHeight: 92,
        borderRadius: 64,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: space.sm,
        backgroundColor: Colors.surface,
    },
    arcCenterLabel: {
        ...Typography.caption,
        fontFamily: Fonts.semibold,
        color: Colors.textSubtle,
    },
    arcCenterValue: {
        ...Typography.title,
        marginTop: 2,
        color: Colors.text,
        maxWidth: 124,
    },
    arcCenterValueNegative: {
        color: Colors.negative,
    },
    arcSignal: {
        minHeight: 24,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: space.sm,
        marginTop: 8,
        borderRadius: radius.pill,
    },
    arcSignalText: {
        ...Typography.caption,
        fontFamily: Fonts.semibold,
    },
    cashflowTooltip: {
        minWidth: 132,
        minHeight: 54,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: space.md,
        paddingVertical: 6,
        marginTop: -space.sm,
        marginBottom: space.sm,
        backgroundColor: Colors.text,
        borderRadius: radius.xs,
        ...Shadows.md,
    },
    cashflowTooltipLabel: {
        ...Typography.caption,
        color: Colors.textInverse,
        fontFamily: Fonts.medium,
    },
    cashflowTooltipValue: {
        ...Typography.bodySm,
        color: Colors.textInverse,
        fontFamily: Fonts.semibold,
        marginTop: 2,
    },
    flowMetricRow: {
        width: '100%',
        flexDirection: 'row',
        alignItems: 'stretch',
        justifyContent: 'space-between',
        marginTop: space.sm,
    },
    flowMetric: {
        flex: 1,
        minHeight: 76,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: space.sm,
        paddingVertical: space.sm,
        backgroundColor: Colors.surfaceSoft,
        borderWidth: 1,
        borderColor: Colors.border,
        borderRadius: radius.sm,
    },
    flowMetricActive: {
        backgroundColor: Colors.primarySoft,
        borderColor: Colors.primarySoftStrong,
    },
    flowMetricOffset: {
        marginLeft: space.sm,
    },
    flowMetricIcon: {
        width: 30,
        height: 30,
        borderRadius: 15,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: space.sm,
    },
    flowMetricCopy: {
        flex: 1,
        minWidth: 0,
    },
    flowMetricLabel: {
        ...Typography.caption,
        fontFamily: Fonts.semibold,
        color: Colors.textSubtle,
    },
    flowMetricValue: {
        ...Typography.bodyStrong,
        marginTop: 1,
    },
    flowMetricCaption: {
        ...Typography.caption,
        marginTop: 1,
        color: Colors.textSubtle,
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

const skeletonStyles = StyleSheet.create({
    centered: {
        alignSelf: 'center',
    },
    donutHole: {
        position: 'absolute',
        width: 124,
        height: 124,
        borderRadius: 62,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: Colors.surface,
    },
    donutCenterValue: {
        alignSelf: 'center',
        marginTop: 8,
    },
    sectionHeader: {
        marginTop: space.sm,
        marginBottom: space.sm,
    },
    txnSubline: {
        marginTop: 6,
    },
    chevron: {
        marginLeft: space.sm,
    },
    legendLabel: {
        marginLeft: 4,
    },
});
