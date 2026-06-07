import React, { useEffect, useMemo, useState } from 'react';
import {
    KeyboardAvoidingView,
    Platform,
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import moment from 'moment';
import Toast from 'react-native-toast-message';
import APIService from '@/src/ApiService/api.service';
import { formatAmountInput } from '@/src/utils/amount';
import { DEFAULT_CATEGORIES } from '@/src/utils/defaultCategories';
import {
    Chip,
    CircleIconButton,
    NumericKeypad,
    PillButton,
    ScreenContainer,
} from '@/src/components/ui';
import {
    Colors,
    Fonts,
    Shadows,
    Typography,
    radius,
    space,
} from '@/src/styles/theme';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';
import SkeletonBlock from '@/src/components/skeletons/SkeletonBlock';

type TxnType = 'expense' | 'income';

const api = new APIService();

interface CategoryOpt {
    title: string;
}

export default function AddTransactionScreen() {
    const router = useRouter();
    const params = useLocalSearchParams<{
        type?: TxnType;
        category?: string;
    }>();
    const routeType: TxnType = params.type === 'income' || params.type === 'expense'
        ? params.type
        : 'expense';

    const [type, setType] = useState<TxnType>(routeType);
    const [amount, setAmount] = useState('');
    const [category, setCategory] = useState<string>(params.category || '');
    const [categories, setCategories] = useState<CategoryOpt[]>([]);
    const [recentCategories, setRecentCategories] = useState<string[]>([]);
    const [loading, setLoading] = useState(false);
    const [categoriesLoading, setCategoriesLoading] = useState(true);

    useEffect(() => {
        loadCategories(type);
    }, [type]);

    useEffect(() => {
        setType((current) => {
            if (current === routeType) return current;
            setCategory('');
            setCategories([]);
            setRecentCategories([]);
            return routeType;
        });
    }, [routeType]);

    useEffect(() => {
        if (params.category && typeof params.category === 'string') {
            setCategory(params.category);
        }
    }, [params.category]);

    const changeType = (nextType: TxnType) => {
        if (nextType === type) return;
        setType(nextType);
        setCategory('');
        setCategories([]);
        setRecentCategories([]);
    };

    const loadCategories = (t: TxnType) => {
        setCategoriesLoading(true);
        Promise.all([
            api.getCategories(t),
            api.getRecentCategories(t),
        ])
            .then(([categoriesRes, recentRes]) => {
                setCategories(categoriesRes.data?.length ? categoriesRes.data : []);
                setRecentCategories(recentRes.data?.length
                    ? recentRes.data.map((item) => item.title).filter(Boolean)
                    : []);
            })
            .catch(() => {
                setCategories([]);
                setRecentCategories([]);
            })
            .finally(() => {
                setCategoriesLoading(false);
            });
    };

    const popularCategories = useMemo(() => {
        const beTitles = categories.map((c) => c.title);
        const fallback = DEFAULT_CATEGORIES[type] || [];
        const seen = new Set<string>();
        const source = recentCategories.length
            ? [...recentCategories, ...fallback, ...beTitles]
            : [...fallback, ...beTitles];
        const padded = source.filter((title) => {
            const key = title.toLowerCase();
            if (seen.has(key)) return false;
            seen.add(key);
            return true;
        });
        return padded.slice(0, 5).map((title) => ({ title }));
    }, [categories, recentCategories, type]);

    const onSubmit = async () => {
        if (!amount || Number(amount) <= 0) {
            return Toast.show({ type: 'error', text1: 'Enter an amount' });
        }
        if (!category) {
            return Toast.show({ type: 'error', text1: 'Select a category' });
        }
        const payload: any = {
            amount: Number(amount),
            category,
            description: '',
            date: moment().format('YYYY-MM-DD'),
        };
        if (type === 'expense') {
            payload.type = 'self';
        } else {
            // BE addIncome requires `title`; use the selected category.
            payload.title = category;
        }

        setLoading(true);
        try {
            const res =
                type === 'expense'
                    ? await api.addExpense(payload)
                    : await api.addIncome(payload);
            if (res.data) {
                Toast.show({
                    type: 'success',
                    text1: type === 'expense' ? 'Expense added' : 'Income added',
                });
                router.back();
            }
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to save',
            });
        } finally {
            setLoading(false);
        }
    };

    const goToCategoryPicker = () => {
        router.push({
            pathname: '/select-category',
            params: { type, returnTo: 'add-transaction' },
        });
    };

    const catIcon = category ? resolveCategoryIcon(category, type) : null;
    const submitLabel = `Save ${category ? `${category} ` : ''}${type === 'expense' ? 'Expense' : 'Income'}`;
    const pushDigit = (digit: string) => {
        setAmount((prev) => {
            const next = `${prev}${digit}`.replace(/^0+(?=\d)/, '');
            return next.slice(0, 9);
        });
    };
    const popDigit = () => setAmount((prev) => prev.slice(0, -1));

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : undefined}
                style={styles.flex}
            >
                <View style={styles.headerRow}>
                    <CircleIconButton
                        name="chevron-back"
                        onPress={() => router.back()}
                    />
                    <Text style={styles.headerTitle}>
                        {type === 'expense' ? 'Add Expense' : 'Add Income'}
                    </Text>
                    <View style={{ width: 40 }} />
                </View>

                <View style={styles.segmentWrap}>
                    <TouchableOpacity
                        activeOpacity={0.85}
                        onPress={() => changeType('expense')}
                        style={[
                            styles.segment,
                            type === 'expense' && styles.segmentActive,
                        ]}
                    >
                        <Text
                            style={[
                                styles.segmentText,
                                type === 'expense' && styles.segmentTextActive,
                            ]}
                        >
                            Expenses
                        </Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        activeOpacity={0.85}
                        onPress={() => changeType('income')}
                        style={[
                            styles.segment,
                            type === 'income' && styles.segmentActive,
                        ]}
                    >
                        <Text
                            style={[
                                styles.segmentText,
                                type === 'income' && styles.segmentTextActive,
                            ]}
                        >
                            Income
                        </Text>
                    </TouchableOpacity>
                </View>

                <ScrollView
                    style={styles.formScroll}
                    contentContainerStyle={styles.scroll}
                    keyboardShouldPersistTaps="handled"
                    showsVerticalScrollIndicator={false}
                >
                    <View style={styles.amountWrap}>
                        <View style={styles.amountRow}>
                            <Text style={styles.currency}>₹</Text>
                            <Text style={styles.amountInput}>
                                {formatAmountInput(amount) || '0'}
                            </Text>
                        </View>
                        <Text style={styles.amountLabel}>Enter Amount</Text>
                    </View>

                    <View style={styles.chipsBlock}>
                        <ScrollView
                            horizontal
                            showsHorizontalScrollIndicator={false}
                            contentContainerStyle={styles.chipsRow}
                        >
                            {categoriesLoading ? (
                                <ChipRowSkeleton />
                            ) : popularCategories.map((c) => {
                                const icon = resolveCategoryIcon(c.title, type);
                                return (
                                    <Chip
                                        key={c.title}
                                        label={c.title}
                                        iconName={icon.name}
                                        iconColor={icon.color}
                                        selected={category === c.title}
                                        onPress={() => setCategory(c.title)}
                                        style={styles.chip}
                                    />
                                );
                            })}
                            {!categoriesLoading && <Chip
                                label={category && !popularCategories.find(c => c.title === category) ? category : 'More'}
                                iconName={catIcon?.name || 'ellipsis-horizontal'}
                                iconColor={catIcon?.color || Colors.primary}
                                selected={!!category && !popularCategories.find(c => c.title === category)}
                                onPress={goToCategoryPicker}
                                style={styles.chip}
                            />}
                        </ScrollView>
                    </View>
                </ScrollView>

                <View style={styles.footer}>
                    <PillButton
                        label={submitLabel}
                        onPress={onSubmit}
                        loading={loading}
                        size="lg"
                    />
                </View>
                <NumericKeypad onDigit={pushDigit} onBackspace={popDigit} />
            </KeyboardAvoidingView>
        </ScreenContainer>
    );
}

