import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Animated,
    Easing,
    LayoutChangeEvent,
    ScrollView,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import APIService from '@/src/ApiService/api.service';
import {
    CashioIcon,
    CircleIconButton,
    ScreenContainer,
} from '@/src/components/ui';
import {
    Colors,
    Fonts,
    Shadows,
    Typography,
    focusRing,
    noWebOutline,
    space,
} from '@/src/styles/theme';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';
import { DEFAULT_CATEGORIES } from '@/src/utils/defaultCategories';

const api = new APIService();
const LABEL_SCROLL_INTERVAL_MS = 3200;
const LABEL_SCROLL_START_DELAY_MS = 900;
const LABEL_SCROLL_END_PAUSE_MS = 650;
const LABEL_SCROLL_EDGE_PADDING = 10;

interface CategoryOpt {
    title: string;
}

export default function SelectCategoryScreen() {
    const router = useRouter();
    const params = useLocalSearchParams<{
        type?: 'expense' | 'income';
        returnTo?: string;
        currentCategory?: string;
    }>();
    const type = (params.type as 'expense' | 'income') || 'expense';
    const returnToBudget = params.returnTo === 'set-budget';

    const [query, setQuery] = useState('');
    const [searchFocused, setSearchFocused] = useState(false);
    const [categories, setCategories] = useState<CategoryOpt[]>([]);

    useEffect(() => {
        setCategories([]);
        load();
    }, [type]);

    const load = () => {
        api.getCategories(type)
            .then((res) => {
                if (res.data?.length) setCategories(res.data);
            })
            .catch(() => {});
    };

    // Merge BE categories with the curated defaults so the grid is never empty
    // and new users see useful options immediately. BE entries win on conflict.
    const mergedCategories = useMemo<CategoryOpt[]>(() => {
        const beTitles = new Set(categories.map((c) => c.title.toLowerCase()));
        const fallback = DEFAULT_CATEGORIES[type] || [];
        const order = new Map(fallback.map((title, index) => [title.toLowerCase(), index]));
        return [
            ...categories,
            ...fallback
                .filter((t) => !beTitles.has(t.toLowerCase()))
                .map((title) => ({ title })),
        ].map((category, index) => ({ category, index }))
            .sort((a, b) => {
                const aIsOther = a.category.title.toLowerCase() === 'other';
                const bIsOther = b.category.title.toLowerCase() === 'other';
                if (aIsOther && !bIsOther) return 1;
                if (!aIsOther && bIsOther) return -1;

                const aOrder = order.get(a.category.title.toLowerCase());
                const bOrder = order.get(b.category.title.toLowerCase());
                if (aOrder !== undefined && bOrder !== undefined) return aOrder - bOrder;
                if (aOrder !== undefined) return -1;
                if (bOrder !== undefined) return 1;
                return a.index - b.index;
            })
            .map(({ category }) => category);
    }, [categories, type]);

    const filtered = useMemo(() => {
        const q = query.trim().toLowerCase();
        if (!q) return mergedCategories;
        return mergedCategories.filter((c) => c.title.toLowerCase().includes(q));
    }, [mergedCategories, query]);

    const select = (title: string) => {
        if (returnToBudget) {
            router.replace({
                pathname: '/set-budget',
                params: { category: title, resetAmount: '1' },
            });
            return;
        }

        router.replace({
            pathname: '/add-transaction',
            params: { type, category: title },
        });
    };
    const goBack = () => {
        if (returnToBudget) {
            router.replace(
                params.currentCategory
                    ? {
                        pathname: '/set-budget',
                        params: { category: params.currentCategory },
                    }
                    : '/set-budget',
            );
            return;
        }

        router.back();
    };

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.headerRow}>
                <CircleIconButton name="chevron-back" onPress={goBack} />
                <Text style={styles.headerTitle}>
                    {returnToBudget
                        ? 'Select Budget Category'
                        : type === 'income'
                            ? 'Select Income Category'
                            : 'Select Expense Category'}
                </Text>
                <View style={{ width: 40 }} />
            </View>

            <View
                style={[
                    styles.searchWrap,
                    searchFocused && styles.searchWrapFocused,
                ]}
            >
                <Icon name="search" size={18} color={Colors.textSubtle} />
                <TextInput
                    placeholder={type === 'income' ? 'Search for income categories' : 'Search for expense categories'}
                    placeholderTextColor={Colors.textSubtle}
                    value={query}
                    onChangeText={setQuery}
                    style={[styles.searchInput, noWebOutline]}
                    autoCapitalize="words"
                    returnKeyType="search"
                    onFocus={() => setSearchFocused(true)}
                    onBlur={() => setSearchFocused(false)}
                />
            </View>

            <ScrollView
                contentContainerStyle={styles.gridScroll}
                showsVerticalScrollIndicator={false}
            >
                <View className="flex-row flex-wrap -mx-2">
                    {filtered.map((c) => (
                        <CategoryTile
                            key={c.title}
                            title={c.title}
                            type={type}
                            onPress={() => select(c.title)}
                        />
                    ))}
                    {filtered.length === 0 && (
                        <View style={styles.empty}>
                            <Icon name="search" size={32} color={Colors.textSubtle} />
                            <Text style={styles.emptyText}>No categories found</Text>
                            <Text style={styles.emptySub}>
                                Try a different search term.
                            </Text>
                        </View>
                    )}
                </View>
            </ScrollView>
        </ScreenContainer>
    );
}

