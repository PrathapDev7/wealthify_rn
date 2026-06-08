import React, { useEffect, useMemo, useState } from 'react';
import {
    Alert,
    KeyboardAvoidingView,
    Platform,
    ScrollView,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import Icon from 'react-native-vector-icons/Ionicons';
import moment from 'moment';
import Toast from 'react-native-toast-message';
import APIService from '@/src/ApiService/api.service';
import {
    Card,
    Chip,
    CircleIconButton,
    IconBadge,
    PillButton,
    ScreenContainer,
} from '@/src/components/ui';
import {
    Fonts,
    Shadows,
    Typography,
    noWebOutline,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { formatNumberWithCommas } from '@/src/utils/helper';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';
import { DEFAULT_CATEGORIES } from '@/src/utils/defaultCategories';

const api = new APIService();

type TransactionType = 'income' | 'expense';

const readParam = (value?: string | string[]) =>
    Array.isArray(value) ? value[0] || '' : value || '';

export default function TransactionDetailScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const params = useLocalSearchParams<{
        id?: string;
        transactionType?: TransactionType;
        title?: string;
        category?: string;
        subCategory?: string;
        expenseType?: string;
        date?: string;
        description?: string;
        amount?: string;
        createdAt?: string;
        updatedAt?: string;
    }>();

    const transactionType: TransactionType =
        params.transactionType === 'income' ? 'income' : 'expense';
    const isIncome = transactionType === 'income';
    const id = readParam(params.id);
    const initialCategory = readParam(params.category);
    const title = readParam(params.title);
    const [category, setCategory] = useState(initialCategory);
    const [subCategory] = useState(readParam(params.subCategory));
    const [expenseType] = useState(readParam(params.expenseType) || 'self');
    const [date, setDate] = useState(readParam(params.date));
    const [description, setDescription] = useState(
        readParam(params.description),
    );
    const [amount, setAmount] = useState(readParam(params.amount));
    const [saving, setSaving] = useState(false);
    const [deleting, setDeleting] = useState(false);
    const [categories, setCategories] = useState<{ title: string }[]>([]);
    const [recentCategories, setRecentCategories] = useState<string[]>([]);
    const [categoriesLoading, setCategoriesLoading] = useState(true);

    const icon = useMemo(
        () => resolveCategoryIcon(category || title, transactionType),
        [category, title, transactionType],
    );
    const amountNumber = Number(amount || 0);
    const amountColor = isIncome ? colors.accentDark : colors.negative;
    const sign = isIncome ? '+' : '-';
    const formattedAmount = `${sign}₹${formatNumberWithCommas(
        Math.abs(amountNumber || 0).toFixed(2),
    )}`;
    const createdAt = readParam(params.createdAt);
    const updatedAt = readParam(params.updatedAt);
    const pageTitle = isIncome ? 'Income Details' : 'Expense Details';
    const displayName =
        (isIncome ? category || title : category || subCategory) ||
        (isIncome ? 'Income' : 'Expense');
    const popularCategories = useMemo(() => {
        const beTitles = categories.map((item) => item.title).filter(Boolean);
        const fallback = DEFAULT_CATEGORIES[transactionType] || [];
        const source = recentCategories.length
            ? [...recentCategories, ...fallback, ...beTitles]
            : [...fallback, ...beTitles];
        const seen = new Set<string>();
        const merged = source.filter((item) => {
            const key = item.toLowerCase();
            if (seen.has(key)) return false;
            seen.add(key);
            return true;
        });

        if (category && !merged.some((item) => item.toLowerCase() === category.toLowerCase())) {
            merged.unshift(category);
        }

        return merged.slice(0, 6);
    }, [categories, category, recentCategories, transactionType]);

    useEffect(() => {
        setCategoriesLoading(true);
        Promise.all([
            api.getCategories(transactionType),
            api.getRecentCategories(transactionType),
        ])
            .then(([categoriesRes, recentRes]) => {
                setCategories(
                    categoriesRes.data?.length ? categoriesRes.data : [],
                );
                setRecentCategories(
                    recentRes.data?.length
                        ? recentRes.data
                              .map((item) => item.title)
                              .filter(Boolean)
                        : [],
                );
            })
            .catch(() => {
                setCategories([]);
                setRecentCategories([]);
            })
            .finally(() => setCategoriesLoading(false));
    }, [transactionType]);

    const getRouteState = (nextCategory = category) => ({
        id,
        transactionType,
        title,
        category: nextCategory,
        subCategory,
        expenseType,
        date,
        description,
        amount,
        createdAt,
        updatedAt,
    });

    const goToCategoryPicker = () => {
        router.push({
            pathname: '/select-category',
            params: {
                ...getRouteState(),
                type: transactionType,
                returnTo: 'transaction-detail',
                currentCategory: category,
            },
        });
    };

    const validate = () => {
        const parsedAmount = Number(amount);
        if (!id) {
            Toast.show({ type: 'error', text1: 'Missing transaction ID' });
            return false;
        }
        if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
            Toast.show({ type: 'error', text1: 'Enter a valid amount' });
            return false;
        }
        if (!category.trim()) {
            Toast.show({ type: 'error', text1: 'Category is required' });
            return false;
        }
        if (!moment(date, 'YYYY-MM-DD', true).isValid()) {
            Toast.show({ type: 'error', text1: 'Use date format YYYY-MM-DD' });
            return false;
        }
        return true;
    };

    const onSave = async () => {
        if (!validate()) return;

        setSaving(true);
        try {
            const commonPayload = {
                amount: Number(amount),
                category: category.trim(),
                description: description.trim(),
                date,
            };

            if (isIncome) {
                await api.updateIncome(id, {
                    ...commonPayload,
                    title: category.trim(),
                });
            } else {
                await api.updateExpense(id, {
                    ...commonPayload,
                    sub_category: subCategory.trim(),
                    type: expenseType.trim() || 'self',
                });
            }

            Toast.show({ type: 'success', text1: `${pageTitle} updated` });
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to update',
            });
        } finally {
            setSaving(false);
        }
    };

    const deleteTransaction = async () => {
        if (!id) {
            Toast.show({ type: 'error', text1: 'Missing transaction ID' });
            return;
        }

        setDeleting(true);
        try {
            if (isIncome) {
                await api.deleteIncome(id);
            } else {
                await api.deleteExpense(id);
            }
            Toast.show({ type: 'success', text1: `${pageTitle} deleted` });
            router.replace('/transactions');
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to delete',
            });
        } finally {
            setDeleting(false);
        }
    };

    const onDelete = () => {
        Alert.alert(
            `Delete ${isIncome ? 'income' : 'expense'}?`,
            'This transaction will be permanently removed.',
            [
                { text: 'Cancel', style: 'cancel' },
                {
                    text: 'Delete',
                    style: 'destructive',
                    onPress: deleteTransaction,
                },
            ],
        );
    };

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
                    <Text style={styles.headerTitle}>{pageTitle}</Text>
                    <View style={styles.headerSpacer} />
                </View>

                <ScrollView
                    keyboardShouldPersistTaps="handled"
                    showsVerticalScrollIndicator={false}
                    contentContainerStyle={styles.scroll}
                >
                    <Card style={styles.heroCard}>
                        <View style={styles.heroTop}>
                            <IconBadge
                                name={icon.name}
                                color={icon.color}
                                bg={`${icon.color}1A`}
                                size={58}
                                iconSize={34}
                                rounded="circle"
                                elevated={false}
                            />
                            <View style={styles.heroCopy}>
                                <Text style={styles.heroType}>
                                    {isIncome ? 'Income received' : 'Expense paid'}
                                </Text>
                                <Text style={styles.heroTitle} numberOfLines={1}>
                                    {displayName}
                                </Text>
                            </View>
                        </View>
                        <Text
                            style={[styles.heroAmount, { color: amountColor }]}
                            numberOfLines={1}
                            adjustsFontSizeToFit
                        >
                            {formattedAmount}
                        </Text>
                        <View style={styles.heroMetaRow}>
                            <MetaPill
                                icon="calendar-outline"
                                label={
                                    date
                                        ? moment(date).format('DD MMM YYYY')
                                        : 'No date'
                                }
                            />
                            <MetaPill
                                icon={isIncome ? 'arrow-down' : 'arrow-up'}
                                label={isIncome ? 'Income' : 'Expense'}
                                color={amountColor}
                            />
                        </View>
                    </Card>

                    <View style={styles.sectionLabelRow}>
                        <Text style={styles.sectionLabel}>Information</Text>
                    </View>

                    <Card style={styles.formCard} elevation="sm">
                        <CategorySelector
                            type={transactionType}
                            selected={category}
                            categories={popularCategories}
                            loading={categoriesLoading}
                            onSelect={setCategory}
                            onMorePress={goToCategoryPicker}
                        />
                        <DetailField
                            label="Amount"
                            value={amount}
                            onChangeText={(text) =>
                                setAmount(text.replace(/[^0-9.]/g, ''))
                            }
                            keyboardType="decimal-pad"
                            placeholder="0"
                            leftText="₹"
                        />
                        <DetailField
                            label="Date"
                            value={date}
                            onChangeText={setDate}
                            placeholder="YYYY-MM-DD"
                        />
                        <DetailField
                            label="Description"
                            value={description}
                            onChangeText={setDescription}
                            placeholder="Add notes or details"
                            multiline
                            maxLength={100}
                        />
                    </Card>

                    <View style={styles.actions}>
                        <PillButton
                            label="Save Changes"
                            onPress={onSave}
                            loading={saving}
                            disabled={deleting}
                            size="lg"
                        />
                        <TouchableOpacity
                            activeOpacity={0.85}
                            onPress={onDelete}
                            disabled={saving || deleting}
                            style={[
                                styles.deleteButton,
                                (saving || deleting) && styles.actionDisabled,
                            ]}
                        >
                            <Icon
                                name="trash-outline"
                                size={18}
                                color={colors.negative}
                            />
                            <Text style={styles.deleteText}>
                                {deleting ? 'Deleting...' : 'Delete Transaction'}
                            </Text>
                        </TouchableOpacity>
                    </View>
                </ScrollView>
            </KeyboardAvoidingView>
        </ScreenContainer>
    );
}

