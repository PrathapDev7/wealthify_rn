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
import Toast from 'react-native-toast-message';
import moment from 'moment';
import * as FileSystem from 'expo-file-system/legacy';
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import { Card, CircleIconButton, PillButton, ScreenContainer } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { usePreferences } from '@/src/context/PreferencesContext';
import CustomDatePicker from '@/src/components/common/CustomDatePicker';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

type RangeKey = 'thisMonth' | 'lastMonth' | 'thisYear' | 'custom';

interface RangeOption {
    value: RangeKey;
    label: string;
}

const RANGE_OPTIONS: RangeOption[] = [
    { value: 'thisMonth', label: 'This month' },
    { value: 'lastMonth', label: 'Last month' },
    { value: 'thisYear', label: 'This year' },
];

interface DateRange {
    start_date: string;
    end_date: string;
}

interface ExpenseRow {
    amount?: number;
    category?: string;
    date?: string;
    description?: string;
    sub_category?: string;
}

interface IncomeRow {
    amount?: number;
    category?: string;
    date?: string;
    title?: string;
    description?: string;
}

interface CategoryRow {
    category: string;
    amount: number;
}

const computeRange = (key: RangeKey): DateRange => {
    switch (key) {
        case 'lastMonth':
            return {
                start_date: moment().subtract(1, 'month').startOf('month').format('YYYY-MM-DD'),
                end_date: moment().subtract(1, 'month').endOf('month').format('YYYY-MM-DD'),
            };
        case 'thisYear':
            return {
                start_date: moment().startOf('year').format('YYYY-MM-DD'),
                end_date: moment().endOf('year').format('YYYY-MM-DD'),
            };
        case 'thisMonth':
        default:
            return {
                start_date: moment().startOf('month').format('YYYY-MM-DD'),
                end_date: moment().endOf('month').format('YYYY-MM-DD'),
            };
    }
};

