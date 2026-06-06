import React, { useEffect, useState } from 'react';
import {
    KeyboardAvoidingView,
    Platform,
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useDispatch } from 'react-redux';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Toast from 'react-native-toast-message';
import { useRouter } from 'expo-router';
import APIService from '../../ApiService/api.service';
import { getUserData } from '../../redux/Actions/UserActions';
import {
    PillButton,
    ScreenContainer,
    TextField,
    CashioIcon,
} from '@/src/components/ui';
import { Colors, Fonts, Shadows, Typography, radius, space } from '@/src/styles/theme';

const api = new APIService();

type Mode = 'login' | 'register';

interface LoginData {
    mobile: string;
    password: string;
}
interface RegisterData {
    username: string;
    mobile: string;
    password: string;
    confirm_password: string;
}

const AuthScreen = () => {
    const dispatch: any = useDispatch();
    const router = useRouter();

    const [mode, setMode] = useState<Mode>('register');
    const [loading, setLoading] = useState(false);
    const [loginData, setLoginData] = useState<LoginData>({
        mobile: '',
        password: '',
    });
    const [registerData, setRegisterData] = useState<RegisterData>({
        username: '',
        mobile: '',
        password: '',
        confirm_password: '',
    });

    useEffect(() => {
        (async () => {
            const user = await AsyncStorage.getItem('wealthify_user');
            if (user) {
                dispatch(getUserData(JSON.parse(user)));
                router.replace('/dashboard');
            }
        })();
    }, []);

    const updateLogin = (key: keyof LoginData, value: string) =>
        setLoginData((prev) => ({ ...prev, [key]: value }));

    const updateRegister = (key: keyof RegisterData, value: string) =>
        setRegisterData((prev) => ({ ...prev, [key]: value }));

    const toast = (text1: string, type: 'error' | 'success' = 'error') =>
        Toast.show({ type, text1 });

    const handleSubmit = async () => {
        if (mode === 'register') {
            const { username, mobile, password, confirm_password } = registerData;
            if (!username || !mobile || !password || !confirm_password) {
                return toast('All fields are required');
            }
            if (password !== confirm_password) {
                return toast('Passwords do not match');
            }
        } else {
            if (!loginData.mobile || !loginData.password) {
                return toast('Enter mobile and password');
            }
        }

        setLoading(true);
        try {
            const res =
                mode === 'register'
                    ? await api.register(registerData)
                    : await api.login(loginData);

            if (res.data) {
                await AsyncStorage.setItem('wealthify_token', res.data.token);
                await AsyncStorage.setItem(
                    'wealthify_user',
                    JSON.stringify(res.data.data),
                );
                dispatch(getUserData(res.data.data));
                toast(mode === 'register' ? 'Account created!' : 'Welcome back!', 'success');
                router.replace('/dashboard');
            }
        } catch (err: any) {
            toast(err.response?.data?.message || 'Something went wrong');
        } finally {
            setLoading(false);
        }
    };

    const swapMode = () => setMode((m) => (m === 'login' ? 'register' : 'login'));

    const isRegister = mode === 'register';

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : undefined}
                style={styles.flex}
            >
                <ScrollView
                    contentContainerStyle={styles.scroll}
                    keyboardShouldPersistTaps="handled"
                    showsVerticalScrollIndicator={false}
                >
                    <View style={styles.header}>
                        <View style={styles.lockTile}>
                            <CashioIcon name="auth_lock" size={30} />
                        </View>
                        <Text style={styles.title}>
                            {isRegister
                                ? 'Get Started with Cashio'
                                : 'Welcome back'}
                        </Text>
                        <Text style={styles.subtitle}>
                            {isRegister
                                ? 'Create your secure wallet in just a few steps.'
                                : 'Log in to keep your finances on track.'}
                        </Text>
                    </View>

                    <View style={styles.form}>
                        {isRegister && (
                            <TextField
                                label="Full name"
                                placeholder="Your name"
                                value={registerData.username}
                                onChangeText={(t) => updateRegister('username', t)}
                                autoCapitalize="words"
                                leftIconName="person-outline"
                            />
                        )}

                        <TextField
                            label={isRegister ? 'Email' : 'Mobile number'}
                            placeholder={isRegister ? 'Enter email' : '10-digit mobile'}
                            value={isRegister ? registerData.mobile : loginData.mobile}
                            onChangeText={(t) =>
                                isRegister
                                    ? updateRegister('mobile', t)
                                    : updateLogin('mobile', t)
                            }
                            keyboardType={isRegister ? 'email-address' : 'phone-pad'}
                            leftIconName={isRegister ? undefined : 'call-outline'}
                            maxLength={isRegister ? undefined : 15}
                        />

                        <TextField
                            label="Password"
                            placeholder="Enter password"
                            value={isRegister ? registerData.password : loginData.password}
                            onChangeText={(t) =>
                                isRegister
                                    ? updateRegister('password', t)
                                    : updateLogin('password', t)
                            }
                            secureTextEntry
                            leftIconName="lock-closed-outline"
                        />

                        {isRegister && (
                            <TextField
                                label="Confirm password"
                                placeholder="Re-enter password"
                                value={registerData.confirm_password}
                                onChangeText={(t) => updateRegister('confirm_password', t)}
                                secureTextEntry
                                leftIconName="lock-closed-outline"
                            />
                        )}

                        <PillButton
                            label={isRegister ? 'Sign Up' : 'Log In'}
                            onPress={handleSubmit}
                            loading={loading}
                            size="lg"
                            style={styles.cta}
                        />

                        {isRegister ? (
                            <>
                                <View style={styles.orRow}>
                                    <View style={styles.orLine} />
                                    <Text style={styles.orText}>Or</Text>
                                    <View style={styles.orLine} />
                                </View>
                                <View style={styles.socialRow}>
                                    <TouchableOpacity style={styles.socialButton} activeOpacity={0.85}>
                                        <Icon name="logo-apple" size={16} color={Colors.text} />
                                        <Text style={styles.socialText}>Apple</Text>
                                    </TouchableOpacity>
                                    <TouchableOpacity style={styles.socialButton} activeOpacity={0.85}>
                                        <Icon name="logo-google" size={16} color={Colors.text} />
                                        <Text style={styles.socialText}>Google</Text>
                                    </TouchableOpacity>
                                </View>
                            </>
                        ) : null}

                        <View style={styles.swapRow}>
                            <Text style={styles.swapText}>
                                {isRegister
                                    ? 'Already have an account?'
                                    : "Don't have an account?"}
                            </Text>
                            <TouchableOpacity onPress={swapMode} hitSlop={10}>
                                <Text style={styles.swapLink}>
                                    {isRegister ? ' Log In' : ' Sign Up'}
                                </Text>
                            </TouchableOpacity>
                        </View>
                    </View>

                    <Text style={styles.legal}>
                        By continuing, you agree to our{' '}
                        <Text style={styles.legalLink}>Terms</Text>{' '}
                        and <Text style={styles.legalLink}>Privacy Policy</Text>.
                    </Text>
                </ScrollView>
            </KeyboardAvoidingView>
        </ScreenContainer>
    );
};

