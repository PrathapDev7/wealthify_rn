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
import { useFocusEffect, useLocalSearchParams, useRouter } from 'expo-router';
import Toast from 'react-native-toast-message';
import {
    Card,
    CircleIconButton,
    PillButton,
    ScreenContainer,
    TextField,
} from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import CustomDatePicker from '@/src/components/common/CustomDatePicker';
import ConfirmationModal from '@/src/components/common/ConfirmationModal';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

type Kind = 'expense' | 'income';
type Frequency = 'daily' | 'weekly' | 'monthly' | 'yearly';

interface Recurring {
    _id: string;
    kind: Kind;
    amount: number;
    category: string;
    sub_category?: string;
    title?: string;
    description?: string;
    frequency: Frequency;
    interval: number;
    startDate: string;
    nextRunDate: string;
    endDate?: string;
    active: boolean;
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

export default function EditRecurringScreen() {
    const router = useRouter();
    const params = useLocalSearchParams<{ id?: string }>();
    const isEdit = !!params.id;
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);

    const [loading, setLoading] = useState(isEdit);
    const [saving, setSaving] = useState(false);
    const [showDelete, setShowDelete] = useState(false);

    const [kind, setKind] = useState<Kind>('expense');
    const [amount, setAmount] = useState('');
    const [category, setCategory] = useState('');
    const [description, setDescription] = useState('');
    const [frequency, setFrequency] = useState<Frequency>('monthly');
    const [interval, setInterval] = useState('1');
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');

    const load = useCallback(() => {
        if (!params.id) return;
        setLoading(true);
        api.getRecurring()
            .then((res) => {
                const list: Recurring[] = res.data?.data || [];
                const rule = list.find((r) => r._id === params.id);
                if (rule) {
                    setKind(rule.kind);
                    setAmount(rule.amount != null ? String(rule.amount) : '');
                    setCategory(rule.category || '');
                    setDescription(rule.description || '');
                    setFrequency(rule.frequency);
                    setInterval(rule.interval != null ? String(rule.interval) : '1');
                    setStartDate(rule.startDate || '');
                    setEndDate(rule.endDate || '');
                } else {
                    Toast.show({ type: 'error', text1: 'Recurring not found' });
                }
            })
            .catch((err: any) => {
                Toast.show({
                    type: 'error',
                    text1: err?.response?.data?.message || 'Something went wrong',
                });
            })
            .finally(() => setLoading(false));
    }, [params.id]);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const onSave = async () => {
        if (!amount || Number(amount) <= 0) {
            return Toast.show({ type: 'error', text1: 'Enter an amount' });
        }
        if (!category.trim()) {
            return Toast.show({ type: 'error', text1: 'Enter a category' });
        }
        if (!startDate) {
            return Toast.show({ type: 'error', text1: 'Pick a start date' });
        }

        const body: Record<string, any> = {
            kind,
            amount: Number(amount),
            category: category.trim(),
            description: description.trim(),
            frequency,
            interval: Number(interval) || 1,
            startDate,
            endDate: endDate || undefined,
        };
        // Income entries carry a title; reuse the category when no dedicated field.
        if (kind === 'income') {
            body.title = category.trim();
        }

        setSaving(true);
        try {
            if (isEdit && params.id) {
                await api.updateRecurring(params.id, body);
            } else {
                await api.addRecurring(body);
            }
            Toast.show({
                type: 'success',
                text1: isEdit ? 'Recurring updated' : 'Recurring added',
            });
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err?.response?.data?.message || 'Something went wrong',
            });
        } finally {
            setSaving(false);
        }
    };

    const onDelete = async () => {
        if (!params.id) return;
        setShowDelete(false);
        try {
            await api.deleteRecurring(params.id);
            Toast.show({ type: 'success', text1: 'Recurring deleted' });
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err?.response?.data?.message || 'Something went wrong',
            });
        }
    };

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>
                    {isEdit ? 'Edit recurring' : 'Add recurring'}
                </Text>
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
                        <Text style={styles.fieldLabel}>Type</Text>
                        <Segmented<Kind>
                            options={[
                                { value: 'expense', label: 'Expense', icon: 'arrow-up-outline' },
                                { value: 'income', label: 'Income', icon: 'arrow-down-outline' },
                            ]}
                            value={kind}
                            onChange={setKind}
                            styles={styles}
                            colors={colors}
                        />

                        <TextField
                            label="Amount"
                            placeholder="0"
                            value={amount}
                            onChangeText={setAmount}
                            keyboardType="numeric"
                            leftIconName="cash-outline"
                            style={styles.spacedTop}
                        />

                        <TextField
                            label="Category"
                            placeholder="e.g. Rent, Salary, Netflix"
                            value={category}
                            onChangeText={setCategory}
                            autoCapitalize="words"
                            leftIconName="pricetag-outline"
                        />

                        <TextField
                            label="Description (optional)"
                            placeholder="Add a note"
                            value={description}
                            onChangeText={setDescription}
                            autoCapitalize="sentences"
                            leftIconName="create-outline"
                        />
                    </Card>

                    <Card style={styles.card}>
                        <Text style={styles.fieldLabel}>Frequency</Text>
                        <Segmented<Frequency>
                            options={[
                                { value: 'daily', label: 'Daily' },
                                { value: 'weekly', label: 'Weekly' },
                                { value: 'monthly', label: 'Monthly' },
                                { value: 'yearly', label: 'Yearly' },
                            ]}
                            value={frequency}
                            onChange={setFrequency}
                            styles={styles}
                            colors={colors}
                        />

                        <TextField
                            label="Repeat every (interval)"
                            placeholder="1"
                            value={interval}
                            onChangeText={setInterval}
                            keyboardType="numeric"
                            leftIconName="repeat-outline"
                            style={styles.spacedTop}
                        />

                        <Text style={[styles.fieldLabel, styles.spacedTop]}>Start date</Text>
                        <CustomDatePicker
                            value={startDate}
                            placeholder="Select start date"
                            onChange={setStartDate}
                        />

                        <Text style={[styles.fieldLabel, styles.spacedTop]}>
                            End date (optional)
                        </Text>
                        <CustomDatePicker
                            value={endDate}
                            placeholder="No end date"
                            onChange={setEndDate}
                        />
                    </Card>

                    <PillButton
                        label={isEdit ? 'Save changes' : 'Add recurring'}
                        onPress={onSave}
                        loading={saving}
                        size="lg"
                        style={{ marginTop: space.md }}
                    />

                    {isEdit ? (
                        <PillButton
                            label="Delete recurring"
                            variant="secondary"
                            onPress={() => setShowDelete(true)}
                            style={{ marginTop: space.md }}
                            textStyle={{ color: colors.negative }}
                        />
                    ) : null}

                    <View style={{ height: 60 }} />
                </ScrollView>
            )}

            <ConfirmationModal
                visible={showDelete}
                onClose={() => setShowDelete(false)}
                onConfirm={onDelete}
                message="Delete this recurring transaction? Future entries will no longer be created."
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
        scroll: {
            paddingHorizontal: space.xl,
            paddingTop: space.sm,
            paddingBottom: space['3xl'],
        },
        card: { gap: space.sm, marginBottom: space.lg },
        fieldLabel: { ...Typography.label, color: colors.textSubtle },
        spacedTop: { marginTop: space.md },
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
