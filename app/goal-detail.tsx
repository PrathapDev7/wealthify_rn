import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    KeyboardAvoidingView,
    Platform,
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
import { usePreferences } from '@/src/context/PreferencesContext';
import CustomDatePicker from '@/src/components/common/CustomDatePicker';
import ConfirmationModal from '@/src/components/common/ConfirmationModal';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

interface Contribution {
    amount: number;
    date: string;
    note?: string;
}

interface Goal {
    _id: string;
    name: string;
    targetAmount: number;
    savedAmount: number;
    targetDate?: string;
    icon?: string;
    color?: string;
    note?: string;
    completed: boolean;
    contributions: Contribution[];
}

const formatDate = (iso?: string) => {
    if (!iso) return '';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return '';
    return d.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });
};

const ProgressBar = ({
    value,
    max,
    colors,
    styles,
}: {
    value: number;
    max: number;
    colors: ColorPalette;
    styles: ReturnType<typeof makeStyles>;
}) => {
    const ratio = max > 0 ? Math.min(value / max, 1) : 0;
    const barColor = ratio >= 1 ? colors.accentDark : colors.primary;
    return (
        <View style={styles.track}>
            <View style={[styles.fill, { width: `${ratio * 100}%`, backgroundColor: barColor }]} />
        </View>
    );
};

