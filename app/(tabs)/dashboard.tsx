import React, { useCallback, useEffect, useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
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

const api = new APIService();

interface Txn {
  _id?: string;
  type?: "income" | "expense";
  title?: string;
  category?: string;
  sub_category?: string;
  date?: string;
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

  useEffect(() => {
    (async () => {
      const cached = await AsyncStorage.getItem("wealthify_user");
      if (cached) dispatch(getUserData(JSON.parse(cached)));
    })();
  }, []);

  const loadStats = useCallback(() => {
    api
      .getStats()
      .then((res) => {
        if (res.data?.response) setStats(res.data.response);
      })
      .catch(() => {});
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
          recent.map((t, idx) => <TxnRow key={t._id || idx} txn={t} />)
        )}

        <View style={styles.bottomSpacer} />
      </ScrollView>
    </ScreenContainer>
  );
}

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

const TxnRow: React.FC<{ txn: Txn }> = ({ txn }) => {
  const isIncome = txn.type === "income";
  const sign = isIncome ? "+" : "-";
  const amountColor = isIncome ? Colors.accentDark : Colors.negative;
  const label = txn.title || txn.category || "Untitled";
  const icon = resolveCategoryIcon(txn.category, txn.type);

  return (
    <View style={txnStyles.row}>
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
    </View>
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
    fontFamily: Fonts.medium,
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
