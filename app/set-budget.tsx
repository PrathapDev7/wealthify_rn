import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Animated,
    KeyboardAvoidingView,
    Image,
    Platform,
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import Toast from 'react-native-toast-message';
import Icon from 'react-native-vector-icons/Ionicons';
import APIService from '@/src/ApiService/api.service';
import { formatAmountInput } from '@/src/utils/amount';
import {
    Card,
    CircleIconButton,
    NumericKeypad,
    PillButton,
    ScreenContainer,
} from '@/src/components/ui';
import {
    Colors,
    Fonts,
    Typography,
    space,
} from '@/src/styles/theme';
import { formatNumberWithCommas } from '@/src/utils/helper';
import { remoteImage } from '@/assets/Constants/remoteAssets';
import SkeletonBlock from '@/src/components/skeletons/SkeletonBlock';

const api = new APIService();
const PRESET_AMOUNTS = [5000, 10000, 25000, 50000];
const HEADER_SOLID = 'rgba(234, 224, 255, 1)';
const HEADER_CLEAR = 'rgba(234, 224, 255, 0)';
const budgetIcon = remoteImage('assets/icons/budget.png');

export default function SetBudgetScreen() {
    const router = useRouter();
    const params = useLocalSearchParams<{
        category?: string;
        resetAmount?: string;
        scrollToList?: string;
    }>();
    const category = params.category || '';
    const shouldResetAmount = params.resetAmount === '1';
    const scrollToListToken = params.scrollToList || '';
    const budgetKey = category || 'Overall';
    const scrollRef = useRef<ScrollView | null>(null);
    const lastRouteScrollToken = useRef('');
    const scrollY = useRef(new Animated.Value(0)).current;

    const [amount, setAmount] = useState('');
    const [totalIncome, setTotalIncome] = useState(0);
    const [totalExpenses, setTotalExpenses] = useState(0);
    const [totalBalance, setTotalBalance] = useState(0);
    const [loading, setLoading] = useState(false);
    const [loadingData, setLoadingData] = useState(true);
    const [budgetDocId, setBudgetDocId] = useState<string | null>(null);
    const [existingBudgets, setExistingBudgets] = useState<Record<string, number>>({});
    const [savedBudgetsY, setSavedBudgetsY] = useState<number | null>(null);
    const [pendingListScroll, setPendingListScroll] = useState(false);
    const hasSavedBudgetForCurrentKey =
        typeof existingBudgets[budgetKey] === 'number' && existingBudgets[budgetKey] > 0;
    const submitLabel = `${hasSavedBudgetForCurrentKey ? 'Update' : 'Save'} ${budgetKey} Budget`;
    const headerBackgroundColor = scrollY.interpolate({
        inputRange: [0, 56, 116],
        outputRange: [HEADER_CLEAR, 'rgba(234, 224, 255, 0.62)', HEADER_SOLID],
        extrapolate: 'clamp',
    });
    const headerShadeOpacity = scrollY.interpolate({
        inputRange: [0, 64, 116],
        outputRange: [0, 0.35, 1],
        extrapolate: 'clamp',
    });

    const existingBudgetEntries = useMemo(
        () => Object.entries(existingBudgets)
            .filter(([, value]) => typeof value === 'number' && value > 0)
            .sort(([a], [b]) => {
                if (a === budgetKey) return -1;
                if (b === budgetKey) return 1;
                if (a === 'Overall') return -1;
                if (b === 'Overall') return 1;
                return a.localeCompare(b);
            })
            .slice(0, 4),
        [budgetKey, existingBudgets],
    );

    useEffect(() => {
        let active = true;
        setLoadingData(true);
        Promise.all([loadBalance(), loadBudgets(true)])
            .finally(() => {
                if (active) setLoadingData(false);
            });

        return () => {
            active = false;
        };
    }, [budgetKey, shouldResetAmount]);

    useEffect(() => {
        const routeRequestedScroll =
            !!scrollToListToken && lastRouteScrollToken.current !== scrollToListToken;
        if (!routeRequestedScroll && !pendingListScroll) return;
        if (!existingBudgetEntries.length || savedBudgetsY === null) return;

        if (routeRequestedScroll) {
            lastRouteScrollToken.current = scrollToListToken;
        }
        setPendingListScroll(false);

        const timer = setTimeout(() => {
            scrollRef.current?.scrollTo({
                y: Math.max(savedBudgetsY - space.md, 0),
                animated: true,
            });
        }, 220);

        return () => clearTimeout(timer);
    }, [existingBudgetEntries.length, pendingListScroll, savedBudgetsY, scrollToListToken]);

    const loadBalance = () => {
        return api.getStats()
            .then((res) => {
                const stats = res.data?.response;
                if (stats) {
                    setTotalIncome(stats.total_incomes || 0);
                    setTotalExpenses(stats.total_expenses || 0);
                    const balance =
                        (stats.total_incomes || 0) - (stats.total_expenses || 0);
                    setTotalBalance(balance);
                }
            })
            .catch(() => {});
    };

    const loadBudgets = async (syncAmount = true) => {
        try {
            const res = await api.getBudgets();
            const doc = res.data?.response;
            if (doc?._id) {
                setBudgetDocId(doc._id);
                setExistingBudgets(doc.budgets || {});
                if (syncAmount) {
                    const existing = (doc.budgets || {})[budgetKey];
                    setAmount(typeof existing === 'number' ? existing.toString() : '');
                }
            } else if (syncAmount) {
                setAmount('');
            }
        } catch {
            // Keep the entered amount available if budgets fail to load.
        }
    };

    const onSave = async () => {
        if (!amount || Number(amount) <= 0) {
            return Toast.show({ type: 'error', text1: 'Enter an amount' });
        }
        // BE stores ONE budget document per user containing a `budgets` object
        // keyed by category. Merge the new entry into the existing object and
        // PUT if a doc exists, otherwise POST a new one.
        const mergedBudgets = { ...existingBudgets, [budgetKey]: Number(amount) };

        setLoading(true);
        try {
            const res = budgetDocId
                ? await api.updateBudgets(budgetDocId, { budgets: mergedBudgets })
                : await api.addBudgets({ budgets: mergedBudgets });
            if (res.data) {
                setExistingBudgets(mergedBudgets);
                await loadBudgets(false);
                Toast.show({ type: 'success', text1: 'Budget saved' });
                if (budgetKey !== 'Overall') {
                    router.replace({
                        pathname: '/set-budget',
                        params: { scrollToList: Date.now().toString() },
                    });
                } else {
                    setPendingListScroll(true);
                }
            }
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to save budget',
            });
        } finally {
            setLoading(false);
        }
    };
    const pushDigit = (digit: string) => {
        setAmount((prev) => {
            const next = `${prev}${digit}`.replace(/^0+(?=\d)/, '');
            return next.slice(0, 9);
        });
    };
    const popDigit = () => setAmount((prev) => prev.slice(0, -1));
    const applyPreset = (value: number) => setAmount(value.toString());
    const selectExistingBudget = (name: string, value: number) => {
        setAmount(value.toString());
        if (name === 'Overall') {
            router.replace('/set-budget');
            return;
        }
        router.replace({
            pathname: '/set-budget',
            params: { category: name },
        });
    };
    const pickBudgetCategory = () => {
        router.replace({
            pathname: '/select-category',
            params: {
                type: 'expense',
                returnTo: 'set-budget',
                currentCategory: category,
            },
        });
    };
    const formatMoney = (value: number) => `₹${formatNumberWithCommas(value.toFixed(2))}`;

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : undefined}
                style={styles.flex}
            >
                <Animated.View
                    style={[
                        styles.headerRow,
                        { backgroundColor: headerBackgroundColor },
                    ]}
                >
                    <CircleIconButton
                        name="chevron-back"
                        onPress={() => router.back()}
                    />
                    <Text style={styles.headerTitle}>Set Budget</Text>
                    <View style={{ width: 42 }} />
                    <Animated.View
                        pointerEvents="none"
                        style={[
                            styles.headerBottomShade,
                            { opacity: headerShadeOpacity },
                        ]}
                    />
                </Animated.View>

                <Animated.ScrollView
                    ref={scrollRef}
                    contentContainerStyle={styles.scroll}
                    keyboardShouldPersistTaps="handled"
                    showsVerticalScrollIndicator={false}
                    scrollEventThrottle={16}
                    onScroll={Animated.event(
                        [{ nativeEvent: { contentOffset: { y: scrollY } } }],
                        { useNativeDriver: false },
                    )}
                >
                    {loadingData ? (
                        <SetBudgetSkeleton />
                    ) : (
                        <>
                    <Card style={styles.balanceCard}>
                        <Image
                            source={budgetIcon}
                            style={styles.budgetIcon}
                            resizeMode="contain"
                        />
                        <View style={styles.balanceBody}>
                            <Text style={styles.balanceLabel}>
                                {category ? `${category} budget` : 'Overall budget'}
                            </Text>
                            <Text style={styles.balanceAmount}>
                                {formatMoney(totalBalance)}
                            </Text>
                        </View>
                        <View style={styles.balanceMeta}>
                            <Text style={styles.metaLabel}>Spent</Text>
                            <Text style={styles.metaValue}>{formatMoney(totalExpenses)}</Text>
                        </View>
                    </Card>

                    <Card style={styles.amountCard}>
                        <View style={styles.scopeRow}>
                            <Text style={styles.scopeLabel}>Budget For</Text>
                            <TouchableOpacity
                                activeOpacity={0.85}
                                onPress={pickBudgetCategory}
                                style={styles.scopeChip}
                            >
                                <Text numberOfLines={1} style={styles.scopeChipText}>{budgetKey}</Text>
                                <Icon name="chevron-down" size={15} color={Colors.primary} />
                            </TouchableOpacity>
                        </View>
                        <View style={styles.amountRow}>
                            <Text style={styles.currency}>₹</Text>
                            <Text style={styles.amountInput}>
                                {formatAmountInput(amount) || '0'}
                            </Text>
                        </View>
                        <Text style={styles.amountLabel}>Enter Amount</Text>

                        <View style={styles.quickSection}>
                            <Text style={styles.sectionLabel}>Quick Set</Text>
                            <View style={styles.presetGrid}>
                                {PRESET_AMOUNTS.map((preset) => (
                                    <TouchableOpacity
                                        key={preset}
                                        activeOpacity={0.85}
                                        onPress={() => applyPreset(preset)}
                                        style={[
                                            styles.presetChip,
                                            Number(amount) === preset && styles.presetChipActive,
                                        ]}
                                    >
                                        <Text
                                            style={[
                                                styles.presetText,
                                                Number(amount) === preset && styles.presetTextActive,
                                            ]}
                                        >
                                            ₹{formatNumberWithCommas(preset)}
                                        </Text>
                                    </TouchableOpacity>
                                ))}
                            </View>
                        </View>
                    </Card>

                    <View style={styles.statsRow}>
                        <View style={styles.statTile}>
                            <Text style={styles.statLabel}>Income</Text>
                            <Text style={styles.statValue}>{formatMoney(totalIncome)}</Text>
                        </View>
                        <View style={styles.statTile}>
                            <Text style={styles.statLabel}>Balance</Text>
                            <Text
                                style={[
                                    styles.statValue,
                                    totalBalance < 0 && styles.statValueNegative,
                                ]}
                            >
                                {formatMoney(totalBalance)}
                            </Text>
                        </View>
                    </View>

                    {existingBudgetEntries.length > 0 && (
                        <View
                            onLayout={(event) => setSavedBudgetsY(event.nativeEvent.layout.y)}
                        >
                            <Card style={styles.savedCard}>
                                <View style={styles.savedHeader}>
                                    <Text style={styles.savedTitle}>Saved Budgets</Text>
                                    <Text style={styles.savedCount}>
                                        {existingBudgetEntries.length}
                                    </Text>
                                </View>
                                <View style={styles.savedList}>
                                    {existingBudgetEntries.map(([name, value]) => (
                                        <TouchableOpacity
                                            key={name}
                                            activeOpacity={0.85}
                                            onPress={() => selectExistingBudget(name, value)}
                                            style={[
                                                styles.savedBudget,
                                                name === budgetKey && styles.savedBudgetActive,
                                            ]}
                                        >
                                            <Text
                                                numberOfLines={1}
                                                style={[
                                                    styles.savedName,
                                                    name === budgetKey && styles.savedNameActive,
                                                ]}
                                            >
                                                {name}
                                            </Text>
                                            <Text
                                                style={[
                                                    styles.savedAmount,
                                                    name === budgetKey && styles.savedAmountActive,
                                                ]}
                                            >
                                                ₹{formatNumberWithCommas(value)}
                                            </Text>
                                        </TouchableOpacity>
                                    ))}
                                </View>
                            </Card>
                        </View>
                    )}
                        </>
                    )}
                </Animated.ScrollView>

                <View style={styles.footer}>
                    <PillButton
                        label={submitLabel}
                        onPress={onSave}
                        loading={loading}
                        size="lg"
                    />
                </View>
                <NumericKeypad onDigit={pushDigit} onBackspace={popDigit} />
            </KeyboardAvoidingView>
        </ScreenContainer>
    );
}

