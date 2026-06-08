import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
    Modal,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    TextInput,
    View,
} from 'react-native';
import Svg, { Circle, Defs, LinearGradient, Stop } from 'react-native-svg';
import Icon from 'react-native-vector-icons/Ionicons';
import moment from 'moment';
import { useFocusEffect, useRouter } from 'expo-router';
import APIService from '@/src/ApiService/api.service';
import {
    Card,
    CircleIconButton,
    IconBadge,
    PillButton,
    ScreenContainer,
    SectionHeader,
    TextField,
} from '@/src/components/ui';
import {
    Fonts,
    Shadows,
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { usePreferences } from '@/src/context/PreferencesContext';
import { formatNumberWithCommas } from '@/src/utils/helper';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';
import {
    getTransactionDate,
    readTransactionList,
} from '@/src/utils/transactions';
import CustomDatePicker from '@/src/components/common/CustomDatePicker';
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
type TypeFilter = 'all' | 'expense' | 'income';

interface Filters {
    typeFilter: TypeFilter;
    category: string;
    minAmount: string;
    maxAmount: string;
    startDate: string;
    endDate: string;
}

const EMPTY_FILTERS: Filters = {
    typeFilter: 'all',
    category: '',
    minAmount: '',
    maxAmount: '',
    startDate: '',
    endDate: '',
};

const TYPE_FILTER_OPTIONS: { value: TypeFilter; label: string }[] = [
    { value: 'all', label: 'All' },
    { value: 'expense', label: 'Expense' },
    { value: 'income', label: 'Income' },
];

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
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();
    const [selectedRangeKey, setSelectedRangeKey] =
        useState<RangeKey>('thisMonth');
    const [rangeMenuOpen, setRangeMenuOpen] = useState(false);
    const [selectedCashflowKey, setSelectedCashflowKey] =
        useState<CashflowKey | null>(null);
    const [incomes, setIncomes] = useState<Txn[]>([]);
    const [expenses, setExpenses] = useState<Txn[]>([]);
    const [loading, setLoading] = useState(true);

    // Search + filters
    const [keyword, setKeyword] = useState('');
    const [appliedKeyword, setAppliedKeyword] = useState('');
    const [filters, setFilters] = useState<Filters>(EMPTY_FILTERS);
    const [draftFilters, setDraftFilters] = useState<Filters>(EMPTY_FILTERS);
    const [filtersOpen, setFiltersOpen] = useState(false);

    const hasActiveFilters = useMemo(
        () =>
            filters.typeFilter !== 'all' ||
            filters.category.trim() !== '' ||
            filters.minAmount.trim() !== '' ||
            filters.maxAmount.trim() !== '' ||
            filters.startDate !== '' ||
            filters.endDate !== '' ||
            appliedKeyword.trim() !== '',
        [filters, appliedKeyword],
    );

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
        // Explicit date filters override the quick range selector.
        const startDate = filters.startDate || rangeConfig.start.format('YYYY-MM-DD');
        const endDate = filters.endDate || rangeConfig.end.format('YYYY-MM-DD');

        const baseQuery: Record<string, string> = {
            start_date: startDate,
            end_date: endDate,
        };
        const trimmedKeyword = appliedKeyword.trim();
        if (trimmedKeyword) baseQuery.keyword = trimmedKeyword;
        const trimmedCategory = filters.category.trim();
        if (trimmedCategory) baseQuery.category = trimmedCategory;
        if (filters.minAmount.trim()) baseQuery.min_amount = filters.minAmount.trim();
        if (filters.maxAmount.trim()) baseQuery.max_amount = filters.maxAmount.trim();

        const wantIncomes = filters.typeFilter !== 'expense';
        const wantExpenses = filters.typeFilter !== 'income';

        setLoading(true);
        const [incomeResult, expenseResult] = await Promise.allSettled([
            wantIncomes ? api.getIncomes({ ...baseQuery }) : Promise.resolve(null),
            // NOTE: don't pass `type: 'expense'` — the Expense model's `type`
            // field defaults to 'self', so that filter would exclude every
            // normal expense. The get-expenses endpoint already returns only
            // expenses; wantExpenses controls whether we call it at all.
            wantExpenses
                ? api.getExpenses({ ...baseQuery })
                : Promise.resolve(null),
        ]);

        if (wantIncomes && incomeResult.status === 'fulfilled' && incomeResult.value) {
            const list = readTransactionList(incomeResult.value, 'incomes');
            setIncomes(list.map((t: Txn) => ({ ...t, type: 'income' })));
        } else {
            setIncomes([]);
        }

        if (wantExpenses && expenseResult.status === 'fulfilled' && expenseResult.value) {
            const list = readTransactionList(expenseResult.value, 'expenses');
            setExpenses(list.map((t: Txn) => ({ ...t, type: 'expense' })));
        } else {
            setExpenses([]);
        }

        setLoading(false);
    }, [rangeConfig, appliedKeyword, filters]);

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
                    color: colors.primary,
                    label: 'Income',
                },
                {
                    key: 'expense' as const,
                    value: totals.curExpense,
                    color: colors.accentDark,
                    label: 'Expense',
                },
            ].filter((item) => item.value > 0),
        [totals.curExpense, totals.curIncome, colors],
    );
    const incomeExpenseBalance = totals.curIncome - totals.curExpense;
    const selectedCashflowItem = selectedCashflowKey
        ? incomeExpenseTotals.find((item) => item.key === selectedCashflowKey)
        : null;
    const hasCashflow = incomeExpenseTotals.length > 0;

    useEffect(() => {
        setSelectedCashflowKey(null);
    }, [incomeExpenseTotals]);

    const submitSearch = useCallback(() => {
        setAppliedKeyword(keyword);
    }, [keyword]);

    const openFilters = useCallback(() => {
        setRangeMenuOpen(false);
        setDraftFilters(filters);
        setFiltersOpen(true);
    }, [filters]);

    const applyFilters = useCallback(() => {
        setFilters(draftFilters);
        setFiltersOpen(false);
    }, [draftFilters]);

    const clearFilters = useCallback(() => {
        setDraftFilters(EMPTY_FILTERS);
        setFilters(EMPTY_FILTERS);
        setKeyword('');
        setAppliedKeyword('');
        setFiltersOpen(false);
    }, []);

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

                <View
                    style={styles.searchRow}
                    onTouchStart={(event) => event.stopPropagation()}
                >
                    <View style={styles.searchField}>
                        <Icon
                            name="search"
                            size={18}
                            color={colors.textSubtle}
                            style={styles.searchIcon}
                        />
                        <TextInput
                            placeholder="Search transactions"
                            placeholderTextColor={colors.textSubtle}
                            value={keyword}
                            onChangeText={setKeyword}
                            onSubmitEditing={submitSearch}
                            returnKeyType="search"
                            style={styles.searchInput}
                        />
                        {keyword.length > 0 ? (
                            <Pressable
                                accessibilityRole="button"
                                hitSlop={8}
                                onPress={() => {
                                    setKeyword('');
                                    setAppliedKeyword('');
                                }}
                            >
                                <Icon
                                    name="close-circle"
                                    size={18}
                                    color={colors.textSubtle}
                                />
                            </Pressable>
                        ) : null}
                    </View>
                    <View>
                        <CircleIconButton
                            name="options-outline"
                            onPress={openFilters}
                        />
                        {hasActiveFilters ? (
                            <View style={styles.filterDot} />
                        ) : null}
                    </View>
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
                                            color={colors.text}
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

            <FiltersSheet
                visible={filtersOpen}
                draft={draftFilters}
                onChange={setDraftFilters}
                onApply={applyFilters}
                onClear={clearFilters}
                onClose={() => setFiltersOpen(false)}
                formatCurrency={formatCurrency}
            />
        </ScreenContainer>
    );
}

