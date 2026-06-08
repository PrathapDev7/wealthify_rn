import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
    ActivityIndicator,
    AppState,
    AppStateStatus,
    Pressable,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as LocalAuthentication from 'expo-local-authentication';
import Icon from 'react-native-vector-icons/Ionicons';
import { Typography, radius, space, useColors } from '@/src/styles/theme';

const LOCK_KEY = 'wealthify_app_lock';

// Renders a full-screen lock overlay over its children whenever App Lock is
// enabled (Account → App Lock) and the app has just been foregrounded.
export const AppLockGate: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const colors = useColors();
    const [enabled, setEnabled] = useState(false);
    const [locked, setLocked] = useState(false);
    const [checking, setChecking] = useState(true);
    const [authing, setAuthing] = useState(false);
    const authingRef = useRef(false);
    const appState = useRef<AppStateStatus>(AppState.currentState);

    const readEnabled = useCallback(async () => {
        try {
            return (await AsyncStorage.getItem(LOCK_KEY)) === 'true';
        } catch {
            return false;
        }
    }, []);

    const authenticate = useCallback(async () => {
        if (authingRef.current) return;
        authingRef.current = true;
        setAuthing(true);
        try {
            const result = await LocalAuthentication.authenticateAsync({
                promptMessage: 'Unlock Wealthify',
            });
            if (result.success) setLocked(false);
        } catch {
            // leave locked; user can retry via the Unlock button
        } finally {
            authingRef.current = false;
            setAuthing(false);
        }
    }, []);

    useEffect(() => {
        (async () => {
            const en = await readEnabled();
            setEnabled(en);
            setLocked(en);
            setChecking(false);
            if (en) authenticate();
        })();
    }, [readEnabled, authenticate]);

    useEffect(() => {
        const sub = AppState.addEventListener('change', async (next: AppStateStatus) => {
            const prev = appState.current;
            appState.current = next;

            const en = await readEnabled();
            setEnabled(en);
            if (!en) {
                setLocked(false);
                return;
            }

            if (next === 'active' && /inactive|background/.test(prev)) {
                authenticate();
            } else if (/inactive|background/.test(next)) {
                setLocked(true);
            }
        });
        return () => sub.remove();
    }, [readEnabled, authenticate]);

    return (
        <View style={styles.flex}>
            {children}
            {enabled && locked && !checking ? (
                <View style={[styles.overlay, { backgroundColor: colors.background }]}>
                    <Icon name="lock-closed" size={52} color={colors.primary} />
                    <Text style={[styles.title, { ...Typography.title, color: colors.text }]}>
                        Wealthify is locked
                    </Text>
                    <Text style={[styles.subtitle, { ...Typography.bodySm, color: colors.textSubtle }]}>
                        Authenticate to continue
                    </Text>
                    <Pressable
                        style={[styles.btn, { backgroundColor: colors.primary }]}
                        onPress={authenticate}
                        disabled={authing}
                    >
                        {authing ? (
                            <ActivityIndicator color={colors.textInverse} />
                        ) : (
                            <Text style={[styles.btnText, { color: colors.textInverse }]}>Unlock</Text>
                        )}
                    </Pressable>
                </View>
            ) : null}
        </View>
    );
};

const styles = StyleSheet.create({
    flex: { flex: 1 },
    overlay: {
        ...StyleSheet.absoluteFillObject,
        zIndex: 10000,
        elevation: 10000,
        alignItems: 'center',
        justifyContent: 'center',
        paddingHorizontal: space.xl,
    },
    title: { marginTop: space.lg },
    subtitle: { marginTop: space.xs },
    btn: {
        marginTop: space['2xl'],
        paddingHorizontal: space['3xl'],
        paddingVertical: space.md,
        borderRadius: radius.pill,
        minWidth: 160,
        alignItems: 'center',
    },
    btnText: { ...Typography.button },
});

export default AppLockGate;
