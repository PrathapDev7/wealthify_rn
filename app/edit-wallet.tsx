import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import Toast from 'react-native-toast-message';
import { useFocusEffect, useLocalSearchParams, useRouter } from 'expo-router';
import { Card, CircleIconButton, PillButton, ScreenContainer, TextField } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import ConfirmationModal from '@/src/components/common/ConfirmationModal';
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

const KIND_OPTIONS: SegOption<WalletKind>[] = [
    { value: 'cash', label: 'Cash', icon: 'cash-outline' },
    { value: 'bank', label: 'Bank', icon: 'business-outline' },
    { value: 'card', label: 'Card', icon: 'card-outline' },
    { value: 'wallet', label: 'Wallet', icon: 'wallet-outline' },
];

export default function EditWalletScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const params = useLocalSearchParams<{ id?: string }>();
    const id = params.id;
    const isEdit = !!id;

    const [loading, setLoading] = useState(isEdit);
    const [saving, setSaving] = useState(false);
    const [confirmVisible, setConfirmVisible] = useState(false);

    const [name, setName] = useState('');
    const [kind, setKind] = useState<WalletKind>('cash');
    const [openingBalance, setOpeningBalance] = useState('');

    const load = useCallback(() => {
        if (!id) return;
        setLoading(true);
        api.getWallets()
            .then((res) => {
                const data: Wallet[] = res.data?.data || [];
                const found = data.find((w) => w._id === id);
                if (found) {
                    setName(found.name ?? '');
                    setKind(found.kind ?? 'cash');
                    setOpeningBalance(
                        found.openingBalance != null ? String(found.openingBalance) : '',
                    );
                }
            })
            .catch(() => {})
            .finally(() => setLoading(false));
    }, [id]);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const onSave = async () => {
        const trimmed = name.trim();
        if (!trimmed) {
            return Toast.show({ type: 'error', text1: 'Enter a name' });
        }
        const opening = Number(openingBalance) || 0;
        setSaving(true);
        try {
            if (isEdit && id) {
                await api.updateWallet(id, { name: trimmed, kind, openingBalance: opening });
                Toast.show({ type: 'success', text1: 'Wallet updated' });
            } else {
                await api.addWallet({ name: trimmed, kind, openingBalance: opening });
                Toast.show({ type: 'success', text1: 'Wallet added' });
            }
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to save wallet',
            });
        } finally {
            setSaving(false);
        }
    };

    const onDelete = async () => {
        if (!id) return;
        setConfirmVisible(false);
        try {
            await api.deleteWallet(id);
            Toast.show({ type: 'success', text1: 'Wallet deleted' });
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to delete wallet',
            });
        }
    };

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>{isEdit ? 'Edit wallet' : 'Add wallet'}</Text>
                <View style={{ width: 40 }} />
            </View>

            {loading ? (
                <View style={styles.center}>
                    <ActivityIndicator color={colors.primary} />
                </View>
            ) : (
                <ScrollView
                    showsVerticalScrollIndicator={false}
                    keyboardShouldPersistTaps="handled"
                    contentContainerStyle={styles.scroll}
                >
                    <Card style={styles.card}>
                        <TextField
                            label="Name"
                            placeholder="e.g. Everyday cash"
                            value={name}
                            onChangeText={setName}
                            autoCapitalize="sentences"
                            style={styles.field}
                        />

                        <Text style={styles.fieldLabel}>Type</Text>
                        <Segmented<WalletKind>
                            options={KIND_OPTIONS}
                            value={kind}
                            onChange={setKind}
                            styles={styles}
                            colors={colors}
                        />

                        <TextField
                            label="Opening balance"
                            placeholder="0"
                            value={openingBalance}
                            onChangeText={setOpeningBalance}
                            keyboardType="numeric"
                            style={[styles.field, styles.fieldTop]}
                        />
                    </Card>

                    <PillButton
                        label={isEdit ? 'Save changes' : 'Add wallet'}
                        onPress={onSave}
                        loading={saving}
                        size="lg"
                        style={{ marginTop: space.lg }}
                    />

                    {isEdit ? (
                        <PillButton
                            label="Delete wallet"
                            variant="secondary"
                            onPress={() => setConfirmVisible(true)}
                            leftIcon={<Icon name="trash-outline" size={18} color={colors.negative} />}
                            textStyle={{ color: colors.negative }}
                            style={{ marginTop: space.md }}
                        />
                    ) : null}

                    <View style={{ height: 60 }} />
                </ScrollView>
            )}

            <ConfirmationModal
                visible={confirmVisible}
                onClose={() => setConfirmVisible(false)}
                onConfirm={onDelete}
                message="Delete this wallet? Its transactions are kept but it will be archived."
                confirmText="Delete"
                cancelText="Cancel"
            />
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
        card: { gap: space.sm },
        field: { marginBottom: 0 },
        fieldTop: { marginTop: space.sm },
        fieldLabel: { ...Typography.label, color: colors.textSubtle, marginBottom: space.sm },
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
