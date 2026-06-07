import React, { useCallback, useEffect, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import Icon from "react-native-vector-icons/Ionicons";
import { useFocusEffect, useRouter } from "expo-router";
import { useDispatch } from "react-redux";
import AsyncStorage from "@react-native-async-storage/async-storage";
import moment from "moment";
import { Bell, Settings } from "lucide-react-native";
import APIService from "@/src/ApiService/api.service";
import { getUserData } from "@/src/redux/Actions/UserActions";
import {
  Card,
  CircleIconButton,
  IconBadge,
  ScreenContainer,
  SectionHeader,
} from "@/src/components/ui";
import {
  Colors,
  Fonts,
  Shadows,
  Typography,
  radius,
  space,
} from "@/src/styles/theme";
import { formatNumberWithCommas } from "@/src/utils/helper";
import { resolveCategoryIcon } from "@/src/utils/categoryIcon";
import SkeletonBlock from "@/src/components/skeletons/SkeletonBlock";

const api = new APIService();

interface Txn {
  _id?: string;
  type?: "income" | "expense" | string;
  title?: string;
  category?: string;
  sub_category?: string;
  date?: string;
  description?: string;
  createdAt?: string;
  updatedAt?: string;
  amount?: number;
}

export default function DashboardScreen() {
  const router = useRouter();
  const dispatch: any = useDispatch();

  const [stats, setStats] = useState<{
    allData: Txn[];
    total_incomes: number;
    total_expenses: number;
  }>({ allData: [], total_incomes: 0, total_expenses: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const cached = await AsyncStorage.getItem("wealthify_user");
      if (cached) dispatch(getUserData(JSON.parse(cached)));
    })();
  }, []);

  const loadStats = useCallback(() => {
    setLoading(true);
    api
      .getStats()
      .then((res) => {
        if (res.data?.response) setStats(res.data.response);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadStats();
    }, [loadStats]),
  );

  const balance = (stats.total_incomes || 0) - (stats.total_expenses || 0);
  const monthlySpend = stats.total_expenses || 0;
  const recent = (stats.allData || []).slice(0, 6);
  const walletAmount = `${balance < 0 ? "-" : ""}₹${formatNumberWithCommas(Math.abs(balance).toFixed(2))}`;
  const isFirstRun =
    recent.length === 0 &&
    (stats.total_incomes || 0) === 0 &&
    (stats.total_expenses || 0) === 0;

  return (
    <ScreenContainer variant="wash" extendUnderStatusBar>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scroll}
      >
        {loading ? (
          <DashboardSkeleton />
        ) : (
          <>
        <View style={styles.topRow}>
          <CircleIconButton
            name="settings-outline"
            iconSize={20}
            icon={
              <Settings
                size={20}
                color={Colors.textSubtle}
                strokeWidth={2.25}
              />
            }
            onPress={() => router.push("/account")}
          />
          <View style={styles.datePill}>
            <Icon name="calendar-outline" size={16} color={Colors.text} />
            <Text style={styles.dateText}>
              {moment().format("ddd, DD MMM")}
            </Text>
          </View>
          <CircleIconButton
            name="notifications-outline"
            iconSize={20}
            icon={
              <Bell size={20} color={Colors.textSubtle} strokeWidth={2.25} />
            }
          />
        </View>

        <View style={styles.hero}>
          <Text style={styles.heroLabel}>This Month Spend</Text>
          <Text style={styles.heroValue}>
            ₹{formatNumberWithCommas(monthlySpend.toFixed(2))}
          </Text>
          <View style={styles.heroDelta}>
            <Icon
              name={balance >= 0 ? "trending-down" : "trending-up"}
              size={14}
              color={balance >= 0 ? Colors.accentDark : Colors.negative}
            />
            <Text style={styles.heroDeltaText}>
              {balance >= 0
                ? `You're under by ₹${formatNumberWithCommas(balance.toFixed(2))}`
                : `Over by ₹${formatNumberWithCommas(Math.abs(balance).toFixed(2))}`}
            </Text>
          </View>
        </View>

        <Card
          style={styles.walletCard}
          onPress={() => router.push(isFirstRun ? "/set-budget" : "/analytics")}
        >
          <View style={styles.walletLeft}>
            <IconBadge
              name="wallet"
              color={Colors.primary}
              bg={Colors.primarySoft}
              size={42}
              iconSize={26}
              rounded="circle"
              elevated={false}
            />
            <Text style={styles.walletLabel}>Spending Wallet</Text>
          </View>
          <View style={styles.walletRight}>
            <Text style={styles.walletAmount}>
              {isFirstRun ? "Set Budget" : walletAmount}
            </Text>
            <View style={styles.chevronBox}>
              <Icon
                name="chevron-forward"
                size={15}
                color={Colors.textSubtle}
              />
            </View>
          </View>
        </Card>

        <SectionHeader
          title="Recent Transactions"
          actionLabel="See All"
          onActionPress={() => router.push("/transactions")}
          style={styles.sectionHeader}
        />

        {recent.length === 0 ? (
          <FirstTransactionCard />
        ) : (
          recent.map((t, idx) => (
            <TxnRow
              key={t._id || idx}
              txn={t}
              onPress={() =>
                router.push({
                  pathname: "/transaction-detail",
                  params: getTransactionRouteParams(t),
                })
              }
            />
          ))
        )}

        <View style={styles.bottomSpacer} />
          </>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}

const DashboardSkeleton = () => (
  <>
    <View style={styles.topRow}>
      <SkeletonBlock width={42} height={42} radius={21} />
      <SkeletonBlock width={124} height={34} radius={17} />
      <SkeletonBlock width={42} height={42} radius={21} />
    </View>

    <View style={styles.hero}>
      <SkeletonBlock width={116} height={16} radius={8} style={skeletonStyles.centered} />
      <SkeletonBlock width={184} height={46} radius={12} style={skeletonStyles.heroValue} />
      <SkeletonBlock width={238} height={18} radius={9} style={skeletonStyles.centered} />
    </View>

    <Card style={styles.walletCard}>
      <View style={styles.walletLeft}>
        <SkeletonBlock width={42} height={42} radius={21} />
        <SkeletonBlock width={132} height={18} radius={9} style={skeletonStyles.walletLabel} />
      </View>
      <View style={styles.walletRight}>
        <SkeletonBlock width={96} height={18} radius={9} />
        <SkeletonBlock width={18} height={18} radius={9} style={skeletonStyles.chevron} />
      </View>
    </Card>

    <View style={[styles.sectionHeader, skeletonStyles.sectionHeader]}>
      <SkeletonBlock width={154} height={20} radius={10} />
      <SkeletonBlock width={54} height={16} radius={8} />
    </View>

    {Array.from({ length: 6 }).map((_, index) => (
      <View key={index} style={txnStyles.row}>
        <SkeletonBlock width={44} height={44} radius={22} />
        <View style={txnStyles.middle}>
          <SkeletonBlock width={index % 2 ? 132 : 104} height={17} radius={8} />
          <SkeletonBlock width={82} height={13} radius={6} style={skeletonStyles.txnDate} />
        </View>
        <View style={txnStyles.right}>
          <SkeletonBlock width={78} height={17} radius={8} />
          <SkeletonBlock width={18} height={18} radius={9} style={skeletonStyles.chevron} />
        </View>
      </View>
    ))}

    <View style={styles.bottomSpacer} />
  </>
);

const FirstTransactionCard = () => (
  <Card elevation="sm" style={styles.emptyCard}>
    <View style={styles.emptyIconWrap}>
      <Icon name="receipt-outline" size={30} color={Colors.primary} />
    </View>
    <Text style={styles.emptyText}>Track your first transaction</Text>
    <Text style={styles.emptySub}>
      Add today's spending or income to make your wallet, budget, and analytics
      useful.
    </Text>
  </Card>
);

const getTransactionKind = (txn: Txn) =>
  txn.type === "income" ? "income" : "expense";

const getTransactionRouteParams = (txn: Txn) => {
  const transactionType = getTransactionKind(txn);

  return {
    id: txn._id || "",
    transactionType,
    title: txn.title || "",
    category: txn.category || "",
    subCategory: txn.sub_category || "",
    expenseType: transactionType === "expense" ? txn.type || "self" : "",
    date: txn.date || "",
    description: txn.description || "",
    amount: String(txn.amount || 0),
    createdAt: txn.createdAt || "",
    updatedAt: txn.updatedAt || "",
  };
};

const TxnRow: React.FC<{ txn: Txn; onPress?: () => void }> = ({
  txn,
  onPress,
}) => {
  const isIncome = txn.type === "income";
  const sign = isIncome ? "+" : "-";
  const amountColor = isIncome ? Colors.accentDark : Colors.negative;
  const label = txn.title || txn.category || "Untitled";
  const icon = resolveCategoryIcon(txn.category, isIncome ? "income" : "expense");

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={txnStyles.row}
    >
      <IconBadge
        name={icon.name}
        color={icon.color}
        bg={`${icon.color}1A`}
        size={44}
        iconSize={26}
        rounded="circle"
        elevated={false}
      />
      <View style={txnStyles.middle}>
        <Text style={txnStyles.title} numberOfLines={1}>
          {label}
        </Text>
        <Text style={txnStyles.date}>
          {txn.date ? moment(txn.date).format("DD MMM YYYY") : ""}
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
    </Pressable>
  );
};

const styles = StyleSheet.create({
  scroll: {
    paddingHorizontal: space.xl,
    paddingTop: space.lg,
    paddingBottom: space["3xl"],
  },
  topRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: space.lg,
  },
  datePill: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: space.md,
    paddingVertical: 8,
  },
  dateText: {
    ...Typography.bodyMedium,
    fontFamily: Fonts.medium,
    marginLeft: 6,
  },
  hero: {
    alignItems: "center",
    paddingVertical: space["2xl"],
  },
  heroLabel: {
    ...Typography.body,
    fontFamily: Fonts.medium,
    fontSize: Typography.body.fontSize - 2,
    color: Colors.textSubtle,
    marginBottom: space.xs,
  },
  heroValue: {
    ...Typography.displayLg,
    fontFamily: Fonts.semibold,
    letterSpacing: 1,
    marginBottom: space.sm,
  },
  heroDelta: {
    flexDirection: "row",
    alignItems: "center",
  },
  heroDeltaText: {
    ...Typography.bodySm,
    fontFamily: Fonts.medium,
    color: Colors.textMuted,
    marginLeft: 4,
  },
  walletCard: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginTop: space.md,
    paddingVertical: space.lg,
  },
  walletLeft: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
  },
  walletLabel: {
    ...Typography.subtitle,
    fontFamily: Fonts.semibold,
    fontSize: 14,
    marginLeft: space.md,
  },
  walletRight: {
    flexDirection: "row",
    alignItems: "center",
  },
  walletAmount: {
    ...Typography.subtitle,
    fontFamily: Fonts.semibold,
    fontSize: 14,
    marginRight: space.sm,
  },
  chevronBox: {
    width: 18,
    height: 18,
    alignItems: "center",
    justifyContent: "center",
  },
  sectionHeader: {
    marginTop: space.lg,
  },
  emptyCard: {
    alignItems: "center",
    paddingVertical: space["2xl"],
    paddingHorizontal: space.lg,
  },
  emptyIconWrap: {
    width: 58,
    height: 58,
    borderRadius: radius.full,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: Colors.primarySoft,
  },
  emptyText: {
    ...Typography.subtitle,
    fontFamily: Fonts.semibold,
    marginTop: space.lg,
    textAlign: "center",
  },
  emptySub: {
    ...Typography.bodySm,
    marginTop: space.sm,
    color: Colors.textSubtle,
    textAlign: "center",
    maxWidth: 300,
  },
  bottomSpacer: {
    height: 104,
  },
});

const txnStyles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: Colors.surface,
    borderRadius: radius.md,
    padding: space.md,
    marginBottom: space.sm,
    ...Shadows.xs,
  },
  middle: {
    flex: 1,
    marginLeft: space.md,
  },
  title: {
    ...Typography.bodyMedium,
    marginBottom: 2,
  },
  date: {
    ...Typography.caption,
  },
  right: {
    flexDirection: "row",
    alignItems: "center",
  },
  amount: {
    ...Typography.bodyMedium,
    marginRight: space.xs,
  },
  chevronBox: {
    width: 18,
    height: 18,
    alignItems: "center",
    justifyContent: "center",
  },
});

const skeletonStyles = StyleSheet.create({
  centered: {
    alignSelf: "center",
  },
  heroValue: {
    alignSelf: "center",
    marginVertical: space.sm,
  },
  walletLabel: {
    marginLeft: space.md,
  },
  chevron: {
    marginLeft: space.sm,
  },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: space.sm,
  },
  txnDate: {
    marginTop: 6,
  },
});
