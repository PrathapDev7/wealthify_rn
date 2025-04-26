import {Stack, useRouter} from "expo-router";
import {Provider} from "react-redux";
import store from "@/src/redux/store";
import React, {useEffect} from "react";
import {StatusBar} from 'expo-status-bar';
import {Colors} from "@/src/styles/colors";
import {StyleSheet} from "react-native";
import {GestureHandlerRootView} from "react-native-gesture-handler";
import {MD3LightTheme as DefaultTheme, Provider as PaperProvider} from 'react-native-paper';
import Toast from 'react-native-toast-message';

export const unstable_settings = {
    initialRouteName: 'index',
};

export default function RootLayout() {

    return (
        <GestureHandlerRootView style={styles.container}>
            <Provider store={store}>
                <PaperProvider theme={DefaultTheme}>
                    <StatusBar style="light" backgroundColor={Colors.primary}/>
                    <Stack screenOptions={{headerShown: false}}/>
                    <Toast />
                </PaperProvider>
            </Provider>
        </GestureHandlerRootView>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
});