export default function GoalDetailScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { formatCurrency } = usePreferences();
    const params = useLocalSearchParams<{ id?: string }>();
    const id = params.id;
    const isCreate = !id;

    // Shared form fields (used in create mode and inline edit in detail mode).
    const [name, setName] = useState('');
    const [targetAmount, setTargetAmount] = useState('');
    const [targetDate, setTargetDate] = useState('');
    const [note, setNote] = useState('');

    // Detail-mode state.
    const [loading, setLoading] = useState(!isCreate);
    const [goal, setGoal] = useState<Goal | null>(null);
    const [contribAmount, setContribAmount] = useState('');
    const [editing, setEditing] = useState(false);

    // Action flags.
    const [saving, setSaving] = useState(false);
    const [contributing, setContributing] = useState(false);
    const [completing, setCompleting] = useState(false);
    const [savingEdit, setSavingEdit] = useState(false);
    const [confirmVisible, setConfirmVisible] = useState(false);

    const load = useCallback(() => {
        if (isCreate) return;
        setLoading(true);
        api.getGoals()
            .then((res) => {
                const list: Goal[] = res.data?.data || [];
                const found = list.find((g) => g._id === id) || null;
                setGoal(found);
            })
            .catch(() => {
                Toast.show({ type: 'error', text1: 'Failed to load goal' });
            })
            .finally(() => setLoading(false));
    }, [id, isCreate]);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    // ---- create mode ----
    const onCreate = async () => {
        if (!name.trim()) {
            return Toast.show({ type: 'error', text1: 'Enter a goal name' });
        }
        if (!targetAmount || Number(targetAmount) <= 0) {
            return Toast.show({ type: 'error', text1: 'Enter a target amount' });
        }
        setSaving(true);
        try {
            await api.addGoal({
                name: name.trim(),
                targetAmount: Number(targetAmount),
                ...(targetDate ? { targetDate } : {}),
                ...(note.trim() ? { note: note.trim() } : {}),
            });
            Toast.show({ type: 'success', text1: 'Goal created' });
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to create goal',
            });
        } finally {
            setSaving(false);
        }
    };

    // ---- detail mode actions ----
    const onContribute = async () => {
        if (!id) return;
        if (!contribAmount || Number(contribAmount) <= 0) {
            return Toast.show({ type: 'error', text1: 'Enter an amount' });
        }
        setContributing(true);
        try {
            await api.contributeGoal(id, { amount: Number(contribAmount) });
            setContribAmount('');
            Toast.show({ type: 'success', text1: 'Contribution added' });
            load();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to add contribution',
            });
        } finally {
            setContributing(false);
        }
    };

    const onMarkComplete = async () => {
        if (!id) return;
        setCompleting(true);
        try {
            await api.updateGoal(id, { completed: true });
            Toast.show({ type: 'success', text1: 'Goal marked complete' });
            load();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to update goal',
            });
        } finally {
            setCompleting(false);
        }
    };

    const startEditing = () => {
        if (!goal) return;
        setName(goal.name);
        setTargetAmount(String(goal.targetAmount ?? ''));
        setTargetDate(goal.targetDate ? goal.targetDate.slice(0, 10) : '');
        setNote(goal.note || '');
        setEditing(true);
    };

    const onSaveEdit = async () => {
        if (!id) return;
        if (!name.trim()) {
            return Toast.show({ type: 'error', text1: 'Enter a goal name' });
        }
        if (!targetAmount || Number(targetAmount) <= 0) {
            return Toast.show({ type: 'error', text1: 'Enter a target amount' });
        }
        setSavingEdit(true);
        try {
            await api.updateGoal(id, {
                name: name.trim(),
                targetAmount: Number(targetAmount),
                targetDate: targetDate || undefined,
                note: note.trim() || undefined,
            });
            Toast.show({ type: 'success', text1: 'Goal updated' });
            setEditing(false);
            load();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to update goal',
            });
        } finally {
            setSavingEdit(false);
        }
    };

    const onDelete = async () => {
        if (!id) return;
        setConfirmVisible(false);
        try {
            await api.deleteGoal(id);
            Toast.show({ type: 'success', text1: 'Goal deleted' });
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to delete goal',
            });
        }
    };

    const headerTitle = isCreate ? 'New goal' : editing ? 'Edit goal' : 'Goal';

    const renderForm = (onSubmit: () => void, submitLabel: string, busy: boolean) => (
        <>
            <TextField
                label="Name"
                placeholder="e.g. Emergency fund"
                value={name}
                onChangeText={setName}
                autoCapitalize="sentences"
            />
            <TextField
                label="Target amount"
                placeholder="0"
                value={targetAmount}
                onChangeText={(t) => setTargetAmount(t.replace(/[^0-9.]/g, ''))}
                keyboardType="numeric"
            />
            <Text style={styles.fieldLabel}>Target date (optional)</Text>
            <View style={styles.datePickerWrap}>
                <CustomDatePicker
                    value={targetDate}
                    placeholder="Select date"
                    onChange={setTargetDate}
                />
            </View>
            <TextField
                label="Note (optional)"
                placeholder="Add a note"
                value={note}
                onChangeText={setNote}
                autoCapitalize="sentences"
            />
            <PillButton
                label={submitLabel}
                onPress={onSubmit}
                loading={busy}
                size="lg"
                style={{ marginTop: space.sm }}
            />
        </>
    );

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : undefined}
                style={styles.flex}
            >
                <View style={styles.header}>
                    <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                    <Text style={styles.headerTitle}>{headerTitle}</Text>
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
                        {isCreate ? (
                            <Card style={styles.formCard}>
                                {renderForm(onCreate, 'Create goal', saving)}
                            </Card>
                        ) : !goal ? (
                            <Card style={styles.empty}>
                                <Icon name="alert-circle-outline" size={34} color={colors.textSubtle} />
                                <Text style={styles.emptyTitle}>Goal not found</Text>
                                <Text style={styles.emptyBody}>
                                    It may have been deleted. Go back and try again.
                                </Text>
                            </Card>
                        ) : editing ? (
                            <Card style={styles.formCard}>
                                {renderForm(onSaveEdit, 'Save changes', savingEdit)}
                                <PillButton
                                    label="Cancel"
                                    variant="secondary"
                                    onPress={() => setEditing(false)}
                                    style={{ marginTop: space.md }}
                                />
                            </Card>
                        ) : (
                            <>
                                <Card style={styles.progressCard}>
                                    <View style={styles.progressHead}>
                                        <Text style={styles.goalName} numberOfLines={2}>{goal.name}</Text>
                                        {goal.completed ? (
                                            <View style={styles.badge}>
                                                <Icon name="checkmark" size={12} color={colors.textInverse} />
                                                <Text style={styles.badgeText}>Completed</Text>
                                            </View>
                                        ) : null}
                                    </View>
                                    <Text style={styles.bigAmount}>
                                        {formatCurrency(goal.savedAmount)}
                                        <Text style={styles.bigAmountTarget}> / {formatCurrency(goal.targetAmount)}</Text>
                                    </Text>
                                    <ProgressBar value={goal.savedAmount} max={goal.targetAmount} colors={colors} styles={styles} />
                                    <Text style={styles.percentLine}>
                                        {goal.targetAmount > 0
                                            ? Math.round(Math.min(goal.savedAmount / goal.targetAmount, 1) * 100)
                                            : 0}
                                        % saved
                                    </Text>
                                    {goal.targetDate ? (
                                        <Text style={styles.targetDateLine}>Target date {formatDate(goal.targetDate)}</Text>
                                    ) : null}
                                    {goal.note ? <Text style={styles.noteLine}>{goal.note}</Text> : null}
                                </Card>

                                {!goal.completed ? (
                                    <Card style={styles.contribCard}>
                                        <Text style={styles.sectionTitle}>Add contribution</Text>
                                        <TextField
                                            placeholder="Amount"
                                            value={contribAmount}
                                            onChangeText={(t) => setContribAmount(t.replace(/[^0-9.]/g, ''))}
                                            keyboardType="numeric"
                                            style={styles.contribInput}
                                        />
                                        <PillButton
                                            label="Add contribution"
                                            onPress={onContribute}
                                            loading={contributing}
                                        />
                                    </Card>
                                ) : null}

                                <Card style={styles.listCard}>
                                    <Text style={styles.sectionTitle}>Contributions</Text>
                                    {goal.contributions.length === 0 ? (
                                        <Text style={styles.emptyBody}>No contributions yet.</Text>
                                    ) : (
                                        [...goal.contributions]
                                            .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                                            .map((c, idx) => (
                                                <View
                                                    key={`${c.date}-${idx}`}
                                                    style={[
                                                        styles.contribRow,
                                                        idx > 0 && styles.contribRowBorder,
                                                    ]}
                                                >
                                                    <View style={styles.contribRowLeft}>
                                                        <Text style={styles.contribDate}>{formatDate(c.date)}</Text>
                                                        {c.note ? (
                                                            <Text style={styles.contribNote} numberOfLines={1}>{c.note}</Text>
                                                        ) : null}
                                                    </View>
                                                    <Text style={styles.contribAmount}>+{formatCurrency(c.amount)}</Text>
                                                </View>
                                            ))
                                    )}
                                </Card>

                                <PillButton
                                    label="Edit goal"
                                    variant="secondary"
                                    onPress={startEditing}
                                    style={{ marginTop: space.lg }}
                                />
                                {!goal.completed ? (
                                    <PillButton
                                        label="Mark complete"
                                        onPress={onMarkComplete}
                                        loading={completing}
                                        style={{ marginTop: space.md }}
                                    />
                                ) : null}
                                <PillButton
                                    label="Delete"
                                    variant="ghost"
                                    onPress={() => setConfirmVisible(true)}
                                    textStyle={{ color: colors.negative }}
                                    style={{ marginTop: space.md }}
                                />
                            </>
                        )}
                        <View style={{ height: 60 }} />
                    </ScrollView>
                )}
            </KeyboardAvoidingView>

            <ConfirmationModal
                visible={confirmVisible}
                onClose={() => setConfirmVisible(false)}
                onConfirm={onDelete}
                message="Delete this savings goal? This cannot be undone."
                confirmText="Delete"
                cancelText="Cancel"
            />
        </ScreenContainer>
    );
}