const FiltersSheet: React.FC<{
    visible: boolean;
    draft: Filters;
    onChange: (next: Filters) => void;
    onApply: () => void;
    onClear: () => void;
    onClose: () => void;
    formatCurrency: (value: number | string | null | undefined) => string;
}> = ({ visible, draft, onChange, onApply, onClear, onClose, formatCurrency }) => {
    const colors = useColors();
    const styles = useMemo(() => makeFilterStyles(colors), [colors]);

    const patch = (partial: Partial<Filters>) =>
        onChange({ ...draft, ...partial });

    const minNum = Number(draft.minAmount);
    const maxNum = Number(draft.maxAmount);
    const amountPreview =
        draft.minAmount.trim() && draft.maxAmount.trim()
            ? `${formatCurrency(minNum)} – ${formatCurrency(maxNum)}`
            : draft.minAmount.trim()
              ? `From ${formatCurrency(minNum)}`
              : draft.maxAmount.trim()
                ? `Up to ${formatCurrency(maxNum)}`
                : '';

    return (
        <Modal
            visible={visible}
            transparent
            animationType="slide"
            onRequestClose={onClose}
        >
            <Pressable style={styles.backdrop} onPress={onClose} />
            <View style={styles.sheet}>
                <View style={styles.sheetHandle} />
                <View style={styles.sheetHeader}>
                    <Text style={styles.sheetTitle}>Filters</Text>
                    <Pressable
                        accessibilityRole="button"
                        hitSlop={10}
                        onPress={onClose}
                    >
                        <Icon name="close" size={22} color={colors.textSubtle} />
                    </Pressable>
                </View>

                <ScrollView
                    showsVerticalScrollIndicator={false}
                    keyboardShouldPersistTaps="handled"
                    contentContainerStyle={styles.sheetBody}
                >
                    <Text style={styles.fieldLabel}>Type</Text>
                    <View style={styles.segment}>
                        {TYPE_FILTER_OPTIONS.map((opt) => {
                            const active = opt.value === draft.typeFilter;
                            return (
                                <Pressable
                                    key={opt.value}
                                    onPress={() => patch({ typeFilter: opt.value })}
                                    style={[
                                        styles.segmentItem,
                                        active && styles.segmentItemActive,
                                    ]}
                                >
                                    <Text
                                        style={[
                                            styles.segmentLabel,
                                            {
                                                color: active
                                                    ? colors.textInverse
                                                    : colors.textSubtle,
                                            },
                                        ]}
                                    >
                                        {opt.label}
                                    </Text>
                                </Pressable>
                            );
                        })}
                    </View>

                    <TextField
                        label="Category"
                        placeholder="e.g. Groceries"
                        value={draft.category}
                        onChangeText={(text) => patch({ category: text })}
                        autoCapitalize="words"
                        leftIconName="pricetag-outline"
                    />

                    <Text style={styles.fieldLabel}>Amount</Text>
                    <View style={styles.amountRow}>
                        <View style={styles.amountField}>
                            <TextField
                                placeholder="Min"
                                value={draft.minAmount}
                                onChangeText={(text) =>
                                    patch({ minAmount: text.replace(/[^0-9.]/g, '') })
                                }
                                keyboardType="numeric"
                            />
                        </View>
                        <View style={styles.amountField}>
                            <TextField
                                placeholder="Max"
                                value={draft.maxAmount}
                                onChangeText={(text) =>
                                    patch({ maxAmount: text.replace(/[^0-9.]/g, '') })
                                }
                                keyboardType="numeric"
                            />
                        </View>
                    </View>
                    {amountPreview ? (
                        <Text style={styles.amountPreview}>{amountPreview}</Text>
                    ) : null}

                    <Text style={styles.fieldLabel}>Date range</Text>
                    <View style={styles.dateRow}>
                        <View style={styles.dateField}>
                            <CustomDatePicker
                                value={draft.startDate}
                                placeholder="Start date"
                                onChange={(date) => patch({ startDate: date })}
                            />
                        </View>
                        <View style={styles.dateField}>
                            <CustomDatePicker
                                value={draft.endDate}
                                placeholder="End date"
                                onChange={(date) => patch({ endDate: date })}
                            />
                        </View>
                    </View>

                    <View style={styles.actionsRow}>
                        <View style={styles.actionItem}>
                            <PillButton
                                label="Clear"
                                variant="secondary"
                                onPress={onClear}
                            />
                        </View>
                        <View style={styles.actionItem}>
                            <PillButton label="Apply" onPress={onApply} />
                        </View>
                    </View>
                </ScrollView>
            </View>
        </Modal>
    );
};