const MetaPill: React.FC<{
    icon: string;
    label: string;
    color?: string;
}> = ({ icon, label, color }) => {
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    return (
    <View style={styles.metaPill}>
        <Icon name={icon} size={14} color={color ?? colors.textSubtle} />
        <Text style={styles.metaPillText} numberOfLines={1}>
            {label}
        </Text>
    </View>
    );
};

const CategorySelector: React.FC<{
    type: TransactionType;
    selected: string;
    categories: string[];
    loading: boolean;
    onSelect: (category: string) => void;
    onMorePress: () => void;
}> = ({ type, selected, categories, loading, onSelect, onMorePress }) => {
    const colors = useColors();
    const categoryStyles = useMemo(() => makeCategoryStyles(colors), [colors]);
    return (
    <View style={categoryStyles.wrap}>
        <Text style={categoryStyles.label}>Category</Text>
        <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={categoryStyles.row}
        >
            {loading
                ? Array.from({ length: 4 }).map((_, index) => (
                      <View
                          key={index}
                          style={[
                              categoryStyles.loadingChip,
                              index % 2 === 0 && categoryStyles.loadingChipWide,
                          ]}
                      />
                  ))
                : categories.map((item) => {
                      const icon = resolveCategoryIcon(item, type);
                      return (
                          <Chip
                              key={item}
                              label={item}
                              iconName={icon.name}
                              iconColor={icon.color}
                              selected={
                                  item.toLowerCase() === selected.toLowerCase()
                              }
                              onPress={() => onSelect(item)}
                              style={categoryStyles.chip}
                          />
                      );
                  })}
            {!loading ? (
                <Chip
                    label="More"
                    iconName="ellipsis-horizontal"
                    iconColor={colors.primary}
                    selected={false}
                    onPress={onMorePress}
                    style={categoryStyles.chip}
                />
            ) : null}
        </ScrollView>
    </View>
    );
};