const makeStyles = (colors: ColorPalette) =>
    StyleSheet.create({
        flex: { flex: 1 },
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
        formCard: { marginBottom: space.lg },
        fieldLabel: { ...Typography.label, color: colors.textSubtle, marginBottom: space.sm },
        datePickerWrap: { marginBottom: space.lg },
        progressCard: { marginBottom: space.lg, gap: space.sm },
        progressHead: { flexDirection: 'row', alignItems: 'flex-start', gap: space.sm },
        goalName: { ...Typography.title, color: colors.text, flex: 1 },
        bigAmount: { ...Typography.titleLg, color: colors.text },
        bigAmountTarget: { ...Typography.body, color: colors.textSubtle },
        percentLine: { ...Typography.bodySm, color: colors.textSubtle },
        targetDateLine: { ...Typography.caption, color: colors.textSubtle },
        noteLine: { ...Typography.bodySm, color: colors.textBody },
        contribCard: { marginBottom: space.lg, gap: space.md },
        contribInput: { marginBottom: 0 },
        sectionTitle: { ...Typography.subtitle, color: colors.text },
        listCard: { marginBottom: space.lg, gap: space.sm },
        contribRow: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingVertical: space.sm,
        },
        contribRowBorder: {
            borderTopWidth: StyleSheet.hairlineWidth,
            borderTopColor: colors.border,
        },
        contribRowLeft: { flex: 1, gap: 2 },
        contribDate: { ...Typography.bodySm, color: colors.text, fontFamily: Typography.bodyMedium.fontFamily },
        contribNote: { ...Typography.caption, color: colors.textSubtle },
        contribAmount: { ...Typography.moneySm, color: colors.accentDark },
        badge: {
            flexDirection: 'row',
            alignItems: 'center',
            gap: 3,
            paddingHorizontal: space.sm,
            paddingVertical: 3,
            borderRadius: radius.xs,
            backgroundColor: colors.accentDark,
        },
        badgeText: { ...Typography.caption, color: colors.textInverse, fontFamily: Typography.bodyMedium.fontFamily },
        track: {
            height: 8, borderRadius: 4, backgroundColor: colors.surfaceMuted, overflow: 'hidden',
        },
        fill: { height: '100%', borderRadius: 4 },
        empty: { alignItems: 'center', gap: space.sm, paddingVertical: space['2xl'] },
        emptyTitle: { ...Typography.subtitle, color: colors.text },
        emptyBody: { ...Typography.bodySm, color: colors.textSubtle, textAlign: 'center' },
    });
