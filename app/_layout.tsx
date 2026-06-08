import {Stack} from "expo-router";
import "@/global.css";
import {Provider} from "react-redux";
import store from "@/src/redux/store";
import React, {useEffect, useRef, useState} from "react";
import {StatusBar} from 'expo-status-bar';
import {Animated, Easing, ImageSourcePropType, StyleSheet, Text, TextInput, View} from "react-native";
import {Fonts} from "@/src/styles/fonts";
import {GestureHandlerRootView} from "react-native-gesture-handler";
import {SafeAreaProvider} from "react-native-safe-area-context";
import {MD3LightTheme, MD3DarkTheme, Provider as PaperProvider} from 'react-native-paper';
import {ThemeProvider, useTheme} from '@/src/styles/ThemeContext';
import {PreferencesProvider} from '@/src/context/PreferencesContext';
import {AppLockGate} from '@/src/components/AppLockGate';
import Toast, {ToastConfigParams} from 'react-native-toast-message';
import Icon from 'react-native-vector-icons/Ionicons';
import * as SplashScreen from 'expo-splash-screen';
import {
    useFonts,
    Poppins_200ExtraLight,
    Poppins_300Light,
    Poppins_400Regular,
    Poppins_500Medium,
    Poppins_600SemiBold,
    Poppins_700Bold,
    Poppins_800ExtraBold,
} from '@expo-google-fonts/poppins';
import {remoteImage} from "@/assets/Constants/remoteAssets";
import {AppRefreshProvider} from "@/src/context/AppRefreshContext";

export const unstable_settings = {
    initialRouteName: 'index',
};

SplashScreen.preventAutoHideAsync().catch(() => {});

const animatedSplashIcon = remoteImage('assets/images/splash.png') as ImageSourcePropType;
const animatedSplashBackground = '#250066';

type TextComponentWithDefaults = typeof Text & {
    defaultProps?: {
        style?: unknown;
    };
};

const applyDefaultFont = (Component: TextComponentWithDefaults) => {
    Component.defaultProps = Component.defaultProps ?? {};
    Component.defaultProps.style = [
        Component.defaultProps.style,
        {fontFamily: Fonts.regular},
    ].filter(Boolean);
};

applyDefaultFont(Text);
applyDefaultFont(TextInput as TextComponentWithDefaults);

const WealthifyToast = ({type, text1, text2}: ToastConfigParams<any>) => {
    const {colors} = useTheme();

    const toastTone = {
        success: {icon: 'checkmark-circle', color: colors.accentDark, bg: colors.accentSoft},
        error: {icon: 'alert-circle', color: colors.negative, bg: colors.negativeSoft},
        info: {icon: 'information-circle', color: colors.primary, bg: colors.primarySoft},
    } as const;
    const tone = toastTone[type as keyof typeof toastTone] || toastTone.info;

    return (
        <View style={[styles.toast, {backgroundColor: colors.surface, borderColor: colors.border, shadowColor: colors.deepPurple}]}>
            <View style={[styles.toastIcon, {backgroundColor: tone.bg}]}>
                <Icon name={tone.icon} size={20} color={tone.color} />
            </View>
            <View style={styles.toastTextWrap}>
                <Text numberOfLines={1} style={[styles.toastTitle, {color: colors.text}]}>
                    {text1}
                </Text>
                {text2 ? (
                    <Text numberOfLines={2} style={[styles.toastBody, {color: colors.textSubtle}]}>
                        {text2}
                    </Text>
                ) : null}
            </View>
        </View>
    );
};

const toastConfig = {
    success: WealthifyToast,
    error: WealthifyToast,
    info: WealthifyToast,
};

const AnimatedSplashOverlay = ({play, onFinish}: {play: boolean; onFinish: () => void}) => {
    const overlayOpacity = useRef(new Animated.Value(1)).current;
    const iconOpacity = useRef(new Animated.Value(0)).current;
    const iconScale = useRef(new Animated.Value(0.92)).current;

    useEffect(() => {
        if (!play) {
            return;
        }

        const animation = Animated.sequence([
            Animated.parallel([
                Animated.timing(iconOpacity, {
                    toValue: 1,
                    duration: 460,
                    easing: Easing.out(Easing.cubic),
                    useNativeDriver: true,
                }),
                Animated.timing(iconScale, {
                    toValue: 1,
                    duration: 460,
                    easing: Easing.out(Easing.cubic),
                    useNativeDriver: true,
                }),
            ]),
            Animated.delay(520),
            Animated.parallel([
                Animated.timing(overlayOpacity, {
                    toValue: 0,
                    duration: 520,
                    easing: Easing.inOut(Easing.cubic),
                    useNativeDriver: true,
                }),
                Animated.timing(iconScale, {
                    toValue: 1.05,
                    duration: 520,
                    easing: Easing.inOut(Easing.cubic),
                    useNativeDriver: true,
                }),
            ]),
        ]);

        animation.start(({finished}) => {
            if (finished) {
                onFinish();
            }
        });

        return () => animation.stop();
    }, [iconOpacity, iconScale, onFinish, overlayOpacity, play]);

    return (
        <Animated.View
            pointerEvents="none"
            style={[styles.animatedSplash, {opacity: overlayOpacity}]}
        >
            <Animated.Image
                source={animatedSplashIcon}
                resizeMode="contain"
                style={[
                    styles.animatedSplashIcon,
                    {
                        opacity: iconOpacity,
                        transform: [{scale: iconScale}],
                    },
                ]}
            />
        </Animated.View>
    );
};