const TransactionsSkeleton = () => {
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const txnStyles = useMemo(() => makeTxnStyles(colors), [colors]);
    const skeletonStyles = useMemo(() => makeSkeletonStyles(colors), [colors]);
    return (
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
};

const LegendSkeleton = () => {
    const colors = useColors();
    const legendStyles = useMemo(() => makeLegendStyles(colors), [colors]);
    const skeletonStyles = useMemo(() => makeSkeletonStyles(colors), [colors]);
    return (
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
};

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
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const maxValue = Math.max(income, expense, 1);
    const incomeArc = arcDash(88, income / maxValue);
    const expenseArc = arcDash(66, expense / maxValue);
    const safeBalance = Math.max(balance, 0);
    const savedPercent =
        income > 0 ? Math.round((safeBalance / income) * 100) : 0;
    const spentPercent =
        income > 0 ? Math.min(Math.round((expense / income) * 100), 999) : 0;
    const balanceIsNegative = balance < 0;
    const signalColor = balanceIsNegative ? colors.negative : colors.accentDark;
    const signalBg = balanceIsNegative
        ? colors.negativeSoft
        : colors.accentSoft;
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
                                stopColor={colors.primaryGradientStart}
                            />
                            <Stop offset="1" stopColor={colors.primaryDarker} />
                        </LinearGradient>
                        <LinearGradient
                            id="expenseArcGradient"
                            x1="0"
                            y1="0"
                            x2="1"
                            y2="1"
                        >
                            <Stop offset="0" stopColor={colors.accent} />
                            <Stop offset="1" stopColor={colors.accentDark} />
                        </LinearGradient>
                    </Defs>
                    <Circle
                        cx={ARC_CENTER}
                        cy={ARC_CENTER}
                        r={88}
                        fill="transparent"
                        stroke={colors.primarySoft}
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
                        stroke={colors.accentSoft}
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
                    color={colors.primary}
                    active={selectedKey === 'income'}
                    onPress={onSelect}
                />
                <CashflowMetric
                    keyName="expense"
                    icon="arrow-up"
                    label="Expense"
                    value={expense}
                    color={colors.accentDark}
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
}> = ({ keyName, icon, label, value, color, active, caption, onPress }) => {
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    return (
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
};

const EmptyDonutState: React.FC<{ rangeLabel: string }> = ({ rangeLabel }) => {
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    return (
        <View style={styles.emptyChartState}>
            <View style={styles.emptyChartGraphic}>
                <View style={styles.emptyRingOuter}>
                    <View style={styles.emptyRingInner}>
                        <Icon
                            name="pie-chart-outline"
                            size={28}
                            color={colors.primary}
                        />
                    </View>
                </View>
                <View style={[styles.emptySpark, styles.emptySparkIncome]} />
                <View style={[styles.emptySpark, styles.emptySparkExpense]} />
            </View>
            <Text style={styles.emptyTitle}>Nothing to chart yet</Text>
            <Text style={styles.emptySubText}>
                Add income or expenses for {rangeLabel} and your balance
                breakdown will appear here.
            </Text>
            <View style={styles.emptyMetricRow}>
                <View style={styles.emptyMetric}>
                    <View
                        style={[
                            styles.emptyMetricDot,
                            { backgroundColor: colors.primary },
                        ]}
                    />
                    <Text style={styles.emptyMetricText}>Income ₹0</Text>
                </View>
                <View style={styles.emptyMetric}>
                    <View
                        style={[
                            styles.emptyMetricDot,
                            { backgroundColor: colors.accentDark },
                        ]}
                    />
                    <Text style={styles.emptyMetricText}>Expense ₹0</Text>
                </View>
            </View>
        </View>
    );
};

const EmptyTransactionsState = () => {
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    return (
        <Card style={styles.emptyListCard}>
            <View style={styles.emptyListIcon}>
                <Icon
                    name="receipt-outline"
                    size={28}
                    color={colors.textSubtle}
                />
            </View>
            <View style={styles.emptyListCopy}>
                <Text style={styles.emptyListTitle}>No transactions yet</Text>
                <Text style={styles.emptyListSubText}>
                    New entries for this period will show here.
                </Text>
            </View>
        </Card>
    );
};

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
    const colors = useColors();
    const txnStyles = useMemo(() => makeTxnStyles(colors), [colors]);
    const isIncome = txn.type === 'income';
    const sign = isIncome ? '+' : '-';
    const amountColor = isIncome ? colors.accentDark : colors.negative;
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
                        color={colors.textSubtle}
                    />
                </View>
            </View>
        </Pressable>
    );
};

