import React from 'react';
import { StyleSheet, TouchableOpacity, View, ViewStyle } from 'react-native';
import { Shadows, radius, space, useColors, useTheme } from '@/src/styles/theme';

type Elevation = 'none' | 'sm' | 'md' | 'lg';

interface Props {
    children: React.ReactNode;
    elevation?: Elevation;
    padding?: number;
    style?: ViewStyle | ViewStyle[];
    onPress?: () => void;
}

const Card: React.FC<Props> = ({
    children,
    elevation = 'sm',
    padding = space.lg,
    style,
    onPress,
}) => {
    const colors = useColors();
    const { isDark } = useTheme();

    const containerStyles = [
        styles.base,
        { backgroundColor: colors.surface },
        // Shadows barely register on a dark ground, so add a hairline border
        // to keep cards visually separated from the background.
        isDark && { borderWidth: StyleSheet.hairlineWidth, borderColor: colors.border },
        elevation !== 'none' && Shadows[elevation],
        { padding },
        style,
    ];

    if (onPress) {
        return (
            <TouchableOpacity activeOpacity={0.9} onPress={onPress} style={containerStyles}>
                {children}
            </TouchableOpacity>
        );
    }
    return <View style={containerStyles}>{children}</View>;
};

const styles = StyleSheet.create({
    base: {
        borderRadius: radius.md,
    },
});

export default Card;