const escapeCsv = (value: string | number | undefined): string => {
    const str = value == null ? '' : String(value);
    if (/[",\n]/.test(str)) {
        return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
};

const escapeHtml = (value: string | number | undefined): string => {
    const str = value == null ? '' : String(value);
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
};

export default function ReportsScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();

    const [range, setRange] = useState<RangeKey>('thisMonth');
    const [customStart, setCustomStart] = useState('');
    const [customEnd, setCustomEnd] = useState('');

    const [loading, setLoading] = useState(true);
    const [exporting, setExporting] = useState(false);
    const [totalIncome, setTotalIncome] = useState(0);
    const [totalExpense, setTotalExpense] = useState(0);
    const [categories, setCategories] = useState<CategoryRow[]>([]);
    const [expenses, setExpenses] = useState<ExpenseRow[]>([]);
    const [incomes, setIncomes] = useState<IncomeRow[]>([]);

    const activeRange = useMemo<DateRange | null>(() => {
        if (range === 'custom') {
            if (!customStart || !customEnd) return null;
            return { start_date: customStart, end_date: customEnd };
        }
        return computeRange(range);
    }, [range, customStart, customEnd]);

    const net = totalIncome - totalExpense;

    const load = useCallback(() => {
        if (!activeRange) {
            setLoading(false);
            return;
        }
        setLoading(true);
        Promise.all([api.getExpenses(activeRange), api.getIncomes(activeRange)])
            .then(([expenseRes, incomeRes]) => {
                const expenseList: ExpenseRow[] = expenseRes.data?.expenses || [];
                const expenseTotal: number = expenseRes.data?.total_expenses || 0;
                // Incomes come back as a bare array (different envelope from expenses).
                const incomeList: IncomeRow[] = Array.isArray(incomeRes.data) ? incomeRes.data : [];
                const incomeTotal = incomeList.reduce((sum, i) => sum + (Number(i.amount) || 0), 0);

                // Group expenses by category, sum, sort desc.
                const byCategory: Record<string, number> = {};
                expenseList.forEach((e) => {
                    const key = e.category || 'Other';
                    byCategory[key] = (byCategory[key] || 0) + (Number(e.amount) || 0);
                });
                const catRows: CategoryRow[] = Object.keys(byCategory)
                    .map((category) => ({ category, amount: byCategory[category] }))
                    .sort((a, b) => b.amount - a.amount);

                setExpenses(expenseList);
                setIncomes(incomeList);
                setTotalExpense(expenseTotal);
                setTotalIncome(incomeTotal);
                setCategories(catRows);
            })
            .catch(() => {
                Toast.show({ type: 'error', text1: 'Could not load report data' });
            })
            .finally(() => setLoading(false));
    }, [activeRange]);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const maxCategory = categories.length ? categories[0].amount : 0;

    const buildCsv = useCallback((): string => {
        const lines = ['Date,Type,Category,Description,Amount'];
        expenses.forEach((e) => {
            lines.push([
                escapeCsv(e.date),
                'Expense',
                escapeCsv(e.category),
                escapeCsv(e.description),
                escapeCsv(e.amount),
            ].join(','));
        });
        incomes.forEach((i) => {
            lines.push([
                escapeCsv(i.date),
                'Income',
                escapeCsv(i.category),
                escapeCsv(i.title || i.description),
                escapeCsv(i.amount),
            ].join(','));
        });
        return lines.join('\n');
    }, [expenses, incomes]);

    const buildHtml = useCallback((): string => {
        const rangeLabel = activeRange
            ? `${activeRange.start_date} to ${activeRange.end_date}`
            : '';
        const rowHtml = (
            date: string | undefined,
            type: string,
            category: string | undefined,
            description: string | undefined,
            amount: number | undefined,
        ) =>
            `<tr><td>${escapeHtml(date)}</td><td>${type}</td><td>${escapeHtml(category)}</td>` +
            `<td>${escapeHtml(description)}</td><td class="amt">${escapeHtml(
                formatCurrency(amount),
            )}</td></tr>`;

        const expenseRows = expenses
            .map((e) => rowHtml(e.date, 'Expense', e.category, e.description, e.amount))
            .join('');
        const incomeRows = incomes
            .map((i) => rowHtml(i.date, 'Income', i.category, i.title || i.description, i.amount))
            .join('');

        return `<!DOCTYPE html><html><head><meta charset="utf-8" />
<style>
  body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #130B3D; padding: 24px; }
  h1 { font-size: 22px; margin: 0 0 4px; }
  .sub { color: #68708F; margin: 0 0 20px; font-size: 13px; }
  .totals { display: flex; gap: 16px; margin-bottom: 20px; }
  .stat { flex: 1; border: 1px solid #E7E1F0; border-radius: 12px; padding: 12px 16px; }
  .stat .label { color: #68708F; font-size: 12px; }
  .stat .value { font-size: 18px; font-weight: 700; margin-top: 4px; }
  table { width: 100%; border-collapse: collapse; font-size: 12px; }
  th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #EFEDF5; }
  th { background: #F0EDF5; }
  .amt { text-align: right; white-space: nowrap; }
</style></head><body>
  <h1>Wealthify report</h1>
  <p class="sub">${escapeHtml(rangeLabel)}</p>
  <div class="totals">
    <div class="stat"><div class="label">Income</div><div class="value">${escapeHtml(
        formatCurrency(totalIncome),
    )}</div></div>
    <div class="stat"><div class="label">Expense</div><div class="value">${escapeHtml(
        formatCurrency(totalExpense),
    )}</div></div>
    <div class="stat"><div class="label">Net</div><div class="value">${escapeHtml(
        formatCurrency(net),
    )}</div></div>
  </div>
  <table>
    <thead><tr><th>Date</th><th>Type</th><th>Category</th><th>Description</th><th class="amt">Amount</th></tr></thead>
    <tbody>${expenseRows}${incomeRows}</tbody>
  </table>
</body></html>`;
    }, [activeRange, expenses, incomes, totalIncome, totalExpense, net, formatCurrency]);

    const exportCsv = useCallback(async () => {
        setExporting(true);
        try {
            const csv = buildCsv();
            const uri = FileSystem.cacheDirectory + 'wealthify-report.csv';
            await FileSystem.writeAsStringAsync(uri, csv);
            if (await Sharing.isAvailableAsync()) {
                await Sharing.shareAsync(uri, {
                    mimeType: 'text/csv',
                    dialogTitle: 'Wealthify report',
                });
            } else {
                Toast.show({ type: 'success', text1: 'CSV saved' });
            }
        } catch {
            Toast.show({ type: 'error', text1: 'Could not export CSV' });
        } finally {
            setExporting(false);
        }
    }, [buildCsv]);

    const exportPdf = useCallback(async () => {
        setExporting(true);
        try {
            const html = buildHtml();
            const { uri } = await Print.printToFileAsync({ html });
            if (await Sharing.isAvailableAsync()) {
                await Sharing.shareAsync(uri);
            } else {
                Toast.show({ type: 'success', text1: 'PDF saved' });
            }
        } catch {
            Toast.show({ type: 'error', text1: 'Could not export PDF' });
        } finally {
            setExporting(false);
        }
    }, [buildHtml]);

    const hasData = expenses.length > 0 || incomes.length > 0;

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Reports</Text>
                <View style={{ width: 40 }} />
            </View>

            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
            >
                {/* Range selector */}
                <View style={styles.segment}>
                    {RANGE_OPTIONS.map((opt) => {
                        const active = opt.value === range;
                        return (
                            <Pressable
                                key={opt.value}
                                onPress={() => setRange(opt.value)}
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

                <Card style={styles.customCard}>
                    <View style={styles.customHeader}>
                        <Text style={styles.customLabel}>Custom range</Text>
                        {range === 'custom' ? (
                            <Pressable onPress={() => setRange('thisMonth')}>
                                <Text style={styles.clearLink}>Clear</Text>
                            </Pressable>
                        ) : null}
                    </View>
                    <View style={styles.dateRow}>
                        <View style={styles.dateCol}>
                            <CustomDatePicker
                                value={customStart}
                                placeholder="Start date"
                                onChange={(d) => {
                                    setCustomStart(d);
                                    setRange('custom');
                                }}
                            />
                        </View>
                        <View style={styles.dateCol}>
                            <CustomDatePicker
                                value={customEnd}
                                placeholder="End date"
                                onChange={(d) => {
                                    setCustomEnd(d);
                                    setRange('custom');
                                }}
                            />
                        </View>
                    </View>
                </Card>

                {loading ? (
                    <View style={styles.center}>
                        <ActivityIndicator color={colors.primary} />
                    </View>
                ) : (
                    <>
                        {/* Stat cards */}
                        <View style={styles.statsRow}>
                            <Card style={styles.statCard} elevation="sm">
                                <Text style={styles.statLabel}>Income</Text>
                                <Text style={[styles.statValue, { color: colors.accentDark }]} numberOfLines={1}>
                                    {formatCurrency(totalIncome)}
                                </Text>
                            </Card>
                            <Card style={styles.statCard} elevation="sm">
                                <Text style={styles.statLabel}>Expense</Text>
                                <Text style={[styles.statValue, { color: colors.negative }]} numberOfLines={1}>
                                    {formatCurrency(totalExpense)}
                                </Text>
                            </Card>
                        </View>
                        <Card style={styles.netCard}>
                            <Text style={styles.statLabel}>Net</Text>
                            <Text
                                style={[
                                    styles.netValue,
                                    { color: net >= 0 ? colors.accentDark : colors.negative },
                                ]}
                                numberOfLines={1}
                            >
                                {formatCurrency(net)}
                            </Text>
                        </Card>

                        {/* Category breakdown */}
                        <Text style={styles.sectionLabel}>Spending by category</Text>
                        {categories.length === 0 ? (
                            <Card style={styles.empty}>
                                <Icon name="bar-chart-outline" size={34} color={colors.textSubtle} />
                                <Text style={styles.emptyTitle}>No expenses in this range</Text>
                                <Text style={styles.emptyBody}>
                                    Pick a different range to see a category breakdown.
                                </Text>
                            </Card>
                        ) : (
                            <Card style={styles.breakdownCard}>
                                {categories.map((row, idx) => (
                                    <View
                                        key={row.category}
                                        style={[styles.catRow, idx > 0 && styles.catRowDivided]}
                                    >
                                        <View style={styles.catTop}>
                                            <Text style={styles.catName} numberOfLines={1}>
                                                {row.category}
                                            </Text>
                                            <Text style={styles.catAmount}>{formatCurrency(row.amount)}</Text>
                                        </View>
                                        <CategoryBar
                                            value={row.amount}
                                            max={maxCategory}
                                            colors={colors}
                                            styles={styles}
                                        />
                                    </View>
                                ))}
                            </Card>
                        )}

                        {/* Export */}
                        <Text style={styles.sectionLabel}>Export</Text>
                        <PillButton
                            label="Export CSV"
                            variant="secondary"
                            disabled={exporting || !hasData}
                            loading={exporting}
                            onPress={exportCsv}
                            leftIcon={<Icon name="document-text-outline" size={18} color={colors.text} />}
                            style={{ marginBottom: space.md }}
                        />
                        <PillButton
                            label="Export PDF"
                            variant="primary"
                            disabled={exporting || !hasData}
                            loading={exporting}
                            onPress={exportPdf}
                            leftIcon={<Icon name="share-outline" size={18} color={colors.textInverse} />}
                        />
                    </>
                )}

                <View style={{ height: 60 }} />
            </ScrollView>
        </ScreenContainer>
    );
}

const CategoryBar = ({
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
    return (
        <View style={styles.track}>
            <View
                style={[
                    styles.fill,
                    { width: `${ratio * 100}%`, backgroundColor: colors.accentDark },
                ]}
            />
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
        center: { paddingVertical: space['4xl'], alignItems: 'center', justifyContent: 'center' },
        scroll: { paddingHorizontal: space.xl, paddingTop: space.sm, paddingBottom: space['3xl'] },
        segment: {
            flexDirection: 'row',
            backgroundColor: colors.surfaceMuted,
            borderRadius: radius.sm,
            padding: 4,
            gap: 4,
        },
        segmentItem: {
            flex: 1,
            flexDirection: 'row',
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
        customCard: { marginTop: space.md, gap: space.sm },
        customHeader: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
        },
        customLabel: { ...Typography.label, color: colors.textSubtle },
        clearLink: { ...Typography.link, color: colors.primary },
        dateRow: { flexDirection: 'row', gap: space.sm },
        dateCol: { flex: 1 },
        statsRow: { flexDirection: 'row', gap: space.md, marginTop: space.lg },
        statCard: { flex: 1, gap: space.xs },
        statLabel: { ...Typography.label, color: colors.textSubtle },
        statValue: { ...Typography.moneyMd },
        netCard: { marginTop: space.md, gap: space.xs },
        netValue: { ...Typography.titleLg },
        sectionLabel: {
            ...Typography.label,
            color: colors.textSubtle,
            marginTop: space.xl,
            marginBottom: space.sm,
        },
        breakdownCard: { gap: space.md },
        catRow: { gap: space.sm },
        catRowDivided: {
            borderTopWidth: StyleSheet.hairlineWidth,
            borderTopColor: colors.border,
            paddingTop: space.md,
        },
        catTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
        catName: { ...Typography.bodyMedium, color: colors.text, flex: 1, marginRight: space.sm },
        catAmount: { ...Typography.bodySm, color: colors.text, fontFamily: Typography.bodyMedium.fontFamily },
        track: {
            height: 8, borderRadius: 4, backgroundColor: colors.surfaceMuted, overflow: 'hidden',
        },
        fill: { height: '100%', borderRadius: 4 },
        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
    });
