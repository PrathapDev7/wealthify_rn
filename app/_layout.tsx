import {Stack} from "expo-router";
import "@/global.css";
import {Provider} from "react-redux";
import store from "@/src/redux/store";
import React, {useEffect} from "react";
import {StatusBar} from 'expo-status-bar';
import {Colors} from "@/src/styles/colors";
import {StyleSheet, Text, TextInput, View} from "react-native";
import {Fonts} from "@/src/styles/fonts";
import {GestureHandlerRootView} from "react-native-gesture-handler";
import {SafeAreaProvider} from "react-native-safe-area-context";
import {MD3LightTheme as DefaultTheme, Provider as PaperProvider} from 'react-native-paper';
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

export const unstable_settings = {
    initialRouteName: 'index',
};

SplashScreen.preventAutoHideAsync().catch(() => {});

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

const toastTone = {
    success: {
        icon: 'checkmark-circle',
        color: Colors.accentDark,
        bg: Colors.accentSoft,
    },
    error: {
        icon: 'alert-circle',
        color: Colors.negative,
        bg: Colors.negativeSoft,
    },
    info: {
        icon: 'information-circle',
        color: Colors.primary,
        bg: Colors.primarySoft,
    },
} as const;

const CashioToast = ({type, text1, text2}: ToastConfigParams<any>) => {
    const tone = toastTone[type as keyof typeof toastTone] || toastTone.info;

    return (
        <View style={styles.toast}>
            <View style={[styles.toastIcon, {backgroundColor: tone.bg}]}>
                <Icon name={tone.icon} size={20} color={tone.color} />
            </View>
            <View style={styles.toastTextWrap}>
                <Text numberOfLines={1} style={styles.toastTitle}>
                    {text1}
                </Text>
                {text2 ? (
                    <Text numberOfLines={2} style={styles.toastBody}>
                        {text2}
                    </Text>
                ) : null}
            </View>
        </View>
    );
};

const toastConfig = {
    success: CashioToast,
    error: CashioToast,
    info: CashioToast,
};

export default function RootLayout() {
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
            SplashScreen.hideAsync().catch(() => {});
        }
    }, [fontsLoaded, fontError]);

    if (!fontsLoaded && !fontError) {
        return null;
    }

    return (
        <GestureHandlerRootView style={styles.container}>
            <SafeAreaProvider>
                <Provider store={store}>
                    <PaperProvider theme={DefaultTheme}>
                        <StatusBar style="dark" />
                        <Stack screenOptions={{headerShown: false, contentStyle: {backgroundColor: Colors.background}}}/>
                        <Toast
                            config={toastConfig}
                            position="bottom"
                            bottomOffset={64}
                            visibilityTime={2400}
                        />
                    </PaperProvider>
                </Provider>
            </SafeAreaProvider>
        </GestureHandlerRootView>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    toast: {
        width: '90%',
        minHeight: 66,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 14,
        paddingVertical: 12,
        borderRadius: 18,
        backgroundColor: Colors.surface,
        borderWidth: 1,
        borderColor: Colors.border,
        shadowColor: Colors.deepPurple,
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
        color: Colors.text,
    },
    toastBody: {
        marginTop: 2,
        fontFamily: Fonts.regular,
        fontSize: 12,
        lineHeight: 17,
        color: Colors.textSubtle,
    },
});
