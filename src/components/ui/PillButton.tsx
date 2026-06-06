import React from 'react';
import {
    ActivityIndicator,
    StyleSheet,
    Text,
    TextStyle,
    TouchableOpacity,
    View,
    ViewStyle,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import {
    Colors,
    Fonts,
    Gradients,
    Shadows,
    Typography,
    radius,
    space,
} from '@/src/styles/theme';

type Variant = 'primary' | 'secondary' | 'ghost' | 'dark';
type Size = 'sm' | 'md' | 'lg';

interface Props {
    label: string;
    onPress?: () => void;
    variant?: Variant;
    size?: Size;
    loading?: boolean;
    disabled?: boolean;
    leftIcon?: React.ReactNode;
    rightIcon?: React.ReactNode;
    style?: ViewStyle | ViewStyle[];
    textStyle?: TextStyle | TextStyle[];
    fullWidth?: boolean;
}

const PillButton: React.FC<Props> = ({
    label,
    onPress,
    variant = 'primary',
    size = 'md',
    loading = false,
    disabled = false,
    leftIcon,
    rightIcon,
    style,
    textStyle,
    fullWidth = true,
}) => {
    const isDisabled = disabled || loading;
    const isPrimary = variant === 'primary';

    const containerStyles = [
        styles.base,
        sizeStyles[size],
        !isPrimary && variantStyles[variant].container,
        fullWidth && styles.fullWidth,
        isDisabled && styles.disabled,
        style,
    ];
    const labelStyles = [
        styles.label,
        sizeLabelStyles[size],
        variantStyles[variant].label,
        textStyle,
    ];
    const labelColor = (variantStyles[variant].label.color as string) || Colors.textInverse;

    const content = loading ? (
        <ActivityIndicator color={labelColor} />
    ) : (
        <View style={styles.inner}>
            {leftIcon ? <View style={styles.iconLeft}>{leftIcon}</View> : null}
            <Text style={labelStyles}>{label}</Text>
            {rightIcon ? <View style={styles.iconRight}>{rightIcon}</View> : null}
        </View>
    );

    if (isPrimary) {
        return (
            <TouchableOpacity
                activeOpacity={0.9}
                disabled={isDisabled}
                onPress={onPress}
                style={[
                    styles.primaryTouchable,
                    fullWidth && styles.fullWidth,
                    Shadows.primaryGlow,
                    isDisabled && styles.disabled,
                    style,
                ]}
            >
                <View style={styles.primaryClip}>
                    <LinearGradient
                        colors={Gradients.primary as any}
                        start={{ x: 0.5, y: 0 }}
                        end={{ x: 0.5, y: 1 }}
                        style={[styles.base, styles.primaryGradient, sizeStyles[size]]}
                    >
                        {content}
                    </LinearGradient>
                </View>
            </TouchableOpacity>
        );
    }

    return (
        <TouchableOpacity
            activeOpacity={0.85}
            disabled={isDisabled}
            onPress={onPress}
            style={containerStyles}
        >
            {content}
        </TouchableOpacity>
    );
};

const styles = StyleSheet.create({
    base: {
        borderRadius: radius.md,
        alignItems: 'center',
        justifyContent: 'center',
    },
    fullWidth: {
        width: '100%',
    },
    disabled: {
        opacity: 0.5,
    },
    primaryTouchable: {
        borderRadius: radius.md,
        backgroundColor: 'transparent',
    },
    primaryClip: {
        borderRadius: radius.md,
        overflow: 'hidden',
        backgroundColor: 'transparent',
    },
    primaryGradient: {
        borderRadius: radius.md,
        overflow: 'hidden',
    },
    inner: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
    },
    iconLeft: {
        marginRight: space.sm,
    },
    iconRight: {
        marginLeft: space.sm,
    },
    label: {
        ...Typography.button,
    },
});

const sizeStyles: Record<Size, ViewStyle> = {
    sm: { paddingVertical: 10, paddingHorizontal: space.lg, minHeight: 42 },
    md: { paddingVertical: 14, paddingHorizontal: space.xl, minHeight: 50 },
    lg: { paddingVertical: 16, paddingHorizontal: space['2xl'], minHeight: 52 },
};

const sizeLabelStyles: Record<Size, TextStyle> = {
    sm: { fontSize: 13 },
    md: { fontSize: 14 },
    lg: { fontSize: 14 },
};

const variantStyles: Record<Variant, { container: ViewStyle; label: TextStyle }> = {
    primary: {
        container: {}, // unused — rendered as LinearGradient
        label: { color: Colors.textInverse, fontFamily: Fonts.bold },
    },
    secondary: {
        container: {
            backgroundColor: Colors.surface,
            borderWidth: 1,
            borderColor: Colors.border,
            ...Shadows.sm,
        },
        label: { color: Colors.text, fontFamily: Fonts.bold },
    },
    ghost: {
        container: {
            backgroundColor: 'transparent',
        },
        label: { color: Colors.primary, fontFamily: Fonts.bold },
    },
    dark: {
        container: {
            backgroundColor: Colors.fab,
            ...Shadows.fab,
        },
        label: { color: Colors.textInverse, fontFamily: Fonts.bold },
    },
};

export default PillButton;