const SetBudgetSkeleton = () => (
    <>
        <Card style={styles.balanceCard}>
            <SkeletonBlock width={50} height={50} radius={14} />
            <View style={styles.balanceBody}>
                <SkeletonBlock width={104} height={14} radius={7} />
                <SkeletonBlock width={132} height={20} radius={10} style={skeletonStyles.subline} />
            </View>
            <View style={styles.balanceMeta}>
                <SkeletonBlock width={42} height={12} radius={6} />
                <SkeletonBlock width={86} height={16} radius={8} style={skeletonStyles.subline} />
            </View>
        </Card>

        <Card style={styles.amountCard}>
            <View style={styles.scopeRow}>
                <SkeletonBlock width={78} height={14} radius={7} />
                <SkeletonBlock width={108} height={34} radius={17} />
            </View>
            <View style={styles.amountRow}>
                <SkeletonBlock width={126} height={54} radius={16} />
            </View>
            <SkeletonBlock width={92} height={14} radius={7} style={skeletonStyles.centered} />
            <View style={styles.quickSection}>
                <SkeletonBlock width={72} height={14} radius={7} />
                <View style={styles.presetGrid}>
                    {Array.from({ length: 4 }).map((_, index) => (
                        <SkeletonBlock
                            key={index}
                            width="48%"
                            height={42}
                            radius={21}
                            style={skeletonStyles.preset}
                        />
                    ))}
                </View>
            </View>
        </Card>

        <View style={styles.statsRow}>
            <View style={styles.statTile}>
                <SkeletonBlock width={58} height={13} radius={7} />
                <SkeletonBlock width={104} height={18} radius={9} style={skeletonStyles.subline} />
            </View>
            <View style={styles.statTile}>
                <SkeletonBlock width={64} height={13} radius={7} />
                <SkeletonBlock width={104} height={18} radius={9} style={skeletonStyles.subline} />
            </View>
        </View>

        <Card style={styles.savedCard}>
            <View style={styles.savedHeader}>
                <SkeletonBlock width={112} height={18} radius={9} />
                <SkeletonBlock width={24} height={24} radius={12} />
            </View>
            <View style={styles.savedList}>
                {Array.from({ length: 3 }).map((_, index) => (
                    <SkeletonBlock
                        key={index}
                        width="48%"
                        height={64}
                        radius={14}
                        style={skeletonStyles.savedBudget}
                    />
                ))}
            </View>
        </Card>
    </>
);

