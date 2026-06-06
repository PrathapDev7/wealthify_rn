import React from 'react';
import { StyleSheet, View, ViewStyle } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { Colors } from '@/src/styles/theme';
import GradientBackground from './GradientBackground';

type Variant = 'plain' | 'wash' | 'primary';

interface Props {
    children: React.ReactNode;
    variant?: Variant;
    statusBarStyle?: 'light' | 'dark' | 'auto';
    edges?: ('top' | 'bottom' | 'left' | 'right')[];
    style?: ViewStyle | ViewStyle[];
    contentStyle?: ViewStyle | ViewStyle[];
    /** When true, the gradient extends edge-to-edge behind the safe area. */
    extendUnderStatusBar?: boolean;
}

// Common screen wrapper — handles background, safe area, status bar.
const ScreenContainer: React.FC<Props> = ({
    children,
    variant = 'plain',
    statusBarStyle = 'dark',
    edges = ['top', 'bottom', 'left', 'right'],
    style,
    contentStyle,
    extendUnderStatusBar = false,
}) => {
    if (variant === 'plain') {
        return (
            <SafeAreaView edges={edges} style={[styles.root, style]}>
                <StatusBar style={statusBarStyle} />
                <View style={[styles.content, contentStyle]}>{children}</View>
            </SafeAreaView>
        );
    }

    if (extendUnderStatusBar) {
        return (
            <View style={[styles.root, style]}>
                <StatusBar style={statusBarStyle} />
                <GradientBackground variant={variant} style={StyleSheet.absoluteFill as any} />
                <SafeAreaView edges={edges} style={styles.flex}>
                    <View style={[styles.content, contentStyle]}>{children}</View>
                </SafeAreaView>
            </View>
        );
    }

    return (
        <SafeAreaView edges={edges} style={[styles.root, style]}>
            <StatusBar style={statusBarStyle} />
            <GradientBackground variant={variant} style={StyleSheet.absoluteFill as any} />
            <View style={[styles.content, contentStyle]}>{children}</View>
        </SafeAreaView>
    );
};

const styles = StyleSheet.create({
    root: {
        flex: 1,
        backgroundColor: Colors.background,
    },
    flex: {
        flex: 1,
    },
    content: {
        flex: 1,
    },
});

export default ScreenContainer;