const DetailField: React.FC<{
    label: string;
    value: string;
    onChangeText: (value: string) => void;
    placeholder?: string;
    keyboardType?: 'default' | 'decimal-pad';
    autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
    multiline?: boolean;
    maxLength?: number;
    leftText?: string;
}> = ({
    label,
    value,
    onChangeText,
    placeholder,
    keyboardType = 'default',
    autoCapitalize = 'none',
    multiline = false,
    maxLength,
    leftText,
}) => {
    const colors = useColors();
    const fieldStyles = useMemo(() => makeFieldStyles(colors), [colors]);
    return (
    <View style={fieldStyles.wrap}>
        <Text style={fieldStyles.label}>{label}</Text>
        <View style={[fieldStyles.box, multiline && fieldStyles.boxMultiline]}>
            {leftText ? <Text style={fieldStyles.leftText}>{leftText}</Text> : null}
            <TextInput
                value={value}
                onChangeText={onChangeText}
                placeholder={placeholder}
                placeholderTextColor={colors.textPlaceholder}
                keyboardType={keyboardType}
                autoCapitalize={autoCapitalize}
                multiline={multiline}
                maxLength={maxLength}
                style={[
                    fieldStyles.input,
                    multiline && fieldStyles.inputMultiline,
                    noWebOutline,
                ]}
            />
        </View>
    </View>
    );
};

