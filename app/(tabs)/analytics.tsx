import React, { useCallback, useMemo, useState } from "react";
import {
  type DimensionValue,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from "react-native";
import { BarChart } from "react-native-gifted-charts";
import Icon from "react-native-vector-icons/Ionicons";
import moment from "moment";
import { useFocusEffect } from "expo-router";
import APIService from "@/src/ApiService/api.service";
import {
  Card,
  IconBadge,
  ScreenContainer,
  SectionHeader,
} from "@/src/components/ui";
import {
  Fonts,
  Shadows,
  Typography,
  noWebOutline,
  radius,
  space,
  useColors,
  type ColorPalette,
} from "@/src/styles/theme";
import { formatNumberWithCommas } from "@/src/utils/helper";
import { resolveCategoryIcon } from "@/src/utils/categoryIcon";
import { getTransactionDate, readTransactionList } from "@/src/utils/transactions";
import SkeletonBlock from "@/src/components/skeletons/SkeletonBlock";

const api = new APIService();

type Styles = ReturnType<typeof makeStyles>;
type LegendStyles = ReturnType<typeof makeLegendStyles>;
type SkeletonStyles = ReturnType<typeof makeSkeletonStyles>;

interface Txn {
  type?: "income" | "expense";
  title?: string;
  category?: string;
  date?: string;
  createdAt?: string;
  updatedAt?: string;
  amount?: number;
}

type RangeKey =
  | "today"
  | "yesterday"
  | "last3Days"
  | "thisWeek"
  | "thisMonth"
  | "thisYear";
type AnalyticsTab = "overview" | "trends";

const RANGE_OPTIONS: { key: RangeKey; label: string }[] = [
  { key: "today", label: "Today" },
  { key: "yesterday", label: "Yesterday" },
  { key: "last3Days", label: "Last 3 days" },
  { key: "thisWeek", label: "This week" },
  { key: "thisMonth", label: "This month" },
  { key: "thisYear", label: "This year" },
];

const buildDateRange = (key: RangeKey) => {
  const today = moment();
  let start = today.clone().startOf("day");
  let end = today.clone().endOf("day");

  if (key === "yesterday") {
    start = today.clone().subtract(1, "day").startOf("day");
    end = today.clone().subtract(1, "day").endOf("day");
  } else if (key === "last3Days") {
    start = today.clone().subtract(2, "days").startOf("day");
    end = today.clone().endOf("day");
  } else if (key === "thisWeek") {
    start = today.clone().startOf("isoWeek");
    end = today.clone().endOf("isoWeek");
  } else if (key === "thisMonth") {
    start = today.clone().startOf("month");
    end = today.clone().endOf("month");
  } else if (key === "thisYear") {
    start = today.clone().startOf("year");
    end = today.clone().endOf("year");
  }

  return { start, end };
};

const isTxnInRange = (txn: Txn, start: moment.Moment, end: moment.Moment) => {
  const date = moment(getTransactionDate(txn));
  return date.isValid() && date.isBetween(start, end, undefined, "[]");
};

const sumTransactions = (list: Txn[]) =>
  list.reduce((total, txn) => total + Number(txn.amount || 0), 0);

export default function AnalyticsScreen() {
  const colors = useColors();
  const styles = useMemo(() => makeStyles(colors), [colors]);
  const legendStyles = useMemo(() => makeLegendStyles(colors), [colors]);
  const skeletonStyles = useMemo(() => makeSkeletonStyles(colors), [colors]);
  const { width } = useWindowDimensions();
  const chartWidth = Math.min(width - space.xl * 2 - space.lg * 2 - 44, 300);
  const [selectedTab, setSelectedTab] = useState<AnalyticsTab>("overview");
  const [selectedRangeKey, setSelectedRangeKey] =
    useState<RangeKey>("thisYear");
  const [rangeMenuOpen, setRangeMenuOpen] = useState(false);
  const [chartResetKey, setChartResetKey] = useState(0);
  const [selectedChartItem, setSelectedChartItem] = useState<any | null>(null);
  const [incomes, setIncomes] = useState<Txn[]>([]);
  const [expenses, setExpenses] = useState<Txn[]>([]);
  const [loading, setLoading] = useState(true);

  const selectedRange = useMemo(
    () =>
      RANGE_OPTIONS.find((option) => option.key === selectedRangeKey) ||
      RANGE_OPTIONS[5],
    [selectedRangeKey],
  );
  const emptyRangeLabel = useMemo(
    () =>
      selectedRangeKey === "last3Days"
        ? "the last 3 days"
        : selectedRange.label.toLowerCase(),
    [selectedRange.label, selectedRangeKey],
  );
  const rangeConfig = useMemo(
    () => buildDateRange(selectedRangeKey),
    [selectedRangeKey],
  );

  const load = useCallback(async () => {
    const range = {
      start_date: rangeConfig.start.format("YYYY-MM-DD"),
      end_date: rangeConfig.end.format("YYYY-MM-DD"),
    };

    setLoading(true);
    const [incomeResult, expenseResult] = await Promise.allSettled([
      api.getIncomes(range),
      api.getExpenses(range),
    ]);

    if (incomeResult.status === "fulfilled") {
      const list = readTransactionList(incomeResult.value, "incomes");
      setIncomes(list.map((t: Txn) => ({ ...t, type: "income" })));
    } else {
      setIncomes([]);
    }

    if (expenseResult.status === "fulfilled") {
      const list = readTransactionList(expenseResult.value, "expenses");
      setExpenses(list.map((t: Txn) => ({ ...t, type: "expense" })));
    } else {
      setExpenses([]);
    }

    setLoading(false);
  }, [rangeConfig]);

  useFocusEffect(
    useCallback(() => {
      load();
    }, [load]),
  );

  const chartBuckets = useMemo(() => {
    if (selectedRangeKey === "thisYear") {
      const now = moment();
      const months = [];
      const cursor = rangeConfig.start.clone();
      while (cursor.isSameOrBefore(now, "month")) {
        months.push({
          key: cursor.format("YYYY-MM"),
          label: cursor.format("MMM"),
          longLabel: cursor.format("MMM"),
        });
        cursor.add(1, "month");
      }
      return months;
    }

    if (selectedRangeKey === "thisMonth") {
      const days = [];
      const cursor = rangeConfig.start.clone();
      while (cursor.isSameOrBefore(rangeConfig.end, "day")) {
        days.push({
          key: cursor.format("YYYY-MM-DD"),
          label: cursor.format("MMM D"),
          longLabel: cursor.format("MMM D"),
        });
        cursor.add(1, "day");
      }
      return days;
    }

    const days = [];
    const cursor = rangeConfig.start.clone();
    while (cursor.isSameOrBefore(rangeConfig.end, "day")) {
      days.push({
        key: cursor.format("YYYY-MM-DD"),
        label:
          selectedRangeKey === "thisWeek"
            ? cursor.format("ddd")
            : cursor.format("D MMM"),
        longLabel:
          selectedRangeKey === "today"
            ? "Today"
            : selectedRangeKey === "yesterday"
              ? "Yesterday"
              : cursor.format("D MMM"),
      });
      cursor.add(1, "day");
    }
    return days;
  }, [rangeConfig, selectedRangeKey]);

  const chartBucketCount = chartBuckets.length;
  const chartNeedsScroll =
    selectedRangeKey === "thisMonth" ||
    selectedRangeKey === "thisYear" ||
    chartBucketCount >= 6;
  const chartBarWidth = selectedRangeKey === "thisMonth" ? 8 : 10;
  const hasManyLabels =
    selectedRangeKey === "thisMonth" ||
    selectedRangeKey === "thisYear" ||
    chartBucketCount >= 6;
  const chartYAxisLabelWidth = 44;
  const chartLabelWidth =
    selectedRangeKey === "thisMonth"
      ? 56
      : selectedRangeKey === "thisYear"
        ? 52
        : hasManyLabels
          ? 48
          : 40;
  const chartGroupWidth = chartBarWidth * 2 + 2;
  const singleBucketInitialSpacing = Math.max(
    8,
    (chartWidth - chartGroupWidth) / 4,
  );
  const chartEdgeSpacing = Math.max(8, (chartLabelWidth - chartGroupWidth) / 2);
  const distributedGroupSpacing =
    chartBucketCount > 1 && chartBucketCount <= 3
      ? Math.max(
          14,
          (chartWidth -
            chartEdgeSpacing * 2 -
            chartGroupWidth * chartBucketCount) /
            (chartBucketCount - 1),
        )
      : selectedRangeKey === "thisMonth"
        ? 38
        : selectedRangeKey === "thisYear"
          ? 30
          : hasManyLabels
            ? 26
            : 14;
  const chartInitialSpacing =
    chartBucketCount === 1
      ? singleBucketInitialSpacing
      : chartBucketCount <= 3
        ? chartEdgeSpacing
        : 10;

  const currentIncomes = useMemo(
    () =>
      incomes.filter((txn) =>
        isTxnInRange(txn, rangeConfig.start, rangeConfig.end),
      ),
    [incomes, rangeConfig],
  );
  const currentExpenses = useMemo(
    () =>
      expenses.filter((txn) =>
        isTxnInRange(txn, rangeConfig.start, rangeConfig.end),
      ),
    [expenses, rangeConfig],
  );

  const barData = useMemo(() => {
    const getBucketKey = (txn: Txn) => {
      const m = moment(getTransactionDate(txn));
      if (!m.isValid()) return "";
      if (selectedRangeKey === "thisYear") return m.format("YYYY-MM");
      return m.format("YYYY-MM-DD");
    };
    const sumByBucket = (list: Txn[]) =>
      list.reduce<Record<string, number>>((acc, t) => {
        const k = getBucketKey(t);
        if (!k) return acc;
        acc[k] = (acc[k] || 0) + Number(t.amount || 0);
        return acc;
      }, {});
    const inc = sumByBucket(currentIncomes);
    const exp = sumByBucket(currentExpenses);
    const data: any[] = [];
    const totalBars = chartBuckets.length * 2;
    chartBuckets.forEach((bucket, idx) => {
      const incomeIndex = data.length;
      data.push({
        value: inc[bucket.key] || 0,
        spacing: 2,
        frontColor: colors.primary,
        label: bucket.label,
        labelWidth: chartLabelWidth,
        labelTextStyle: styles.chartLabel,
        tooltipType: "Income",
        tooltipPeriod: bucket.longLabel,
        leftShiftForTooltip:
          incomeIndex <= 1 ? -52 : incomeIndex >= totalBars - 2 ? 84 : 0,
      });
      const expenseIndex = data.length;
      data.push({
        value: exp[bucket.key] || 0,
        frontColor: colors.accentDark,
        spacing: idx < chartBuckets.length - 1 ? distributedGroupSpacing : 0,
        tooltipType: "Expense",
        tooltipPeriod: bucket.longLabel,
        leftShiftForTooltip:
          expenseIndex <= 1 ? -52 : expenseIndex >= totalBars - 2 ? 84 : 0,
      });
    });
    return data;
  }, [
    chartBuckets,
    chartLabelWidth,
    distributedGroupSpacing,
    currentIncomes,
    currentExpenses,
    selectedRangeKey,
    colors,
    styles,
  ]);
  const chartTooltipPlacement = useMemo(() => {
    if (!selectedChartItem || barData.length <= 2)
      return styles.chartTooltipOverlayCenter;
    if (selectedChartItem.index <= 1) return styles.chartTooltipOverlayLeft;
    if (selectedChartItem.index >= barData.length - 2)
      return styles.chartTooltipOverlayRight;
    return styles.chartTooltipOverlayCenter;
  }, [barData.length, selectedChartItem, styles]);

  const totalIncome = useMemo(
    () => sumTransactions(currentIncomes),
    [currentIncomes],
  );
  const totalExpense = useMemo(
    () => sumTransactions(currentExpenses),
    [currentExpenses],
  );
  const historyBalance = totalIncome - totalExpense;
  const historySign = historyBalance >= 0 ? "+" : "-";
  const historyAmountColor =
    historyBalance >= 0 ? colors.accentDark : colors.negative;
  const hasRangeData = totalIncome > 0 || totalExpense > 0;

  const byCategory = useMemo(() => {
    const totals: Record<string, number> = {};
    currentExpenses.forEach((t) => {
      const key = t.category || "Other";
      totals[key] = (totals[key] || 0) + Number(t.amount || 0);
    });
    return Object.entries(totals)
      .map(([category, value]) => ({
        category,
        value,
        ...resolveCategoryIcon(category, "expense"),
      }))
      .sort((a, b) => b.value - a.value);
  }, [currentExpenses]);

  const trendRows = useMemo(() => {
    const getBucketKey = (txn: Txn) => {
      const m = moment(getTransactionDate(txn));
      if (!m.isValid()) return "";
      if (selectedRangeKey === "thisYear") return m.format("YYYY-MM");
      return m.format("YYYY-MM-DD");
    };
    const sumByBucket = (list: Txn[]) =>
      list.reduce<Record<string, number>>((acc, t) => {
        const k = getBucketKey(t);
        if (!k) return acc;
        acc[k] = (acc[k] || 0) + Number(t.amount || 0);
        return acc;
      }, {});

    const inc = sumByBucket(currentIncomes);
    const exp = sumByBucket(currentExpenses);
    return chartBuckets.map((bucket) => {
      const income = inc[bucket.key] || 0;
      const expense = exp[bucket.key] || 0;
      return {
        key: bucket.key,
        label: bucket.longLabel,
        income,
        expense,
        net: income - expense,
      };
    });
  }, [chartBuckets, currentExpenses, currentIncomes, selectedRangeKey]);

  const activeTrendRows = useMemo(
    () => trendRows.filter((row) => row.income > 0 || row.expense > 0),
    [trendRows],
  );
  const maxTrendAmount = useMemo(
    () =>
      Math.max(
        1,
        ...trendRows.flatMap((row) => [
          row.income,
          row.expense,
          Math.abs(row.net),
        ]),
      ),
    [trendRows],
  );
  const strongestIncome = useMemo(
    () =>
      trendRows.reduce(
        (best, row) => (row.income > best.income ? row : best),
        trendRows[0] || {
          label: selectedRange.label,
          income: 0,
          expense: 0,
          net: 0,
        },
      ),
    [selectedRange.label, trendRows],
  );
  const highestExpense = useMemo(
    () =>
      trendRows.reduce(
        (best, row) => (row.expense > best.expense ? row : best),
        trendRows[0] || {
          label: selectedRange.label,
          income: 0,
          expense: 0,
          net: 0,
        },
      ),
    [selectedRange.label, trendRows],
  );
  const netMovement = useMemo(() => {
    if (activeTrendRows.length < 2) return 0;
    return (
      activeTrendRows[activeTrendRows.length - 1].net - activeTrendRows[0].net
    );
  }, [activeTrendRows]);

  return (
    <ScreenContainer variant="wash" extendUnderStatusBar>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scroll}
        onTouchStart={() => {
          if (rangeMenuOpen) setRangeMenuOpen(false);
          setChartResetKey((key) => key + 1);
          setSelectedChartItem(null);
        }}
      >
        <View style={styles.headerRow}>
          <Text style={styles.title}>Analytics</Text>
        </View>

        <View style={styles.segmentWrap}>
          <Pressable
            accessibilityRole="button"
            accessibilityState={{ selected: selectedTab === "overview" }}
            onPress={() => setSelectedTab("overview")}
            style={[
              styles.segment,
              selectedTab === "overview" && styles.segmentActive,
              noWebOutline,
            ]}
          >
            <Text
              style={[
                styles.segmentText,
                selectedTab === "overview" && styles.segmentActiveText,
              ]}
            >
              Overview
            </Text>
          </Pressable>
          <Pressable
            accessibilityRole="button"
            accessibilityState={{ selected: selectedTab === "trends" }}
            onPress={() => setSelectedTab("trends")}
            style={[
              styles.segment,
              selectedTab === "trends" && styles.segmentActive,
              noWebOutline,
            ]}
          >
            <Text
              style={[
                styles.segmentText,
                selectedTab === "trends" && styles.segmentActiveText,
              ]}
            >
              Trends
            </Text>
          </Pressable>
        </View>

        {loading ? (
          <AnalyticsSkeleton
            selectedTab={selectedTab}
            styles={styles}
            legendStyles={legendStyles}
            skeletonStyles={skeletonStyles}
          />
        ) : (
          <>
        <Card style={styles.chartCard}>
          <View
            style={[
              styles.chartHeader,
              rangeMenuOpen && styles.chartHeaderMenuOpen,
            ]}
          >
            <View
              style={styles.rangeControl}
              onTouchStart={(event) => event.stopPropagation()}
            >
              <Pressable
                accessibilityRole="button"
                onPress={() => setRangeMenuOpen((open) => !open)}
                style={[styles.rangePill, noWebOutline]}
              >
                <Text style={styles.rangeText}>{selectedRange.label}</Text>
                <Icon
                  name={rangeMenuOpen ? "chevron-up" : "chevron-down"}
                  size={14}
                  color={colors.text}
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
                          setChartResetKey((key) => key + 1);
                          setSelectedChartItem(null);
                        }}
                        style={[
                          styles.rangeOption,
                          active && styles.rangeOptionActive,
                          noWebOutline,
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
            <View style={styles.legendRow}>
              <Legend dot={colors.primary} label="Income" legendStyles={legendStyles} />
              <Legend dot={colors.accentDark} label="Expense" legendStyles={legendStyles} />
            </View>
          </View>
          <View
            style={styles.chartWrap}
            onTouchStart={(event) => event.stopPropagation()}
          >
            {hasRangeData ? (
              <BarChart
                key={chartResetKey}
                data={barData}
                width={chartWidth}
                parentWidth={chartWidth}
                height={180}
                barWidth={chartBarWidth}
                barBorderRadius={8}
                initialSpacing={chartInitialSpacing}
                endSpacing={chartNeedsScroll ? 24 : chartInitialSpacing}
                spacing={8}
                noOfSections={4}
                overflowTop={64}
                yAxisThickness={0}
                xAxisThickness={0}
                yAxisLabelWidth={chartYAxisLabelWidth}
                yAxisTextStyle={styles.chartYAxisLabel}
                xAxisTextNumberOfLines={1}
                rulesColor={colors.divider}
                rulesType="dashed"
                dashWidth={8}
                dashGap={8}
                rulesThickness={1}
                formatYLabel={(label: string) => {
                  const value = Number(label);
                  if (!Number.isFinite(value)) return label;
                  if (value >= 1000) return `${Math.round(value / 1000)}k`;
                  return label;
                }}
                onPress={(item: any, index: number) => {
                  setRangeMenuOpen(false);
                  setSelectedChartItem({ ...item, index });
                }}
                onBackgroundPress={() => {
                  if (rangeMenuOpen) setRangeMenuOpen(false);
                  setChartResetKey((key) => key + 1);
                  setSelectedChartItem(null);
                }}
                disableScroll={!chartNeedsScroll}
                showScrollIndicator={false}
                nestedScrollEnabled
              />
            ) : (
              <EmptyAnalyticsChartState
                rangeLabel={emptyRangeLabel}
                styles={styles}
                colors={colors}
              />
            )}
            {hasRangeData && selectedChartItem ? (
              <View
                pointerEvents="none"
                style={[styles.chartTooltipOverlay, chartTooltipPlacement]}
              >
                <View style={styles.chartTooltip}>
                  <Text style={styles.chartTooltipLabel}>
                    {selectedChartItem.tooltipType} -{" "}
                    {selectedChartItem.tooltipPeriod}
                  </Text>
                  <Text style={styles.chartTooltipValue}>
                    ₹
                    {formatNumberWithCommas(
                      Number(selectedChartItem.value || 0).toFixed(0),
                    )}
                  </Text>
                </View>
              </View>
            ) : null}
          </View>
        </Card>

        {selectedTab === "overview" ? (
          <>
            <Card style={styles.statRow}>
              <View style={styles.statLeft}>
                <IconBadge
                  name="trending-up"
                  color={colors.accentDark}
                  bg={colors.accentSoft}
                  size={40}
                  rounded="circle"
                  elevated={false}
                />
                <View style={styles.statBody}>
                  <Text style={styles.statLabel}>Income</Text>
                </View>
              </View>
              <Text style={styles.statAmount}>
                ₹{formatNumberWithCommas(totalIncome.toFixed(2))}
              </Text>
            </Card>

            <Card style={styles.statRow}>
              <View style={styles.statLeft}>
                <IconBadge
                  name="trending-down"
                  color={colors.negative}
                  bg={colors.negativeSoft}
                  size={40}
                  rounded="circle"
                  elevated={false}
                />
                <View style={styles.statBody}>
                  <Text style={styles.statLabel}>Expense</Text>
                </View>
              </View>
              <Text style={styles.statAmount}>
                ₹{formatNumberWithCommas(totalExpense.toFixed(2))}
              </Text>
            </Card>

            <SectionHeader title="History" />
            <Card padding={0} style={styles.historyCard}>
              <View style={styles.historyHeader}>
                <Text style={styles.historyDay}>{selectedRange.label}</Text>
                <Text
                  style={[styles.historyTotal, { color: historyAmountColor }]}
                >
                  {historySign}₹
                  {formatNumberWithCommas(Math.abs(historyBalance).toFixed(0))}
                </Text>
              </View>
              {byCategory.length > 0 ? (
                byCategory.slice(0, 4).map((c) => (
                  <View key={c.category} style={styles.historyRow}>
                    <IconBadge
                      name={c.name}
                      color={c.color}
                      bg={`${c.color}1A`}
                      size={38}
                      rounded="circle"
                      elevated={false}
                    />
                    <View style={styles.catBody}>
                      <Text style={styles.catTitle}>{c.category}</Text>
                      <Text style={styles.catShare}>
                        {totalExpense > 0
                          ? `${((c.value / totalExpense) * 100).toFixed(0)}% of spend`
                          : ""}
                      </Text>
                    </View>
                    <Text style={styles.catAmount}>
                      -₹{formatNumberWithCommas(c.value.toFixed(0))}
                    </Text>
                  </View>
                ))
              ) : (
                <EmptyHistoryState
                  rangeLabel={emptyRangeLabel}
                  styles={styles}
                  colors={colors}
                />
              )}
            </Card>
          </>
        ) : (
          <>
            {hasRangeData ? (
              <Card style={styles.trendSummaryCard}>
                <View style={styles.trendSummaryHeader}>
                  <IconBadge
                    name={netMovement >= 0 ? "trending-up" : "trending-down"}
                    color={netMovement >= 0 ? colors.accentDark : colors.negative}
                    bg={
                      netMovement >= 0 ? colors.accentSoft : colors.negativeSoft
                    }
                    size={42}
                    rounded="circle"
                    elevated={false}
                  />
                  <View style={styles.trendSummaryBody}>
                    <Text style={styles.trendSummaryLabel}>Net movement</Text>
                    <Text
                      style={[
                        styles.trendSummaryValue,
                        {
                          color:
                            netMovement >= 0
                              ? colors.accentDark
                              : colors.negative,
                        },
                      ]}
                    >
                      {netMovement >= 0 ? "+" : "-"}₹
                      {formatNumberWithCommas(Math.abs(netMovement).toFixed(0))}
                    </Text>
                  </View>
                </View>
                <View style={styles.trendMetricRow}>
                  <Text style={styles.trendMetricLabel}>Strongest income</Text>
                  <Text style={styles.trendMetricValue}>
                    {strongestIncome.label} · ₹
                    {formatNumberWithCommas(strongestIncome.income.toFixed(0))}
                  </Text>
                </View>
                <View style={styles.trendMetricRow}>
                  <Text style={styles.trendMetricLabel}>Highest expense</Text>
                  <Text style={styles.trendMetricValue}>
                    {highestExpense.label} · ₹
                    {formatNumberWithCommas(highestExpense.expense.toFixed(0))}
                  </Text>
                </View>
              </Card>
            ) : (
              <EmptyTrendSummaryState
                rangeLabel={emptyRangeLabel}
                styles={styles}
                colors={colors}
              />
            )}

            <SectionHeader title="Trend Detail" />
            <Card padding={0} style={styles.trendListCard}>
              {activeTrendRows.length > 0 ? (
                activeTrendRows.map((row) => (
                  <View key={row.key} style={styles.trendRow}>
                    <View style={styles.trendRowHeader}>
                      <Text style={styles.trendRowTitle}>{row.label}</Text>
                      <Text
                        style={[
                          styles.trendRowNet,
                          {
                            color:
                              row.net >= 0
                                ? colors.accentDark
                                : colors.negative,
                          },
                        ]}
                      >
                        {row.net >= 0 ? "+" : "-"}₹
                        {formatNumberWithCommas(Math.abs(row.net).toFixed(0))}
                      </Text>
                    </View>
                    <View style={styles.trendBars}>
                      <TrendBar
                        label="Income"
                        value={row.income}
                        max={maxTrendAmount}
                        color={colors.primary}
                        styles={styles}
                      />
                      <TrendBar
                        label="Expense"
                        value={row.expense}
                        max={maxTrendAmount}
                        color={colors.accentDark}
                        styles={styles}
                      />
                    </View>
                  </View>
                ))
              ) : (
                <EmptyTrendDetailState
                  rangeLabel={emptyRangeLabel}
                  styles={styles}
                  colors={colors}
                />
              )}
            </Card>
          </>
        )}

        <View style={styles.bottomSpacer} />
          </>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}

const Legend: React.FC<{
  dot: string;
  label: string;
  legendStyles: LegendStyles;
}> = ({ dot, label, legendStyles }) => (
  <View style={legendStyles.row}>
    <View style={[legendStyles.dot, { backgroundColor: dot }]} />
    <Text style={legendStyles.label}>{label}</Text>
  </View>
);

const AnalyticsSkeleton: React.FC<{
  selectedTab: AnalyticsTab;
  styles: Styles;
  legendStyles: LegendStyles;
  skeletonStyles: SkeletonStyles;
}> = ({ selectedTab, styles, legendStyles, skeletonStyles }) => (
  <>
    <Card style={styles.chartCard}>
      <View style={styles.chartHeader}>
        <SkeletonBlock width={96} height={32} radius={16} />
        <View style={styles.legendRow}>
          <LegendSkeleton legendStyles={legendStyles} skeletonStyles={skeletonStyles} />
          <LegendSkeleton legendStyles={legendStyles} skeletonStyles={skeletonStyles} />
        </View>
      </View>
      <View style={styles.chartWrap}>
        <View style={skeletonStyles.chartFrame}>
          {Array.from({ length: 4 }).map((_, index) => (
            <SkeletonBlock
              key={index}
              width="100%"
              height={1}
              radius={1}
              style={[skeletonStyles.chartRule, { top: 24 + index * 42 }]}
            />
          ))}
          <View style={skeletonStyles.barRow}>
            {[92, 136, 72, 164, 110, 142].map((height, index) => (
              <View key={index} style={skeletonStyles.barPair}>
                <SkeletonBlock width={10} height={height} radius={8} />
                <SkeletonBlock
                  width={10}
                  height={Math.max(54, height - 34)}
                  radius={8}
                />
              </View>
            ))}
          </View>
        </View>
      </View>
    </Card>

    {selectedTab === "overview" ? (
      <>
        <StatRowSkeleton styles={styles} />
        <StatRowSkeleton styles={styles} />
        <View style={skeletonStyles.sectionHeader}>
          <SkeletonBlock width={72} height={20} radius={10} />
        </View>
        <Card padding={0} style={styles.historyCard}>
          <View style={styles.historyHeader}>
            <SkeletonBlock width={86} height={18} radius={9} />
            <SkeletonBlock width={92} height={20} radius={10} />
          </View>
          {Array.from({ length: 4 }).map((_, index) => (
            <View key={index} style={styles.historyRow}>
              <SkeletonBlock width={38} height={38} radius={19} />
              <View style={styles.catBody}>
                <SkeletonBlock
                  width={index % 2 ? 116 : 84}
                  height={16}
                  radius={8}
                />
                <SkeletonBlock
                  width={72}
                  height={12}
                  radius={6}
                  style={skeletonStyles.subline}
                />
              </View>
              <SkeletonBlock width={68} height={16} radius={8} />
            </View>
          ))}
        </Card>
      </>
    ) : (
      <>
        <Card style={styles.trendSummaryCard}>
          <View style={styles.trendSummaryHeader}>
            <SkeletonBlock width={42} height={42} radius={21} />
            <View style={styles.trendSummaryBody}>
              <SkeletonBlock width={102} height={14} radius={7} />
              <SkeletonBlock
                width={98}
                height={24}
                radius={12}
                style={skeletonStyles.subline}
              />
            </View>
          </View>
          <SkeletonBlock
            width="100%"
            height={16}
            radius={8}
            style={skeletonStyles.trendMetric}
          />
          <SkeletonBlock
            width="86%"
            height={16}
            radius={8}
            style={skeletonStyles.trendMetric}
          />
        </Card>
        <View style={skeletonStyles.sectionHeader}>
          <SkeletonBlock width={104} height={20} radius={10} />
        </View>
        <Card padding={0} style={styles.trendListCard}>
          {Array.from({ length: 3 }).map((_, index) => (
            <View key={index} style={styles.trendRow}>
              <View style={styles.trendRowHeader}>
                <SkeletonBlock width={92} height={16} radius={8} />
                <SkeletonBlock width={78} height={16} radius={8} />
              </View>
              <SkeletonBlock
                width="100%"
                height={8}
                radius={4}
                style={skeletonStyles.trendBar}
              />
              <SkeletonBlock
                width="74%"
                height={8}
                radius={4}
                style={skeletonStyles.trendBar}
              />
            </View>
          ))}
        </Card>
      </>
    )}

    <View style={styles.bottomSpacer} />
  </>
);

const StatRowSkeleton: React.FC<{ styles: Styles }> = ({ styles }) => (
  <Card style={styles.statRow}>
    <View style={styles.statLeft}>
      <SkeletonBlock width={40} height={40} radius={20} />
      <View style={styles.statBody}>
        <SkeletonBlock width={72} height={16} radius={8} />
      </View>
    </View>
    <SkeletonBlock width={98} height={18} radius={9} />
  </Card>
);

const LegendSkeleton: React.FC<{
  legendStyles: LegendStyles;
  skeletonStyles: SkeletonStyles;
}> = ({ legendStyles, skeletonStyles }) => (
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

const EmptyMetricChip: React.FC<{
  dot: string;
  label: string;
  styles: Styles;
}> = ({ dot, label, styles }) => (
  <View style={styles.emptyMetricChip}>
    <View style={[styles.emptyMetricDot, { backgroundColor: dot }]} />
    <Text style={styles.emptyMetricText}>{label}</Text>
  </View>
);

const EmptyAnalyticsChartState: React.FC<{
  rangeLabel: string;
  styles: Styles;
  colors: ColorPalette;
}> = ({ rangeLabel, styles, colors }) => (
  <View style={styles.emptyChartState}>
    <View style={styles.emptyChartGraphic}>
      <View style={styles.emptyChartBars}>
        <View style={[styles.emptyBar, styles.emptyBarIncome]} />
        <View style={[styles.emptyBar, styles.emptyBarExpense]} />
        <View style={[styles.emptyBar, styles.emptyBarMuted]} />
      </View>
      <View style={styles.emptyChartIcon}>
        <Icon name="analytics-outline" size={26} color={colors.primary} />
      </View>
    </View>
    <Text style={styles.emptyTitle}>No analytics yet</Text>
    <Text style={styles.emptySubText}>
      Add income or expenses for {rangeLabel} to see your cash flow here.
    </Text>
    <View style={styles.emptyMetricRow}>
      <EmptyMetricChip dot={colors.primary} label="Income ₹0" styles={styles} />
      <EmptyMetricChip dot={colors.accentDark} label="Expense ₹0" styles={styles} />
    </View>
  </View>
);

const EmptyHistoryState: React.FC<{
  rangeLabel: string;
  styles: Styles;
  colors: ColorPalette;
}> = ({ rangeLabel, styles, colors }) => (
  <View style={styles.emptyInlineState}>
    <View style={styles.emptyInlineIcon}>
      <Icon name="file-tray-outline" size={24} color={colors.textSubtle} />
    </View>
    <View style={styles.emptyInlineCopy}>
      <Text style={styles.emptyInlineTitle}>No history yet</Text>
      <Text style={styles.emptyInlineSub}>
        Categories from {rangeLabel} will appear here.
      </Text>
    </View>
  </View>
);

const EmptyTrendSummaryState: React.FC<{
  rangeLabel: string;
  styles: Styles;
  colors: ColorPalette;
}> = ({ rangeLabel, styles, colors }) => (
  <Card style={styles.emptyTrendSummaryCard}>
    <View style={styles.emptyInlineIcon}>
      <Icon name="trending-up-outline" size={24} color={colors.primary} />
    </View>
    <View style={styles.emptyInlineCopy}>
      <Text style={styles.emptyInlineTitle}>No movement yet</Text>
      <Text style={styles.emptyInlineSub}>
        Trends for {rangeLabel} will unlock after your first entry.
      </Text>
    </View>
  </Card>
);

const EmptyTrendDetailState: React.FC<{
  rangeLabel: string;
  styles: Styles;
  colors: ColorPalette;
}> = ({ rangeLabel, styles, colors }) => (
  <View style={styles.emptyDetailState}>
    <Icon name="stats-chart-outline" size={26} color={colors.textSubtle} />
    <Text style={styles.emptyTitle}>No trend data</Text>
    <Text style={styles.emptySubText}>
      There are no income or expense entries for {rangeLabel}.
    </Text>
  </View>
);

const TrendBar: React.FC<{
  label: string;
  value: number;
  max: number;
  color: string;
  styles: Styles;
}> = ({ label, value, max, color, styles }) => {
  const fillWidth =
    `${Math.max(4, Math.min(100, (value / max) * 100))}%` as DimensionValue;

  return (
    <View style={styles.trendBarRow}>
      <Text style={styles.trendBarLabel}>{label}</Text>
      <View style={styles.trendBarTrack}>
        <View
          style={[
            styles.trendBarFill,
            { backgroundColor: color, width: fillWidth },
          ]}
        />
      </View>
      <Text style={styles.trendBarAmount}>
        ₹{formatNumberWithCommas(value.toFixed(0))}
      </Text>
    </View>
  );
};

const makeStyles = (colors: ColorPalette) =>
  StyleSheet.create({
  scroll: {
    paddingHorizontal: space.xl,
    paddingTop: space.lg,
    paddingBottom: space["3xl"],
  },
  headerRow: {
    alignItems: "center",
    paddingTop: space.md,
    paddingBottom: space.md,
    marginBottom: space.xl,
  },
  title: {
    ...Typography.screenTitle,
    color: colors.text,
  },
  segmentWrap: {
    flexDirection: "row",
    backgroundColor: colors.surface,
    borderRadius: radius.md,
    padding: 4,
    marginBottom: space.md,
    ...Shadows.xs,
  },
  segment: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    minHeight: 36,
    borderRadius: radius.sm,
  },
  segmentActive: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    minHeight: 36,
    borderRadius: radius.sm,
    backgroundColor: colors.primary,
  },
  segmentText: {
    ...Typography.bodySm,
    color: colors.textMuted,
  },
  segmentActiveText: {
    ...Typography.bodySm,
    color: colors.textInverse,
    fontFamily: Fonts.bold,
  },
  chartCard: {
    marginBottom: space.md,
    overflow: "visible",
    zIndex: 2,
    elevation: 2,
  },
  chartWrap: {
    alignItems: "center",
    marginTop: space.md,
    paddingTop: 28,
    minHeight: 236,
    overflow: "visible",
    zIndex: 1,
    elevation: 1,
    position: "relative",
  },
  chartHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    alignSelf: "stretch",
    zIndex: 5,
    elevation: 5,
  },
  chartHeaderMenuOpen: {
    zIndex: 10,
    elevation: 10,
  },
  rangeControl: {
    position: "relative",
    zIndex: 2,
  },
  rangePill: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: space.md,
    paddingVertical: 6,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.pill,
  },
  rangeMenu: {
    position: "absolute",
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
  chartLabel: {
    ...Typography.caption,
    color: colors.textSubtle,
    textAlign: "center",
  },
  chartYAxisLabel: {
    ...Typography.caption,
    color: colors.textSubtle,
  },
  chartTooltip: {
    width: 128,
    minHeight: 56,
    paddingHorizontal: space.sm,
    paddingVertical: 6,
    backgroundColor: colors.text,
    borderRadius: radius.xs,
    alignItems: "center",
    justifyContent: "center",
    ...Shadows.md,
  },
  chartTooltipOverlay: {
    position: "absolute",
    top: 44,
    left: 0,
    right: 0,
    zIndex: 10,
    elevation: 10,
  },
  chartTooltipOverlayLeft: {
    alignItems: "flex-start",
    paddingLeft: 52,
  },
  chartTooltipOverlayCenter: {
    alignItems: "center",
  },
  chartTooltipOverlayRight: {
    alignItems: "flex-end",
    paddingRight: space.sm,
  },
  chartTooltipLabel: {
    ...Typography.caption,
    color: colors.textInverse,
    fontFamily: Fonts.medium,
  },
  chartTooltipValue: {
    ...Typography.bodySm,
    color: colors.textInverse,
    fontFamily: Fonts.semibold,
    marginTop: 2,
  },
  legendRow: {
    flexDirection: "row",
    alignItems: "center",
  },
  statRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: space.md,
  },
  statLeft: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  statBody: {
    marginLeft: space.md,
    flex: 1,
  },
  statLabel: {
    ...Typography.bodyMedium,
    color: colors.text,
  },
  statAmount: {
    ...Typography.subtitle,
    color: colors.text,
  },
  donutCard: {
    marginBottom: space.md,
  },
  donutHeader: {
    alignItems: "center",
  },
  donutLabel: {
    ...Typography.bodyMedium,
    color: colors.textMuted,
  },
  donutWrap: {
    alignItems: "center",
    marginTop: space.lg,
    minHeight: 200,
    justifyContent: "center",
  },
  donutCenter: {
    alignItems: "center",
  },
  donutCenterSmall: {
    ...Typography.caption,
    color: colors.textMuted,
  },
  donutCenterBig: {
    ...Typography.titleLg,
    color: colors.text,
  },
  emptyChartState: {
    width: "100%",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: space.sm,
    paddingBottom: space.sm,
  },
  emptyChartGraphic: {
    width: 112,
    height: 92,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: space.md,
  },
  emptyChartBars: {
    position: "absolute",
    left: 8,
    right: 8,
    bottom: 14,
    height: 58,
    flexDirection: "row",
    alignItems: "flex-end",
    justifyContent: "center",
    gap: 7,
  },
  emptyBar: {
    width: 16,
    borderRadius: radius.pill,
    borderWidth: 3,
    borderColor: colors.surface,
  },
  emptyBarIncome: {
    height: 42,
    backgroundColor: colors.primary,
  },
  emptyBarExpense: {
    height: 30,
    backgroundColor: colors.accentDark,
  },
  emptyBarMuted: {
    height: 50,
    backgroundColor: colors.primarySoftStrong,
  },
  emptyChartIcon: {
    width: 58,
    height: 58,
    borderRadius: 29,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.primarySoft,
    borderWidth: 6,
    borderColor: colors.surface,
    ...Shadows.xs,
  },
  emptyTitle: {
    ...Typography.bodyStrong,
    color: colors.text,
    textAlign: "center",
  },
  emptySubText: {
    ...Typography.bodySm,
    color: colors.textSubtle,
    maxWidth: 274,
    marginTop: space.xs,
    textAlign: "center",
  },
  emptyMetricRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    flexWrap: "wrap",
    marginTop: space.md,
  },
  emptyMetricChip: {
    flexDirection: "row",
    alignItems: "center",
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
  emptyInlineState: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: space.lg,
    paddingTop: space.md,
    paddingBottom: space.lg,
  },
  emptyInlineIcon: {
    width: 46,
    height: 46,
    borderRadius: radius.sm,
    alignItems: "center",
    justifyContent: "center",
    marginRight: space.md,
    backgroundColor: colors.surfaceSoft,
  },
  emptyInlineCopy: {
    flex: 1,
  },
  emptyInlineTitle: {
    ...Typography.bodyStrong,
    color: colors.text,
  },
  emptyInlineSub: {
    ...Typography.bodySm,
    color: colors.textSubtle,
    marginTop: 2,
  },
  emptyTrendSummaryCard: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: space.md,
  },
  emptyDetailState: {
    alignItems: "center",
    paddingHorizontal: space.lg,
    paddingVertical: space["2xl"],
  },
  catRow: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.surface,
    borderRadius: radius.md,
    padding: space.md,
    marginBottom: space.sm,
    ...Shadows.xs,
  },
  historyCard: {
    overflow: "hidden",
  },
  historyHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: space.lg,
    paddingTop: space.lg,
    paddingBottom: space.sm,
  },
  historyDay: {
    ...Typography.bodyStrong,
    color: colors.text,
  },
  historyTotal: {
    ...Typography.bodyStrong,
    color: colors.accentDark,
  },
  historyRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: space.lg,
    paddingVertical: space.md,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
  },
  catBody: {
    flex: 1,
    marginLeft: space.md,
  },
  catTitle: {
    ...Typography.bodyMedium,
    color: colors.text,
  },
  catShare: {
    ...Typography.caption,
    color: colors.textSubtle,
  },
  catAmount: {
    ...Typography.bodyMedium,
    color: colors.text,
    marginLeft: space.sm,
  },
  trendSummaryCard: {
    marginBottom: space.md,
  },
  trendSummaryHeader: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: space.md,
  },
  trendSummaryBody: {
    marginLeft: space.md,
    flex: 1,
  },
  trendSummaryLabel: {
    ...Typography.caption,
    color: colors.textSubtle,
  },
  trendSummaryValue: {
    ...Typography.title,
    color: colors.text,
  },
  trendMetricRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingTop: space.sm,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
    marginTop: space.sm,
  },
  trendMetricLabel: {
    ...Typography.caption,
    color: colors.textSubtle,
    flex: 1,
  },
  trendMetricValue: {
    ...Typography.bodySm,
    fontFamily: Fonts.semibold,
    color: colors.text,
    textAlign: "right",
    flex: 1.2,
  },
  trendListCard: {
    overflow: "hidden",
  },
  trendRow: {
    paddingHorizontal: space.lg,
    paddingVertical: space.md,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
  },
  trendRowHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: space.sm,
  },
  trendRowTitle: {
    ...Typography.bodyMedium,
    color: colors.text,
  },
  trendRowNet: {
    ...Typography.bodyMedium,
    color: colors.text,
  },
  trendBars: {
    gap: 8,
  },
  trendBarRow: {
    flexDirection: "row",
    alignItems: "center",
  },
  trendBarLabel: {
    ...Typography.caption,
    color: colors.textSubtle,
    width: 58,
  },
  trendBarTrack: {
    flex: 1,
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceMuted,
    overflow: "hidden",
  },
  trendBarFill: {
    height: "100%",
    borderRadius: radius.pill,
  },
  trendBarAmount: {
    ...Typography.caption,
    color: colors.textSubtle,
    width: 72,
    textAlign: "right",
  },
  bottomSpacer: {
    height: 128,
  },
});

const makeLegendStyles = (colors: ColorPalette) =>
  StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
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

const makeSkeletonStyles = (_colors: ColorPalette) =>
  StyleSheet.create({
  chartFrame: {
    width: "100%",
    height: 210,
    justifyContent: "flex-end",
    paddingHorizontal: space.lg,
    paddingBottom: space.md,
    position: "relative",
  },
  chartRule: {
    position: "absolute",
    left: space.lg,
    right: space.lg,
  },
  barRow: {
    height: 172,
    flexDirection: "row",
    alignItems: "flex-end",
    justifyContent: "space-between",
    paddingLeft: 44,
  },
  barPair: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 2,
  },
  sectionHeader: {
    marginTop: space.sm,
    marginBottom: space.sm,
  },
  subline: {
    marginTop: 6,
  },
  trendMetric: {
    marginTop: space.sm,
  },
  trendBar: {
    marginTop: 8,
  },
  legendLabel: {
    marginLeft: 4,
  },
});
