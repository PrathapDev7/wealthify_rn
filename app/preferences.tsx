import React, { useMemo } from 'react';
import {
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useRouter } from 'expo-router';
import { Card, CircleIconButton, ScreenContainer } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    useThemeMode,
    type ColorPalette,
    type ThemeMode,
} from '@/src/styles/theme';
import { usePreferences, TxnType, WeekStart } from '@/src/context/PreferencesContext';

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

const CURRENCIES = [
    { code: 'INR', symbol: '₹', label: 'Rupee' },
    { code: 'USD', symbol: '$', label: 'Dollar' },
    { code: 'EUR', symbol: '€', label: 'Euro' },
    { code: 'GBP', symbol: '£', label: 'Pound' },
];

export default function PreferencesScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { mode, setMode } = useThemeMode();
    const { prefs, setPreference, setPreferences, formatCurrency } = usePreferences();

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Preferences</Text>
                <View style={{ width: 40 }} />
            </View>

            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
            >
                {/* Appearance */}
                <Text style={styles.sectionLabel}>Appearance</Text>
                <Card style={styles.card}>
                    <Text style={styles.rowLabel}>Theme</Text>
                    <Segmented<ThemeMode>
                        options={[
                            { value: 'light', label: 'Light', icon: 'sunny-outline' },
                            { value: 'dark', label: 'Dark', icon: 'moon-outline' },
                            { value: 'system', label: 'System', icon: 'phone-portrait-outline' },
                        ]}
                        value={mode}
                        onChange={setMode}
                        styles={styles}
                        colors={colors}
                    />
                </Card>

                {/* Currency */}
                <Text style={styles.sectionLabel}>Currency</Text>
                <Card style={styles.card}>
                    <View style={styles.rowBetween}>
                        <Text style={styles.rowLabel}>Symbol</Text>
                        <Text style={styles.preview}>{formatCurrency(1234.5)}</Text>
                    </View>
                    <View style={styles.currencyRow}>
                        {CURRENCIES.map((c) => {
                            const active = c.code === prefs.currencyCode;
                            return (
                                <Pressable
                                    key={c.code}
                                    onPress={() => setPreferences({ currencySymbol: c.symbol, currencyCode: c.code })}
                                    style={[styles.currencyChip, active && styles.currencyChipActive]}
                                >
                                    <Text style={[styles.currencySymbol, { color: active ? colors.textInverse : colors.text }]}>
                                        {c.symbol}
                                    </Text>
                                    <Text style={[styles.currencyCode, { color: active ? colors.textInverse : colors.textSubtle }]}>
                                        {c.code}
                                    </Text>
                                </Pressable>
                            );
                        })}
                    </View>
                </Card>

                {/* Defaults */}
                <Text style={styles.sectionLabel}>Defaults</Text>
                <Card style={styles.card}>
                    <Text style={styles.rowLabel}>New transaction type</Text>
                    <Segmented<TxnType>
                        options={[
                            { value: 'expense', label: 'Expense', icon: 'arrow-up-outline' },
                            { value: 'income', label: 'Income', icon: 'arrow-down-outline' },
                        ]}
                        value={prefs.defaultTxnType}
                        onChange={(v) => setPreference('defaultTxnType', v)}
                        styles={styles}
                        colors={colors}
                    />
                </Card>

                {/* Calendar */}
                <Text style={styles.sectionLabel}>Calendar</Text>
                <Card style={styles.card}>
                    <Text style={styles.rowLabel}>Week starts on</Text>
                    <Segmented<WeekStart>
                        options={[
                            { value: 'monday', label: 'Monday' },
                            { value: 'sunday', label: 'Sunday' },
                        ]}
                        value={prefs.weekStart}
                        onChange={(v) => setPreference('weekStart', v)}
                        styles={styles}
                        colors={colors}
                    />
                </Card>

                <View style={{ height: 60 }} />
            </ScrollView>
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
        headerTitle: {
            ...Typography.screenTitle,
            color: colors.text,
        },
        scroll: {
            paddingHorizontal: space.xl,
            paddingTop: space.sm,
            paddingBottom: space['3xl'],
        },
        sectionLabel: {
            ...Typography.label,
            color: colors.textSubtle,
            marginTop: space.xl,
            marginBottom: space.sm,
        },
        card: {
            gap: space.md,
        },
        rowLabel: {
            ...Typography.bodyMedium,
            color: colors.text,
        },
        rowBetween: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
        },
        preview: {
            ...Typography.bodyStrong,
            color: colors.primary,
        },
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
        currencyRow: {
            flexDirection: 'row',
            gap: space.sm,
        },
        currencyChip: {
            flex: 1,
            alignItems: 'center',
            paddingVertical: space.md,
            borderRadius: radius.sm,
            backgroundColor: colors.surfaceMuted,
            borderWidth: 1,
            borderColor: colors.border,
        },
        currencyChipActive: {
            backgroundColor: colors.primary,
            borderColor: colors.primary,
        },
        currencySymbol: {
            ...Typography.title,
        },
        currencyCode: {
            ...Typography.caption,
            marginTop: 2,
        },
    });
