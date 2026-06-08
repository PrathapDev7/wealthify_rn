import React, { useEffect, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    ScrollView,
    StyleSheet,
    Switch,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useRouter } from 'expo-router';
import Toast from 'react-native-toast-message';
import * as LocalAuthentication from 'expo-local-authentication';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Card, CircleIconButton, PillButton, ScreenContainer } from '@/src/components/ui';
import {
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';

const STORAGE_KEY = 'wealthify_app_lock';

function labelForType(type: LocalAuthentication.AuthenticationType): string {
    switch (type) {
        case LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION:
            return 'Face ID';
        case LocalAuthentication.AuthenticationType.FINGERPRINT:
            return 'Fingerprint/Touch ID';
        case LocalAuthentication.AuthenticationType.IRIS:
            return 'Iris';
        default:
            return 'Biometrics';
    }
}

export default function SecurityScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);

    const [loading, setLoading] = useState(true);
    const [enabled, setEnabled] = useState(false);
    const [hasHw, setHasHw] = useState(false);
    const [enrolled, setEnrolled] = useState(false);
    const [methods, setMethods] = useState<string[]>([]);

    useEffect(() => {
        (async () => {
            try {
                const saved = await AsyncStorage.getItem(STORAGE_KEY);
                setEnabled(saved === 'true');
            } catch {
                // ignore — default off
            }
            try {
                const hw = await LocalAuthentication.hasHardwareAsync();
                const isEnrolled = await LocalAuthentication.isEnrolledAsync();
                const types = await LocalAuthentication.supportedAuthenticationTypesAsync();
                setHasHw(hw);
                setEnrolled(isEnrolled);
                setMethods(types.map(labelForType));
            } catch {
                setHasHw(false);
                setEnrolled(false);
                setMethods([]);
            }
            setLoading(false);
        })();
    }, []);

    const available = hasHw && enrolled;

    const handleToggle = async (next: boolean) => {
        if (!next) {
            setEnabled(false);
            try {
                await AsyncStorage.setItem(STORAGE_KEY, 'false');
            } catch {
                // ignore
            }
            return;
        }

        // Turning ON.
        if (!hasHw || !enrolled) {
            Toast.show({ type: 'error', text1: 'No biometrics enrolled on this device' });
            return;
        }
        try {
            const r = await LocalAuthentication.authenticateAsync({
                promptMessage: 'Confirm to enable App Lock',
            });
            if (r.success) {
                setEnabled(true);
                await AsyncStorage.setItem(STORAGE_KEY, 'true');
                Toast.show({ type: 'success', text1: 'App Lock enabled' });
            }
            // else: keep off, leave state untouched.
        } catch {
            Toast.show({ type: 'error', text1: 'Could not enable App Lock' });
        }
    };

    const handleTestUnlock = async () => {
        try {
            const r = await LocalAuthentication.authenticateAsync({
                promptMessage: 'Test unlock',
            });
            if (r.success) {
                Toast.show({ type: 'success', text1: 'Unlock successful' });
            } else {
                Toast.show({ type: 'error', text1: 'Unlock failed' });
            }
        } catch {
            Toast.show({ type: 'error', text1: 'Unlock failed' });
        }
    };

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>Security</Text>
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
                    {/* Capability summary */}
                    {available ? (
                        <Card style={styles.infoCard}>
                            <View style={styles.infoTop}>
                                <View style={[styles.iconWrap, { backgroundColor: colors.primary + '22' }]}>
                                    <Icon name="shield-checkmark-outline" size={18} color={colors.primary} />
                                </View>
                                <Text style={styles.infoTitle}>Biometric unlock available</Text>
                            </View>
                            <Text style={styles.infoBody}>
                                {methods.length > 0
                                    ? `This device supports ${methods.join(', ')}.`
                                    : 'This device supports biometric authentication.'}
                            </Text>
                        </Card>
                    ) : (
                        <Card style={[styles.infoCard, styles.warnCard]}>
                            <View style={styles.infoTop}>
                                <View style={[styles.iconWrap, { backgroundColor: colors.warning + '22' }]}>
                                    <Icon name="warning-outline" size={18} color={colors.warning} />
                                </View>
                                <Text style={styles.infoTitle}>
                                    {!hasHw ? 'No biometric hardware' : 'No biometrics enrolled'}
                                </Text>
                            </View>
                            <Text style={styles.infoBody}>
                                {!hasHw
                                    ? 'This device has no biometric sensor, so App Lock cannot be enabled.'
                                    : 'Add a fingerprint, Face ID, or device passcode in your system settings to use App Lock.'}
                            </Text>
                        </Card>
                    )}

                    {/* App lock toggle */}
                    <Text style={styles.sectionLabel}>App lock</Text>
                    <Card style={styles.card}>
                        <View style={styles.row}>
                            <View style={styles.rowText}>
                                <Text style={styles.rowLabel}>App lock</Text>
                                <Text style={styles.rowSub}>
                                    Require biometric/passcode each time you open Wealthify
                                </Text>
                            </View>
                            <Switch
                                value={enabled}
                                onValueChange={handleToggle}
                                disabled={!available}
                                trackColor={{ true: colors.primary }}
                            />
                        </View>
                    </Card>

                    <PillButton
                        label="Test unlock"
                        variant="secondary"
                        onPress={handleTestUnlock}
                        disabled={!available}
                        leftIcon={<Icon name="finger-print-outline" size={18} color={colors.text} />}
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
        scroll: {
            paddingHorizontal: space.xl,
            paddingTop: space.sm,
            paddingBottom: space['3xl'],
        },
        infoCard: { gap: space.sm, marginBottom: space.lg },
        warnCard: {
            backgroundColor: colors.warningSoft,
            borderWidth: 1,
            borderColor: colors.warning + '55',
        },
        infoTop: { flexDirection: 'row', alignItems: 'center', gap: space.sm },
        iconWrap: {
            width: 32,
            height: 32,
            borderRadius: 16,
            alignItems: 'center',
            justifyContent: 'center',
        },
        infoTitle: { ...Typography.bodyMedium, color: colors.text, flex: 1 },
        infoBody: { ...Typography.bodySm, color: colors.textSubtle },
        sectionLabel: {
            ...Typography.label,
            color: colors.textSubtle,
            marginTop: space.xl,
            marginBottom: space.sm,
        },
        card: { gap: space.md },
        row: { flexDirection: 'row', alignItems: 'center' },
        rowText: { flex: 1, marginRight: space.md, gap: 2 },
        rowLabel: { ...Typography.bodyMedium, color: colors.text },
        rowSub: { ...Typography.bodySm, color: colors.textSubtle },
    });