interface ThemedRootProps {
    appRefreshKey: number;
    onRequestRefresh: () => void;
    showAnimatedSplash: boolean;
    playAnimatedSplash: boolean;
    onSplashFinish: () => void;
}

const ThemedRoot = ({
    appRefreshKey,
    onRequestRefresh,
    showAnimatedSplash,
    playAnimatedSplash,
    onSplashFinish,
}: ThemedRootProps) => {
    const {isDark, colors} = useTheme();

    return (
        <PaperProvider theme={isDark ? MD3DarkTheme : MD3LightTheme}>
            <StatusBar style={showAnimatedSplash ? "light" : (isDark ? "light" : "dark")} />
            <AppRefreshProvider requestAppRefresh={onRequestRefresh}>
                <AppLockGate>
                    <Stack
                        key={appRefreshKey}
                        screenOptions={{
                            headerShown: false,
                            contentStyle: {backgroundColor: colors.background},
                        }}
                    />
                </AppLockGate>
            </AppRefreshProvider>
            <Toast
                config={toastConfig}
                position="bottom"
                bottomOffset={64}
                visibilityTime={2400}
            />
            {showAnimatedSplash ? (
                <AnimatedSplashOverlay
                    play={playAnimatedSplash}
                    onFinish={onSplashFinish}
                />
            ) : null}
        </PaperProvider>
    );
};

export default function RootLayout() {
    const [playAnimatedSplash, setPlayAnimatedSplash] = useState(false);
    const [showAnimatedSplash, setShowAnimatedSplash] = useState(true);
    const [appRefreshKey, setAppRefreshKey] = useState(0);
    const [fontsLoaded, fontError] = useFonts({
        Poppins_200ExtraLight,
        Poppins_300Light,
        Poppins_400Regular,
        Poppins_500Medium,
        Poppins_600SemiBold,
        Poppins_700Bold,
        Poppins_800ExtraBold,
    });

    useEffect(() => {
        if (fontsLoaded || fontError) {
            SplashScreen.hideAsync()
                .catch(() => {})
                .finally(() => {
                    setPlayAnimatedSplash(true);
                });
        }
    }, [fontsLoaded, fontError]);

    if (!fontsLoaded && !fontError) {
        return null;
    }

    return (
        <GestureHandlerRootView style={styles.container}>
            <SafeAreaProvider>
                <Provider store={store}>
                    <ThemeProvider>
                        <PreferencesProvider>
                            <ThemedRoot
                                appRefreshKey={appRefreshKey}
                                onRequestRefresh={() => setAppRefreshKey((key) => key + 1)}
                                showAnimatedSplash={showAnimatedSplash}
                                playAnimatedSplash={playAnimatedSplash}
                                onSplashFinish={() => setShowAnimatedSplash(false)}
                            />
                        </PreferencesProvider>
                    </ThemeProvider>
                </Provider>
            </SafeAreaProvider>
        </GestureHandlerRootView>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    animatedSplash: {
        ...StyleSheet.absoluteFillObject,
        zIndex: 9999,
        elevation: 9999,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: animatedSplashBackground,
    },
    animatedSplashIcon: {
        width: 286,
        height: 286,
    },
    toast: {
        width: '90%',
        minHeight: 66,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 14,
        paddingVertical: 12,
        borderRadius: 18,
        borderWidth: 1,
        shadowOffset: {width: 0, height: 14},
        shadowOpacity: 0.16,
        shadowRadius: 24,
        elevation: 10,
    },
    toastIcon: {
        width: 38,
        height: 38,
        borderRadius: 14,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 12,
    },
    toastTextWrap: {
        flex: 1,
    },
    toastTitle: {
        fontFamily: Fonts.semibold,
        fontSize: 14,
    },
    toastBody: {
        marginTop: 2,
        fontFamily: Fonts.regular,
        fontSize: 12,
        lineHeight: 17,
    },
});