const ChipRowSkeleton = () => (
    <>
        {[86, 96, 78, 104, 72, 68].map((width, index) => (
            <SkeletonBlock
                key={index}
                width={width}
                height={36}
                radius={18}
                style={styles.chip}
            />
        ))}
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
    },
    headerTitle: {
        ...Typography.screenTitle,
    },
    segmentWrap: {
        flexDirection: 'row',
        marginHorizontal: space.xl,
        marginTop: space.lg,
        backgroundColor: Colors.surface,
        padding: 4,
        borderRadius: radius.pill,
        ...Shadows.xs,
    },
    segment: {
        flex: 1,
        paddingVertical: 12,
        borderRadius: radius.pill,
        alignItems: 'center',
        justifyContent: 'center',
    },
    segmentActive: {
        backgroundColor: Colors.primary,
    },
    segmentText: {
        ...Typography.bodyMedium,
        color: Colors.textMuted,
    },
    segmentTextActive: {
        color: Colors.textInverse,
    },
    formScroll: {
        flex: 1,
    },
    scroll: {
        flexGrow: 1,
        paddingHorizontal: space.xl,
        paddingTop: space.md,
        paddingBottom: space.sm,
    },
    amountWrap: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
    amountRow: {
        flexDirection: 'row',
        alignItems: 'center',
        minHeight: 64,
    },
    currency: {
        ...Typography.title,
        color: Colors.textMuted,
        marginRight: 4,
        lineHeight: 32,
        includeFontPadding: false,
    },
    amountInput: {
        ...Typography.displayLg,
        fontFamily: Fonts.semibold,
        fontSize: 44,
        lineHeight: 56,
        maxWidth: 260,
        textAlign: 'center',
        padding: 0,
        color: Colors.text,
        includeFontPadding: false,
    },
    amountLabel: {
        ...Typography.bodySm,
        marginTop: 12,
    },
    chipsBlock: {
        marginTop: space.sm,
    },
    chipsRow: {
        gap: space.sm,
        paddingVertical: space.xs,
        paddingRight: space.xl,
    },
    chip: {
        marginRight: space.xs,
    },
    footer: {
        paddingHorizontal: space.xl,
        paddingTop: space.sm,
        paddingBottom: space.lg,
    },
});