const styles = StyleSheet.create({
    flex: { flex: 1 },
    scroll: {
        flexGrow: 1,
        paddingHorizontal: space.xl,
        paddingTop: space['2xl'],
        paddingBottom: space['3xl'],
    },
    header: {
        alignItems: 'center',
        marginTop: space.xl,
        marginBottom: space['2xl'],
    },
    lockTile: {
        width: 44,
        height: 44,
        borderRadius: 22,
        backgroundColor: 'rgba(255,255,255,0.72)',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: space.md,
    },
    title: {
        ...Typography.titleLg,
        textAlign: 'center',
        marginBottom: space.xs,
    },
    subtitle: {
        ...Typography.body,
        color: Colors.textMuted,
        textAlign: 'center',
    },
    form: {
        marginTop: space.sm,
    },
    cta: {
        marginTop: space.sm,
    },
    orRow: {
        flexDirection: 'row',
        alignItems: 'center',
        marginVertical: space.lg,
        gap: space.md,
    },
    orLine: {
        flex: 1,
        height: 1,
        backgroundColor: Colors.divider,
    },
    orText: {
        ...Typography.caption,
        color: Colors.textSubtle,
    },
    socialRow: {
        flexDirection: 'row',
        gap: space.md,
    },
    socialButton: {
        flex: 1,
        minHeight: 46,
        borderRadius: radius.md,
        backgroundColor: Colors.surface,
        alignItems: 'center',
        justifyContent: 'center',
        flexDirection: 'row',
        gap: space.sm,
        ...Shadows.xs,
    },
    socialText: {
        ...Typography.bodyMedium,
        fontSize: 12,
    },
    swapRow: {
        flexDirection: 'row',
        justifyContent: 'center',
        marginTop: space.xl,
    },
    swapText: {
        ...Typography.body,
        color: Colors.textMuted,
    },
    swapLink: {
        ...Typography.body,
        fontFamily: Fonts.semibold,
        color: Colors.primary,
    },
    legal: {
        ...Typography.caption,
        textAlign: 'center',
        marginTop: 'auto',
        paddingTop: space.xl,
        color: Colors.textSubtle,
    },
    legalLink: {
        fontFamily: Fonts.medium,
        color: Colors.primary,
    },
});

export default AuthScreen;