const makeStyles = (colors: ColorPalette) => StyleSheet.create({
    flex: {
        flex: 1,
    },
    headerRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: space.xl,
        paddingTop: space.lg,
        paddingBottom: space.md,
    },
    headerTitle: {
        ...Typography.screenTitle,
        color: colors.text,
    },
    headerSpacer: {
        width: 40,
        height: 40,
    },
    scroll: {
        paddingHorizontal: space.xl,
        paddingTop: space.sm,
        paddingBottom: 118,
    },
    heroCard: {
        paddingVertical: space.xl,
    },
    heroTop: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    heroCopy: {
        flex: 1,
        minWidth: 0,
        marginLeft: space.md,
    },
    heroType: {
        ...Typography.caption,
        fontFamily: Fonts.semibold,
        color: colors.textSubtle,
        marginBottom: 2,
    },
    heroTitle: {
        ...Typography.subtitle,
        fontFamily: Fonts.bold,
        color: colors.text,
    },
    heroAmount: {
        ...Typography.display,
        fontFamily: Fonts.semibold,
        marginTop: space.lg,
    },
    heroMetaRow: {
        flexDirection: 'row',
        alignItems: 'center',
        flexWrap: 'wrap',
        marginTop: space.md,
        marginBottom: -space.xs,
    },
    metaPill: {
        minHeight: 30,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: space.md,
        marginRight: space.sm,
        marginBottom: space.xs,
        backgroundColor: colors.surfaceSoft,
        borderRadius: radius.pill,
    },
    metaPillText: {
        ...Typography.caption,
        marginLeft: 6,
        color: colors.textBody,
    },
    sectionLabelRow: {
        marginTop: space.xl,
        marginBottom: space.sm,
    },
    sectionLabel: {
        ...Typography.bodyMedium,
        fontFamily: Fonts.semibold,
        color: colors.text,
    },
    formCard: {
        paddingBottom: space.sm,
    },
    actions: {
        marginTop: space.xl,
    },
    deleteButton: {
        minHeight: 52,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: space.md,
        borderRadius: radius.md,
        borderWidth: 1,
        borderColor: colors.negativeSoft,
        backgroundColor: colors.surface,
        ...Shadows.xs,
    },
    deleteText: {
        ...Typography.bodyMedium,
        color: colors.negative,
        marginLeft: space.sm,
    },
    actionDisabled: {
        opacity: 0.5,
    },
});

const makeCategoryStyles = (colors: ColorPalette) => StyleSheet.create({
    wrap: {
        marginBottom: space.lg,
    },
    label: {
        ...Typography.label,
        color: colors.textSubtle,
        marginBottom: space.sm,
    },
    row: {
        paddingVertical: space.xs,
        paddingRight: space.xl,
    },
    chip: {
        marginRight: space.sm,
    },
    loadingChip: {
        width: 92,
        height: 46,
        marginRight: space.sm,
        borderRadius: radius.pill,
        backgroundColor: colors.surfaceSoft,
        borderWidth: 1,
        borderColor: colors.border,
    },
    loadingChipWide: {
        width: 112,
    },
});

const makeFieldStyles = (colors: ColorPalette) => StyleSheet.create({
    wrap: {
        marginBottom: space.lg,
    },
    label: {
        ...Typography.label,
        color: colors.textSubtle,
        marginBottom: space.sm,
    },
    box: {
        minHeight: 52,
        flexDirection: 'row',
        alignItems: 'center',
        borderWidth: 1.5,
        borderColor: colors.border,
        borderRadius: radius.sm,
        paddingHorizontal: space.lg,
        backgroundColor: colors.surface,
    },
    boxMultiline: {
        minHeight: 106,
        alignItems: 'flex-start',
        paddingTop: space.md,
        paddingBottom: space.md,
    },
    leftText: {
        ...Typography.bodyMedium,
        color: colors.textSubtle,
        marginRight: space.sm,
    },
    input: {
        flex: 1,
        minWidth: 0,
        ...Typography.body,
        color: colors.text,
        paddingVertical: 0,
    },
    inputMultiline: {
        minHeight: 76,
        textAlignVertical: 'top',
    },
});