const styles = StyleSheet.create({
    flex: { flex: 1 },
    headerRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: space.xl,
        paddingTop: space.lg,
        paddingBottom: space.md,
        zIndex: 10,
        overflow: 'hidden',
    },
    headerTitle: {
        ...Typography.screenTitle,
    },
    headerBottomShade: {
        position: 'absolute',
        left: 0,
        right: 0,
        bottom: 0,
        height: 1,
        backgroundColor: 'rgba(123, 63, 242, 0.08)',
    },
    scroll: {
        paddingHorizontal: space.xl,
        paddingTop: space.xl,
        paddingBottom: space.lg,
        gap: space.lg,
    },
    balanceCard: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: space.lg,
    },
    budgetIcon: {
        width: 50,
        height: 50,
    },
    balanceBody: {
        marginLeft: space.md,
        flex: 1,
    },
    balanceLabel: {
        ...Typography.label,
    },
    balanceAmount: {
        ...Typography.subtitle,
        marginTop: 2,
    },
    balanceMeta: {
        alignItems: 'flex-end',
        marginLeft: space.md,
    },
    metaLabel: {
        ...Typography.caption,
    },
    metaValue: {
        ...Typography.moneySm,
        marginTop: 2,
    },
    amountCard: {
        alignItems: 'center',
        paddingVertical: space.xl,
    },
    scopeRow: {
        width: '100%',
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: space.md,
    },
    scopeLabel: {
        ...Typography.label,
    },
    scopeChip: {
        maxWidth: 180,
        paddingHorizontal: space.md,
        paddingVertical: 7,
        borderRadius: 999,
        backgroundColor: Colors.primarySoft,
        flexDirection: 'row',
        alignItems: 'center',
        gap: 3,
    },
    scopeChipText: {
        ...Typography.bodyStrong,
        color: Colors.primary,
        fontSize: 12,
        flexShrink: 1,
    },
    amountRow: {
        flexDirection: 'row',
        alignItems: 'center',
        minHeight: 62,
    },
    currency: {
        ...Typography.title,
        fontFamily: Fonts.semibold,
        color: Colors.textSubtle,
        marginRight: 4,
        lineHeight: 32,
        includeFontPadding: false,
    },
    amountInput: {
        ...Typography.displayLg,
        fontFamily: Fonts.semibold,
        fontSize: 42,
        lineHeight: 54,
        minWidth: 112,
        maxWidth: 260,
        textAlign: 'center',
        padding: 0,
        color: Colors.text,
        includeFontPadding: false,
    },
    amountLabel: {
        ...Typography.bodySm,
        marginTop: space.xs,
    },
    quickSection: {
        width: '100%',
        marginTop: space.xl,
    },
    sectionLabel: {
        ...Typography.label,
        marginBottom: space.sm,
    },
    presetGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: space.sm,
    },
    presetChip: {
        flexGrow: 1,
        flexBasis: '22%',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: 38,
        paddingHorizontal: space.sm,
        borderRadius: 999,
        backgroundColor: Colors.surfaceMuted,
        borderWidth: 1,
        borderColor: Colors.border,
    },
    presetChipActive: {
        backgroundColor: Colors.primary,
        borderColor: Colors.primary,
    },
    presetText: {
        ...Typography.bodyStrong,
        fontSize: 12,
        color: Colors.text,
    },
    presetTextActive: {
        color: Colors.textInverse,
    },
    statsRow: {
        flexDirection: 'row',
        gap: space.md,
    },
    statTile: {
        flex: 1,
        minHeight: 72,
        justifyContent: 'center',
        paddingHorizontal: space.lg,
        paddingVertical: space.md,
        borderRadius: 18,
        backgroundColor: Colors.surfaceLifted,
        borderWidth: 1,
        borderColor: Colors.divider,
    },
    statLabel: {
        ...Typography.caption,
        marginBottom: 4,
    },
    statValue: {
        ...Typography.moneySm,
    },
    statValueNegative: {
        color: Colors.negative,
    },
    savedCard: {
        paddingVertical: space.lg,
    },
    savedHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: space.md,
    },
    savedTitle: {
        ...Typography.subtitle,
    },
    savedCount: {
        ...Typography.caption,
        color: Colors.primary,
    },
    savedList: {
        gap: space.sm,
    },
    savedBudget: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        minHeight: 42,
        paddingHorizontal: space.md,
        borderRadius: 14,
        backgroundColor: Colors.surfaceSoft,
        borderWidth: 1,
        borderColor: Colors.border,
        gap: space.md,
    },
    savedBudgetActive: {
        backgroundColor: Colors.primarySoft,
        borderColor: Colors.primarySoftStrong,
    },
    savedName: {
        ...Typography.bodyMedium,
        flex: 1,
        color: Colors.textBody,
    },
    savedNameActive: {
        color: Colors.primary,
    },
    savedAmount: {
        ...Typography.moneySm,
    },
    savedAmountActive: {
        color: Colors.primary,
    },
    footer: {
        paddingHorizontal: space.xl,
        paddingTop: space.sm,
        paddingBottom: space.md,
        backgroundColor: 'transparent',
    },
});

const skeletonStyles = StyleSheet.create({
    subline: {
        marginTop: 6,
    },
    centered: {
        alignSelf: 'center',
    },
    preset: {
        flexGrow: 1,
        flexBasis: '48%',
    },
    savedBudget: {
        alignSelf: 'stretch',
    },
});
