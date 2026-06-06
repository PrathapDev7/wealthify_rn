import React from 'react';
import { StyleSheet, TouchableOpacity, View, ViewStyle } from 'react-native';
import { Colors, Shadows, radius, space } from '@/src/styles/theme';

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
    const containerStyles = [
        styles.base,
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
        backgroundColor: Colors.surface,
        borderRadius: radius.md,
    },
});

export default Card;