const makeStyles = (colors: ColorPalette) => StyleSheet.create({
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
        color: colors.text,
    },
    searchRow: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: space.lg,
        gap: space.sm,
    },
    searchField: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: colors.surface,
        borderWidth: 1,
        borderColor: colors.border,
        borderRadius: radius.pill,
        paddingHorizontal: space.md,
        height: 44,
        ...Shadows.sm,
    },
    searchIcon: {
        marginRight: space.sm,
    },
    searchInput: {
        flex: 1,
        ...Typography.bodySm,
        color: colors.text,
        paddingVertical: 0,
    },
    filterDot: {
        position: 'absolute',
        top: 0,
        right: 0,
        width: 12,
        height: 12,
        borderRadius: 6,
        backgroundColor: colors.primary,
        borderWidth: 2,
        borderColor: colors.background,
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
        backgroundColor: colors.surface,
        borderWidth: 1,
        borderColor: colors.border,
        borderRadius: radius.pill,
    },
    rangeMenu: {
        position: 'absolute',
        top: 42,
        left: 0,
        width: 164,
        paddingVertical: space.xs,
        backgroundColor: colors.surface,
        borderWidth: 1,
        borderColor: colors.border,
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
        backgroundColor: colors.primarySoft,
    },
    rangeOptionText: {
        ...Typography.bodySm,
        fontFamily: Fonts.medium,
        color: colors.textBody,
    },
    rangeOptionTextActive: {
        color: colors.primary,
        fontFamily: Fonts.semibold,
    },
    rangeText: {
        ...Typography.bodySm,
        fontFamily: Fonts.medium,
        marginRight: 4,
        color: colors.text,
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
        backgroundColor: colors.surface,
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
        backgroundColor: colors.surface,
    },
    arcCenterLabel: {
        ...Typography.caption,
        fontFamily: Fonts.semibold,
        color: colors.textSubtle,
    },
    arcCenterValue: {
        ...Typography.title,
        marginTop: 2,
        color: colors.text,
        maxWidth: 124,
    },
    arcCenterValueNegative: {
        color: colors.negative,
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
        backgroundColor: colors.text,
        borderRadius: radius.xs,
        ...Shadows.md,
    },
    cashflowTooltipLabel: {
        ...Typography.caption,
        color: colors.surface,
        fontFamily: Fonts.medium,
    },
    cashflowTooltipValue: {
        ...Typography.bodySm,
        color: colors.surface,
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
        backgroundColor: colors.surfaceSoft,
        borderWidth: 1,
        borderColor: colors.border,
        borderRadius: radius.sm,
    },
    flowMetricActive: {
        backgroundColor: colors.primarySoft,
        borderColor: colors.primarySoftStrong,
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
        color: colors.textSubtle,
    },
    flowMetricValue: {
        ...Typography.bodyStrong,
        marginTop: 1,
        color: colors.text,
    },
    flowMetricCaption: {
        ...Typography.caption,
        marginTop: 1,
        color: colors.textSubtle,
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
        borderColor: colors.primarySoft,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: colors.surface,
    },
    emptyRingInner: {
        width: 52,
        height: 52,
        borderRadius: 26,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: colors.primarySoft,
    },
    emptySpark: {
        position: 'absolute',
        width: 18,
        height: 18,
        borderRadius: 9,
        borderWidth: 4,
        borderColor: colors.surface,
    },
    emptySparkIncome: {
        top: 10,
        right: 12,
        backgroundColor: colors.primary,
    },
    emptySparkExpense: {
        left: 14,
        bottom: 14,
        backgroundColor: colors.accentDark,
    },
    emptyTitle: {
        ...Typography.bodyStrong,
        textAlign: 'center',
        color: colors.text,
    },
    emptySubText: {
        ...Typography.bodySm,
        maxWidth: 270,
        marginTop: space.xs,
        textAlign: 'center',
        color: colors.textSubtle,
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
        backgroundColor: colors.surfaceSoft,
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
        color: colors.textBody,
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
        backgroundColor: colors.surfaceSoft,
    },
    emptyListCopy: {
        flex: 1,
        alignItems: 'flex-start',
    },
    emptyListTitle: {
        ...Typography.bodyStrong,
        color: colors.text,
    },
    emptyListSubText: {
        ...Typography.bodySm,
        marginTop: 2,
        color: colors.textSubtle,
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
        backgroundColor: colors.text,
        borderRadius: radius.xs,
        alignItems: 'center',
        justifyContent: 'center',
        ...Shadows.md,
    },
    donutTooltipLabel: {
        ...Typography.caption,
        color: colors.surface,
        fontFamily: Fonts.medium,
    },
    donutTooltipValue: {
        ...Typography.bodySm,
        color: colors.surface,
        fontFamily: Fonts.semibold,
        marginTop: 2,
    },
    donutCenter: {
        alignItems: 'center',
    },
    donutCenterSmall: {
        ...Typography.caption,
        color: colors.textSubtle,
    },
    donutCenterBig: {
        ...Typography.title,
        color: colors.text,
    },
    bottomSpacer: {
        height: 104,
    },
});