const CategoryTile: React.FC<{
    title: string;
    type: 'expense' | 'income';
    onPress?: () => void;
}> = ({
    title,
    type,
    onPress,
}) => {
    const icon = resolveCategoryIcon(title, type);
    const shouldFitOneLine = title.trim().length <= 13;
    return (
        <TouchableOpacity
            activeOpacity={0.85}
            onPress={onPress}
            className="basis-1/4 items-center mb-3 px-2"
        >
            <View
                className="w-full max-w-24 aspect-square items-center justify-center mb-1 bg-white rounded-[14px]"
                style={styles.tileIcon}
            >
                <CashioIcon name={icon.name} size={36} />
            </View>
            <AutoScrollLabel title={title} shouldFitOneLine={shouldFitOneLine} />
        </TouchableOpacity>
    );
};

const AutoScrollLabel: React.FC<{
    title: string;
    shouldFitOneLine: boolean;
}> = ({ title, shouldFitOneLine }) => {
    const offset = useRef(new Animated.Value(0)).current;
    const [containerWidth, setContainerWidth] = useState(0);
    const [textWidth, setTextWidth] = useState(0);
    const shouldScroll = shouldFitOneLine && textWidth > containerWidth + 1;

    useEffect(() => {
        offset.stopAnimation();
        offset.setValue(0);

        if (!shouldScroll || containerWidth <= 0) return undefined;

        const scrollDistance = textWidth - containerWidth + LABEL_SCROLL_EDGE_PADDING;
        const animate = () => {
            Animated.sequence([
                Animated.timing(offset, {
                    toValue: -scrollDistance,
                    duration: 750,
                    easing: Easing.inOut(Easing.cubic),
                    useNativeDriver: true,
                }),
                Animated.delay(LABEL_SCROLL_END_PAUSE_MS),
                Animated.timing(offset, {
                    toValue: 0,
                    duration: 450,
                    easing: Easing.out(Easing.cubic),
                    useNativeDriver: true,
                }),
            ]).start();
        };

        const startTimer = setTimeout(animate, LABEL_SCROLL_START_DELAY_MS);
        const interval = setInterval(animate, LABEL_SCROLL_INTERVAL_MS);

        return () => {
            clearTimeout(startTimer);
            clearInterval(interval);
            offset.stopAnimation();
        };
    }, [containerWidth, offset, shouldScroll, textWidth]);

    const onContainerLayout = (event: LayoutChangeEvent) => {
        setContainerWidth(event.nativeEvent.layout.width);
    };

    const onTextLayout = (event: LayoutChangeEvent) => {
        setTextWidth(event.nativeEvent.layout.width);
    };

    if (!shouldFitOneLine) {
        return (
            <Text style={[styles.tileLabel, styles.tileLabelMultiLine]} numberOfLines={2}>
                {title}
            </Text>
        );
    }

    return (
        <View
            style={[
                styles.tileLabelFrame,
                shouldScroll ? styles.tileLabelFrameScrolling : styles.tileLabelFrameCentered,
            ]}
            onLayout={onContainerLayout}
        >
            <Animated.Text
                style={[
                    styles.tileLabel,
                    styles.tileLabelSingleLine,
                    shouldScroll && { transform: [{ translateX: offset }] },
                ]}
                numberOfLines={1}
                ellipsizeMode="clip"
                onLayout={onTextLayout}
            >
                {title}
            </Animated.Text>
        </View>
    );
};

const styles = StyleSheet.create({
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
    searchWrap: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.surface,
        marginHorizontal: space.xl,
        marginTop: space.lg,
        paddingHorizontal: space.lg,
        height: 48,
        borderRadius: 12,
        borderWidth: 1,
        borderColor: Colors.border,
        ...Shadows.sm,
    },
    searchWrapFocused: {
        ...focusRing,
        borderWidth: 1.5,
    },
    searchInput: {
        flex: 1,
        marginLeft: space.sm,
        ...Typography.body,
    },
    gridScroll: {
        paddingHorizontal: space.xl,
        paddingTop: space.xl,
        paddingBottom: space['3xl'],
    },
    tileIcon: {
        backgroundColor: Colors.surface,
        ...Shadows.sm,
    },
    tileLabel: {
        ...Typography.caption,
        fontFamily: Fonts.medium,
        fontSize: 12,
        lineHeight: 16,
        color: Colors.textMuted,
        textAlign: 'center',
    },
    tileLabelFrame: {
        width: '100%',
        height: 16,
        marginTop: space.xs,
        overflow: 'hidden',
    },
    tileLabelFrameCentered: {
        alignItems: 'center',
    },
    tileLabelFrameScrolling: {
        alignItems: 'flex-start',
    },
    tileLabelSingleLine: {
        flexShrink: 0,
        minWidth: '100%',
    },
    tileLabelMultiLine: {
        width: '100%',
        marginTop: space.xs,
        color: Colors.textMuted,
        textAlign: 'center',
    },
    empty: {
        flex: 1,
        width: '100%',
        alignItems: 'center',
        paddingVertical: space['4xl'],
    },
    emptyText: {
        ...Typography.bodyMedium,
        marginTop: space.md,
    },
    emptySub: {
        ...Typography.bodySm,
        textAlign: 'center',
        marginTop: space.xs,
        paddingHorizontal: space.xl,
    },
});
