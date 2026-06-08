import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useFocusEffect, useRouter } from 'expo-router';
import { Card, CircleIconButton, PillButton, ScreenContainer } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { usePreferences } from '@/src/context/PreferencesContext';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

type WalletKind = 'cash' | 'bank' | 'card' | 'wallet';

interface Wallet {
    _id: string;
    name: string;
    kind: WalletKind;
    openingBalance: number;
    icon?: string;
    color?: string;
    balance: number;
    income: number;
    expense: number;
}

const KIND_ICON: Record<WalletKind, string> = {
    cash: 'cash-outline',
    bank: 'business-outline',
    card: 'card-outline',
    wallet: 'wallet-outline',
};

const KIND_LABEL: Record<WalletKind, string> = {
    cash: 'Cash',
    bank: 'Bank',
    card: 'Card',
    wallet: 'Wallet',
};

export default function WalletsScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();

    const [loading, setLoading] = useState(true);
    const [wallets, setWallets] = useState<Wallet[]>([]);

    const load = useCallback(() => {
        setLoading(true);
        api.getWallets()
            .then((res) => {
                const data: Wallet[] = res.data?.data || [];
                setWallets(data);
            })
            .catch(() => {})
            .finally(() => setLoading(false));
    }, []);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const total = wallets.reduce((sum, w) => sum + (w.balance || 0), 0);

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Wallets</Text>
                <View style={{ width: 40 }} />
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
                    <Card style={styles.totalCard}>
                        <Text style={styles.totalLabel}>Total balance</Text>
                        <Text style={[styles.totalValue, total < 0 && { color: colors.negative }]}>
                            {formatCurrency(total)}
                        </Text>
                        <Text style={styles.totalSub}>
                            {wallets.length} {wallets.length === 1 ? 'account' : 'accounts'}
                        </Text>
                    </Card>

                    {wallets.length === 0 ? (
                        <Card style={styles.empty}>
                            <Icon name="wallet-outline" size={34} color={colors.textSubtle} />
                            <Text style={styles.emptyTitle}>No wallets yet</Text>
                            <Text style={styles.emptyBody}>
                                Add a cash, bank, card or wallet account to track balances separately.
                            </Text>
                        </Card>
                    ) : (
                        wallets.map((w) => {
                            const accent = w.color || colors.primary;
                            const negative = (w.balance || 0) < 0;
                            return (
                                <Card
                                    key={w._id}
                                    style={styles.row}
                                    onPress={() => router.push({ pathname: '/edit-wallet', params: { id: w._id } })}
                                >
                                    <View style={styles.rowTop}>
                                        <View style={[styles.iconWrap, { backgroundColor: accent + '22' }]}>
                                            <Icon name={KIND_ICON[w.kind]} size={18} color={accent} />
                                        </View>
                                        <View style={styles.rowText}>
                                            <Text style={styles.rowTitle} numberOfLines={1}>{w.name}</Text>
                                            <Text style={styles.rowKind}>{KIND_LABEL[w.kind]}</Text>
                                        </View>
                                        <Text style={[styles.rowAmount, negative && { color: colors.negative }]}>
                                            {formatCurrency(w.balance)}
                                        </Text>
                                    </View>
                                    <Text style={styles.rowSub}>
                                        in {formatCurrency(w.income)} · out {formatCurrency(w.expense)}
                                    </Text>
                                </Card>
                            );
                        })
                    )}

                    <PillButton
                        label="Add wallet"
                        onPress={() => router.push('/edit-wallet')}
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
        scroll: { paddingHorizontal: space.xl, paddingTop: space.sm, paddingBottom: space['3xl'] },
        totalCard: { marginBottom: space.lg, gap: space.xs },
        totalLabel: { ...Typography.label, color: colors.textSubtle },
        totalValue: { ...Typography.titleLg, color: colors.text },
        totalSub: { ...Typography.bodySm, color: colors.textSubtle },
        row: { marginBottom: space.md, gap: space.sm },
        rowTop: { flexDirection: 'row', alignItems: 'center' },
        iconWrap: {
            width: 36, height: 36, borderRadius: 18,
            alignItems: 'center', justifyContent: 'center', marginRight: space.md,
        },
        rowText: { flex: 1 },
        rowTitle: { ...Typography.bodyMedium, color: colors.text },
        rowKind: { ...Typography.caption, color: colors.textSubtle, marginTop: 1 },
        rowAmount: { ...Typography.moneySm, color: colors.text },
        rowSub: { ...Typography.caption, color: colors.textSubtle },
        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
    });
