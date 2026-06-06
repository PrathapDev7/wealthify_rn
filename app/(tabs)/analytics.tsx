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
  Colors,
  Fonts,
  Shadows,
  Typography,
  noWebOutline,
  radius,
  space,
} from "@/src/styles/theme";
import { formatNumberWithCommas } from "@/src/utils/helper";
import { resolveCategoryIcon } from "@/src/utils/categoryIcon";

const api = new APIService();

interface Txn {
  type?: "income" | "expense";
  title?: string;
  category?: string;
  date?: string;
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
  let previousStart = start.clone().subtract(1, "day");
  let previousEnd = end.clone().subtract(1, "day");

  if (key === "yesterday") {
    start = today.clone().subtract(1, "day").startOf("day");
    end = today.clone().subtract(1, "day").endOf("day");
    previousStart = start.clone().subtract(1, "day");
    previousEnd = end.clone().subtract(1, "day");
  } else if (key === "last3Days") {
    start = today.clone().subtract(2, "days").startOf("day");
    end = today.clone().endOf("day");
    previousStart = start.clone().subtract(3, "days");
    previousEnd = end.clone().subtract(3, "days");
  } else if (key === "thisWeek") {
    start = today.clone().startOf("isoWeek");
    end = today.clone().endOf("isoWeek");
    previousStart = start.clone().subtract(1, "week");
    previousEnd = end.clone().subtract(1, "week");
  } else if (key === "thisMonth") {
    start = today.clone().startOf("month");
    end = today.clone().endOf("month");
    previousStart = start.clone().subtract(1, "month").startOf("month");
    previousEnd = start.clone().subtract(1, "month").endOf("month");
  } else if (key === "thisYear") {
    start = today.clone().startOf("year");
    end = today.clone().endOf("year");
    previousStart = start.clone().subtract(1, "year");
    previousEnd = end.clone().subtract(1, "year");
  }

  return { start, end, previousStart, previousEnd };
};

const readTransactions = (res: any, collectionKey: "incomes" | "expenses") =>
  Array.isArray(res.data) ? res.data : res.data?.[collectionKey] || [];

const isTxnInRange = (txn: Txn, start: moment.Moment, end: moment.Moment) => {
  const date = moment(txn.date);
  return date.isValid() && date.isBetween(start, end, undefined, "[]");
};

const sumTransactions = (list: Txn[]) =>
  list.reduce((total, txn) => total + Number(txn.amount || 0), 0);