const makeLegendStyles = (colors: ColorPalette) => StyleSheet.create({
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
        color: colors.textSubtle,
    },
});

const makeTxnStyles = (colors: ColorPalette) => StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: space.md,
    },
    rowDivider: {
        borderTopWidth: 1,
        borderTopColor: colors.divider,
    },
    middle: {
        flex: 1,
        marginLeft: space.md,
    },
    title: {
        ...Typography.bodyStrong,
        marginBottom: 2,
        color: colors.text,
    },
    date: {
        ...Typography.caption,
        color: colors.textSubtle,
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

const makeSkeletonStyles = (colors: ColorPalette) => StyleSheet.create({
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
        backgroundColor: colors.surface,
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

const makeFilterStyles = (colors: ColorPalette) => StyleSheet.create({
    backdrop: {
        flex: 1,
        backgroundColor: colors.overlay,
    },
    sheet: {
        backgroundColor: colors.background,
        borderTopLeftRadius: radius.lg,
        borderTopRightRadius: radius.lg,
        paddingHorizontal: space.xl,
        paddingTop: space.sm,
        paddingBottom: space.xl,
        maxHeight: '88%',
    },
    sheetHandle: {
        alignSelf: 'center',
        width: 40,
        height: 4,
        borderRadius: 2,
        backgroundColor: colors.borderStrong,
        marginBottom: space.md,
    },
    sheetHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: space.md,
    },
    sheetTitle: {
        ...Typography.subtitle,
        color: colors.text,
    },
    sheetBody: {
        paddingBottom: space.lg,
    },
    fieldLabel: {
        ...Typography.label,
        color: colors.textSubtle,
        marginBottom: space.sm,
    },
    segment: {
        flexDirection: 'row',
        backgroundColor: colors.surfaceMuted,
        borderRadius: radius.sm,
        padding: 4,
        gap: 4,
        marginBottom: space.lg,
    },
    segmentItem: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        paddingVertical: 10,
        borderRadius: radius.xs,
    },
    segmentItemActive: {
        backgroundColor: colors.primary,
    },
    segmentLabel: {
        ...Typography.bodySm,
        fontFamily: Fonts.medium,
    },
    amountRow: {
        flexDirection: 'row',
        gap: space.md,
    },
    amountField: {
        flex: 1,
    },
    amountPreview: {
        ...Typography.caption,
        color: colors.textSubtle,
        marginTop: -space.sm,
        marginBottom: space.lg,
    },
    dateRow: {
        flexDirection: 'row',
        gap: space.md,
    },
    dateField: {
        flex: 1,
    },
    actionsRow: {
        flexDirection: 'row',
        gap: space.md,
        marginTop: space.md,
    },
    actionItem: {
        flex: 1,
    },
});
