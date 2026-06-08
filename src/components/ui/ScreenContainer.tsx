import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from 'react';
import {
    Animated,
    Easing,
    PanResponder,
    StyleSheet,
    View,
    ViewStyle,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import Icon from 'react-native-vector-icons/Ionicons';
import { useColors, type ColorPalette } from '@/src/styles/theme';
import { useAppRefresh } from '@/src/context/AppRefreshContext';
import GradientBackground from './GradientBackground';

type Variant = 'plain' | 'wash' | 'primary';
const REFRESH_TRIGGER_DISTANCE = 88;
const MAX_PULL_DISTANCE = 112;

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
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { requestAppRefresh } = useAppRefresh();
    const [refreshReady, setRefreshReady] = useState(false);
    const refreshReadyRef = useRef(false);
    const refreshComplete = useRef(false);
    const pullDistance = useRef(new Animated.Value(0)).current;
    const spin = useRef(new Animated.Value(0)).current;

    const resetPullRefresh = useCallback(() => {
        refreshReadyRef.current = false;
        refreshComplete.current = false;
        setRefreshReady(false);
        Animated.spring(pullDistance, {
            toValue: 0,
            useNativeDriver: true,
        }).start();
    }, [pullDistance]);

    const setPullRefreshReady = useCallback((ready: boolean) => {
        if (refreshReadyRef.current === ready) return;
        refreshReadyRef.current = ready;
        setRefreshReady(ready);
    }, []);

    useEffect(() => {
        if (!refreshReady) {
            spin.stopAnimation();
            spin.setValue(0);
            return;
        }

        const animation = Animated.loop(
            Animated.timing(spin, {
                toValue: 1,
                duration: 900,
                easing: Easing.linear,
                useNativeDriver: true,
            }),
        );

        animation.start();
        return () => animation.stop();
    }, [refreshReady, spin]);

    const panResponder = useMemo(
        () =>
            PanResponder.create({
                onMoveShouldSetPanResponderCapture: (_, gestureState) => {
                    const startedNearTop = gestureState.y0 <= 118;
                    const isPullingDown = gestureState.dy > 14;
                    const isMostlyVertical =
                        Math.abs(gestureState.dy) > Math.abs(gestureState.dx) * 1.4;
                    return startedNearTop && isPullingDown && isMostlyVertical;
                },
                onPanResponderMove: (_, gestureState) => {
                    if (gestureState.dy <= 0) return;

                    pullDistance.setValue(
                        Math.min(gestureState.dy, MAX_PULL_DISTANCE),
                    );
                    setPullRefreshReady(
                        gestureState.dy >= REFRESH_TRIGGER_DISTANCE,
                    );
                },
                onPanResponderRelease: () => {
                    if (refreshReadyRef.current && !refreshComplete.current) {
                        refreshComplete.current = true;
                        requestAppRefresh();
                        return;
                    }
                    resetPullRefresh();
                },
                onPanResponderTerminate: () => {
                    resetPullRefresh();
                },
            }),
        [pullDistance, requestAppRefresh, resetPullRefresh, setPullRefreshReady],
    );

    const refreshRotate = spin.interpolate({
        inputRange: [0, 1],
        outputRange: ['0deg', '360deg'],
    });
    const refreshOpacity = pullDistance.interpolate({
        inputRange: [0, 12, REFRESH_TRIGGER_DISTANCE],
        outputRange: [0, 0.75, 1],
        extrapolate: 'clamp',
    });

    const renderContent = () => (
        <View
            style={[styles.content, contentStyle]}
            {...panResponder.panHandlers}
        >
            {children}
            <Animated.View
                pointerEvents="none"
                style={[
                    styles.refreshIndicator,
                    {
                        opacity: refreshOpacity,
                        transform: [
                            {
                                translateY: pullDistance.interpolate({
                                    inputRange: [0, MAX_PULL_DISTANCE],
                                    outputRange: [-18, 18],
                                    extrapolate: 'clamp',
                                }),
                            },
                        ],
                    },
                ]}
            >
                <Animated.View style={{ transform: [{ rotate: refreshRotate }] }}>
                    <Icon name="refresh" size={20} color={colors.primary} />
                </Animated.View>
            </Animated.View>
        </View>
    );

    if (variant === 'plain') {
        return (
            <SafeAreaView edges={edges} style={[styles.root, style]}>
                <StatusBar style={statusBarStyle} />
                {renderContent()}
            </SafeAreaView>
        );
    }

    if (extendUnderStatusBar) {
        return (
            <View style={[styles.root, style]}>
                <StatusBar style={statusBarStyle} />
                <GradientBackground variant={variant} style={StyleSheet.absoluteFill as any} />
                <SafeAreaView edges={edges} style={styles.flex}>
                    {renderContent()}
                </SafeAreaView>
            </View>
        );
    }

    return (
        <SafeAreaView edges={edges} style={[styles.root, style]}>
            <StatusBar style={statusBarStyle} />
            <GradientBackground variant={variant} style={StyleSheet.absoluteFill as any} />
            {renderContent()}
        </SafeAreaView>
    );
};

const makeStyles = (colors: ColorPalette) => StyleSheet.create({
    root: {
        flex: 1,
        backgroundColor: colors.background,
    },
    flex: {
        flex: 1,
    },
    content: {
        flex: 1,
    },
    refreshIndicator: {
        position: 'absolute',
        top: 8,
        alignSelf: 'center',
        width: 38,
        height: 38,
        borderRadius: 19,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: colors.surface,
        borderWidth: 1,
        borderColor: colors.border,
        shadowColor: colors.deepPurple,
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.12,
        shadowRadius: 16,
        elevation: 8,
        zIndex: 50,
    },
});

export default ScreenContainer;