export default function AnalyticsScreen() {
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
  const [previousIncomes, setPreviousIncomes] = useState<Txn[]>([]);
  const [previousExpenses, setPreviousExpenses] = useState<Txn[]>([]);

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

  const load = useCallback(() => {
    const range = {
      start_date: rangeConfig.start.format("YYYY-MM-DD"),
      end_date: rangeConfig.end.format("YYYY-MM-DD"),
    };
    const previousRange = {
      start_date: rangeConfig.previousStart.format("YYYY-MM-DD"),
      end_date: rangeConfig.previousEnd.format("YYYY-MM-DD"),
    };

    api
      .getIncomes(range)
      .then((res) => {
        const list = readTransactions(res, "incomes");
        setIncomes(list.map((t: Txn) => ({ ...t, type: "income" })));
      })
      .catch(() => {});
    api
      .getExpenses(range)
      .then((res) => {
        const list = readTransactions(res, "expenses");
        setExpenses(list.map((t: Txn) => ({ ...t, type: "expense" })));
      })
      .catch(() => {});
    api
      .getIncomes(previousRange)
      .then((res) => {
        const list = readTransactions(res, "incomes");
        setPreviousIncomes(list.map((t: Txn) => ({ ...t, type: "income" })));
      })
      .catch(() => {});
    api
      .getExpenses(previousRange)
      .then((res) => {
        const list = readTransactions(res, "expenses");
        setPreviousExpenses(list.map((t: Txn) => ({ ...t, type: "expense" })));
      })
      .catch(() => {});
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
  const chartPlotWidth = chartWidth - chartYAxisLabelWidth;
  const chartLabelWidth =
    selectedRangeKey === "thisMonth"
      ? 56
      : selectedRangeKey === "thisYear"
        ? 52
        : hasManyLabels
          ? 48
          : 40;
  const chartGroupWidth = chartBarWidth * 2 + 2;
  const chartEdgeSpacing = Math.max(8, (chartLabelWidth - chartGroupWidth) / 2);
  const distributedGroupSpacing =
    chartBucketCount > 1 && chartBucketCount <= 3
      ? Math.max(
          14,
          (chartPlotWidth -
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
      ? Math.max(10, (chartPlotWidth - chartGroupWidth) / 2)
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
  const comparisonIncomes = useMemo(
    () =>
      previousIncomes.filter((txn) =>
        isTxnInRange(txn, rangeConfig.previousStart, rangeConfig.previousEnd),
      ),
    [previousIncomes, rangeConfig],
  );
  const comparisonExpenses = useMemo(
    () =>
      previousExpenses.filter((txn) =>
        isTxnInRange(txn, rangeConfig.previousStart, rangeConfig.previousEnd),
      ),
    [previousExpenses, rangeConfig],
  );

  const barData = useMemo(() => {
    const getBucketKey = (date?: string) => {
      const m = moment(date);
      if (!m.isValid()) return "";
      if (selectedRangeKey === "thisYear") return m.format("YYYY-MM");
      return m.format("YYYY-MM-DD");
    };
    const sumByBucket = (list: Txn[]) =>
      list.reduce<Record<string, number>>((acc, t) => {
        const k = getBucketKey(t.date);
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
        frontColor: Colors.primary,
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
        frontColor: Colors.accentDark,
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
  ]);
  const chartTooltipPlacement = useMemo(() => {
    if (!selectedChartItem || barData.length <= 2)
      return styles.chartTooltipOverlayCenter;
    if (selectedChartItem.index <= 1) return styles.chartTooltipOverlayLeft;
    if (selectedChartItem.index >= barData.length - 2)
      return styles.chartTooltipOverlayRight;
    return styles.chartTooltipOverlayCenter;
  }, [barData.length, selectedChartItem]);

  const totalIncome = useMemo(
    () => sumTransactions(currentIncomes),
    [currentIncomes],
  );
  const previousIncome = useMemo(
    () => sumTransactions(comparisonIncomes),
    [comparisonIncomes],
  );
  const totalExpense = useMemo(
    () => sumTransactions(currentExpenses),
    [currentExpenses],
  );
  const previousExpense = useMemo(
    () => sumTransactions(comparisonExpenses),
    [comparisonExpenses],
  );
  const historyBalance = totalIncome - totalExpense;
  const historySign = historyBalance >= 0 ? "+" : "-";
  const historyAmountColor =
    historyBalance >= 0 ? Colors.accentDark : Colors.negative;
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
    const getBucketKey = (date?: string) => {
      const m = moment(date);
      if (!m.isValid()) return "";
      if (selectedRangeKey === "thisYear") return m.format("YYYY-MM");
      return m.format("YYYY-MM-DD");
    };
    const sumByBucket = (list: Txn[]) =>
      list.reduce<Record<string, number>>((acc, t) => {
        const k = getBucketKey(t.date);
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
              <Legend dot={Colors.primary} label="Income" />
              <Legend dot={Colors.accentDark} label="Expense" />
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
                rulesColor={Colors.divider}
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
              <EmptyAnalyticsChartState rangeLabel={emptyRangeLabel} />
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
                  color={Colors.accentDark}
                  bg={Colors.accentSoft}
                  size={40}
                  rounded="circle"
                  elevated={false}
                />
                <View style={styles.statBody}>
                  <Text style={styles.statLabel}>Income</Text>
                  <DeltaText
                    delta={totalIncome - previousIncome}
                    positiveGood
                  />
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
                  color={Colors.negative}
                  bg={Colors.negativeSoft}
                  size={40}
                  rounded="circle"
                  elevated={false}
                />
                <View style={styles.statBody}>
                  <Text style={styles.statLabel}>Expense</Text>
                  <DeltaText
                    delta={totalExpense - previousExpense}
                    positiveGood={false}
                  />
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
                <EmptyHistoryState rangeLabel={emptyRangeLabel} />
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
                    color={netMovement >= 0 ? Colors.accentDark : Colors.negative}
                    bg={
                      netMovement >= 0 ? Colors.accentSoft : Colors.negativeSoft
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
                              ? Colors.accentDark
                              : Colors.negative,
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
              <EmptyTrendSummaryState rangeLabel={emptyRangeLabel} />
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
                                ? Colors.accentDark
                                : Colors.negative,
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
                        color={Colors.primary}
                      />
                      <TrendBar
                        label="Expense"
                        value={row.expense}
                        max={maxTrendAmount}
                        color={Colors.accentDark}
                      />
                    </View>
                  </View>
                ))
              ) : (
                <EmptyTrendDetailState rangeLabel={emptyRangeLabel} />
              )}
            </Card>
          </>
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

const EmptyMetricChip: React.FC<{ dot: string; label: string }> = ({
  dot,
  label,
}) => (
  <View style={styles.emptyMetricChip}>
    <View style={[styles.emptyMetricDot, { backgroundColor: dot }]} />
    <Text style={styles.emptyMetricText}>{label}</Text>
  </View>
);

const EmptyAnalyticsChartState: React.FC<{ rangeLabel: string }> = ({
  rangeLabel,
}) => (
  <View style={styles.emptyChartState}>
    <View style={styles.emptyChartGraphic}>
      <View style={styles.emptyChartBars}>
        <View style={[styles.emptyBar, styles.emptyBarIncome]} />
        <View style={[styles.emptyBar, styles.emptyBarExpense]} />
        <View style={[styles.emptyBar, styles.emptyBarMuted]} />
      </View>
      <View style={styles.emptyChartIcon}>
        <Icon name="analytics-outline" size={26} color={Colors.primary} />
      </View>
    </View>
    <Text style={styles.emptyTitle}>No analytics yet</Text>
    <Text style={styles.emptySubText}>
      Add income or expenses for {rangeLabel} to see your cash flow here.
    </Text>
    <View style={styles.emptyMetricRow}>
      <EmptyMetricChip dot={Colors.primary} label="Income ₹0" />
      <EmptyMetricChip dot={Colors.accentDark} label="Expense ₹0" />
    </View>
  </View>
);

const EmptyHistoryState: React.FC<{ rangeLabel: string }> = ({ rangeLabel }) => (
  <View style={styles.emptyInlineState}>
    <View style={styles.emptyInlineIcon}>
      <Icon name="file-tray-outline" size={24} color={Colors.textSubtle} />
    </View>
    <View style={styles.emptyInlineCopy}>
      <Text style={styles.emptyInlineTitle}>No history yet</Text>
      <Text style={styles.emptyInlineSub}>
        Categories from {rangeLabel} will appear here.
      </Text>
    </View>
  </View>
);

const EmptyTrendSummaryState: React.FC<{ rangeLabel: string }> = ({
  rangeLabel,
}) => (
  <Card style={styles.emptyTrendSummaryCard}>
    <View style={styles.emptyInlineIcon}>
      <Icon name="trending-up-outline" size={24} color={Colors.primary} />
    </View>
    <View style={styles.emptyInlineCopy}>
      <Text style={styles.emptyInlineTitle}>No movement yet</Text>
      <Text style={styles.emptyInlineSub}>
        Trends for {rangeLabel} will unlock after your first entry.
      </Text>
    </View>
  </Card>
);

const EmptyTrendDetailState: React.FC<{ rangeLabel: string }> = ({
  rangeLabel,
}) => (
  <View style={styles.emptyDetailState}>
    <Icon name="stats-chart-outline" size={26} color={Colors.textSubtle} />
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
}> = ({ label, value, max, color }) => {
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

const DeltaText: React.FC<{ delta: number; positiveGood: boolean }> = ({
  delta,
  positiveGood,
}) => {
  if (delta === 0) {
    return <Text style={Typography.caption}>same as previous period</Text>;
  }
  const isPositive = delta > 0;
  const isGood = isPositive === positiveGood;
  return (
    <Text
      style={[
        Typography.caption,
        { color: isGood ? Colors.accentDark : Colors.negative },
      ]}
    >
      {isPositive ? "+" : ""}₹
      {formatNumberWithCommas(Math.abs(delta).toFixed(2))} vs previous period
    </Text>
  );
};

const styles = StyleSheet.create({
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
  },
  segmentWrap: {
    flexDirection: "row",
    backgroundColor: Colors.surface,
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
    backgroundColor: Colors.primary,
  },
  segmentText: {
    ...Typography.bodySm,
    color: Colors.textMuted,
  },
  segmentActiveText: {
    ...Typography.bodySm,
    color: Colors.textInverse,
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
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: radius.pill,
  },
  rangeMenu: {
    position: "absolute",
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
  chartLabel: {
    ...Typography.caption,
    color: Colors.textSubtle,
    textAlign: "center",
  },
  chartYAxisLabel: {
    ...Typography.caption,
    color: Colors.textSubtle,
  },
  chartTooltip: {
    width: 128,
    minHeight: 56,
    paddingHorizontal: space.sm,
    paddingVertical: 6,
    backgroundColor: Colors.text,
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
    color: Colors.textInverse,
    fontFamily: Fonts.medium,
  },
  chartTooltipValue: {
    ...Typography.bodySm,
    color: Colors.textInverse,
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
  },
  statAmount: {
    ...Typography.subtitle,
  },
  donutCard: {
    marginBottom: space.md,
  },
  donutHeader: {
    alignItems: "center",
  },
  donutLabel: {
    ...Typography.bodyMedium,
    color: Colors.textMuted,
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
    color: Colors.textMuted,
  },
  donutCenterBig: {
    ...Typography.titleLg,
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
    borderColor: Colors.surface,
  },
  emptyBarIncome: {
    height: 42,
    backgroundColor: Colors.primary,
  },
  emptyBarExpense: {
    height: 30,
    backgroundColor: Colors.accentDark,
  },
  emptyBarMuted: {
    height: 50,
    backgroundColor: Colors.primarySoftStrong,
  },
  emptyChartIcon: {
    width: 58,
    height: 58,
    borderRadius: 29,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: Colors.primarySoft,
    borderWidth: 6,
    borderColor: Colors.surface,
    ...Shadows.xs,
  },
  emptyTitle: {
    ...Typography.bodyStrong,
    textAlign: "center",
  },
  emptySubText: {
    ...Typography.bodySm,
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
    backgroundColor: Colors.surfaceSoft,
  },
  emptyInlineCopy: {
    flex: 1,
  },
  emptyInlineTitle: {
    ...Typography.bodyStrong,
  },
  emptyInlineSub: {
    ...Typography.bodySm,
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
    backgroundColor: Colors.surface,
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
  },
  historyTotal: {
    ...Typography.bodyStrong,
    color: Colors.accentDark,
  },
  historyRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: space.lg,
    paddingVertical: space.md,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
  },
  catBody: {
    flex: 1,
    marginLeft: space.md,
  },
  catTitle: {
    ...Typography.bodyMedium,
  },
  catShare: {
    ...Typography.caption,
  },
  catAmount: {
    ...Typography.bodyMedium,
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
  },
  trendSummaryValue: {
    ...Typography.title,
  },
  trendMetricRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingTop: space.sm,
    borderTopWidth: 1,
    borderTopColor: Colors.divider,
    marginTop: space.sm,
  },
  trendMetricLabel: {
    ...Typography.caption,
    flex: 1,
  },
  trendMetricValue: {
    ...Typography.bodySm,
    fontFamily: Fonts.semibold,
    color: Colors.text,
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
    borderTopColor: Colors.divider,
  },
  trendRowHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: space.sm,
  },
  trendRowTitle: {
    ...Typography.bodyMedium,
  },
  trendRowNet: {
    ...Typography.bodyMedium,
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
    width: 58,
  },
  trendBarTrack: {
    flex: 1,
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: Colors.surfaceMuted,
    overflow: "hidden",
  },
  trendBarFill: {
    height: "100%",
    borderRadius: radius.pill,
  },
  trendBarAmount: {
    ...Typography.caption,
    width: 72,
    textAlign: "right",
  },
  bottomSpacer: {
    height: 128,
  },
});

const legendStyles = StyleSheet.create({
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
  },
});
