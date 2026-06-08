import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    Image,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useFocusEffect, useRouter } from 'expo-router';
import { Card, CircleIconButton, PillButton, ScreenContainer, WealthifyIcon } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

type CategoryType = 'expense' | 'income';

interface Category {
    _id: string;
    title: string;
    type: CategoryType;
    icon?: string;
    color?: string;
}

interface SegOption<T> {
    value: T;
    label: string;
    icon?: string;
}

function Segmented<T extends string>({
    options,
    value,
    onChange,
    styles,
    colors,
}: {
    options: SegOption<T>[];
    value: T;
    onChange: (v: T) => void;
    styles: ReturnType<typeof makeStyles>;
    colors: ColorPalette;
}) {
    return (
        <View style={styles.segment}>
            {options.map((opt) => {
                const active = opt.value === value;
                return (
                    <Pressable
                        key={opt.value}
                        onPress={() => onChange(opt.value)}
                        style={[styles.segmentItem, active && styles.segmentItemActive]}
                    >
                        {opt.icon ? (
                            <Icon
                                name={opt.icon}
                                size={15}
                                color={active ? colors.textInverse : colors.textSubtle}
                                style={{ marginRight: 6 }}
                            />
                        ) : null}
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
    );
}

const CategoryIcon: React.FC<{ category: Category; colors: ColorPalette }> = ({ category, colors }) => {
    if (category.icon && category.icon.startsWith('http')) {
        return <Image source={{ uri: category.icon }} style={{ width: 28, height: 28, borderRadius: 8 }} />;
    }
    const ic = resolveCategoryIcon(category.title, category.type);
    return <WealthifyIcon name={ic.name} size={28} />;
};

export default function ManageCategoriesScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);

    const [type, setType] = useState<CategoryType>('expense');
    const [categories, setCategories] = useState<Category[]>([]);
    const [loading, setLoading] = useState(true);

    const load = useCallback(() => {
        setLoading(true);
        api.getCategories(type)
            .then((res) => {
                setCategories(Array.isArray(res.data) ? res.data : []);
            })
            .catch(() => {})
            .finally(() => setLoading(false));
    }, [type]);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Manage Categories</Text>
                <View style={{ width: 40 }} />
            </View>

            <View style={styles.segmentWrap}>
                <Segmented<CategoryType>
                    options={[
                        { value: 'expense', label: 'Expense', icon: 'arrow-up-outline' },
                        { value: 'income', label: 'Income', icon: 'arrow-down-outline' },
                    ]}
                    value={type}
                    onChange={setType}
                    styles={styles}
                    colors={colors}
                />
            </View>

            {loading ? (
                <View style={styles.center}>
                    <ActivityIndicator color={colors.primary} />
                </View>
            ) : (
                <ScrollView
                    showsVerticalScrollIndicator={false}
                    contentContainerStyle={styles.scroll}
                >
                    {categories.length === 0 ? (
                        <Card style={styles.empty}>
                            <Icon name="pricetags-outline" size={34} color={colors.textSubtle} />
                            <Text style={styles.emptyTitle}>No {type} categories yet</Text>
                            <Text style={styles.emptyBody}>
                                Add a custom category with its own icon and color to organize your {type}s.
                            </Text>
                        </Card>
                    ) : (
                        categories.map((category) => (
                            <Card
                                key={category._id}
                                style={styles.row}
                                onPress={() => router.push({ pathname: '/edit-category', params: { id: category._id, type } })}
                            >
                                <View style={[styles.iconWrap, { backgroundColor: (category.color || colors.primary) + '22' }]}>
                                    <CategoryIcon category={category} colors={colors} />
                                </View>
                                <Text style={styles.rowTitle} numberOfLines={1}>{category.title}</Text>
                                <Icon name="chevron-forward" size={18} color={colors.textSubtle} />
                            </Card>
                        ))
                    )}

                    <PillButton
                        label="Add category"
                        onPress={() => router.push({ pathname: '/edit-category', params: { type } })}
                        leftIcon={<Icon name="add" size={18} color={colors.textInverse} />}
                        style={{ marginTop: space.lg }}
                    />
                    <View style={{ height: 60 }} />
                </ScrollView>
            )}
        </ScreenContainer>
    );
}

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
        center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
        segmentWrap: { paddingHorizontal: space.xl, paddingBottom: space.sm },
        scroll: { paddingHorizontal: space.xl, paddingTop: space.sm, paddingBottom: space['3xl'] },
        row: { marginBottom: space.md, flexDirection: 'row', alignItems: 'center' },
        iconWrap: {
            width: 44, height: 44, borderRadius: radius.sm,
            alignItems: 'center', justifyContent: 'center', marginRight: space.md,
        },
        rowTitle: { ...Typography.bodyMedium, color: colors.text, flex: 1 },
        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
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
        segmentItemActive: {
            backgroundColor: colors.primary,
        },
        segmentLabel: {
            ...Typography.bodySm,
            fontFamily: Typography.bodyMedium.fontFamily,
        },
    });
