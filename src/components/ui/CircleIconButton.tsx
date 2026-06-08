import React from 'react';
import { StyleSheet, TouchableOpacity, ViewStyle } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Shadows, useColors } from '@/src/styles/theme';
import WealthifyIcon, { resolveWealthifyIconName } from './WealthifyIcon';

interface Props {
    name: string;
    onPress?: () => void;
    color?: string;
    bg?: string;
    size?: number;
    iconSize?: number;
    icon?: React.ReactNode;
    style?: ViewStyle | ViewStyle[];
}

// Round white button for top-of-screen actions (settings cog, bell, back chevron).
const CircleIconButton: React.FC<Props> = ({
    name,
    onPress,
    color,
    bg,
    size = 40,
    iconSize,
    icon,
    style,
}) => {
    const colors = useColors();
    const resolvedColor = color ?? colors.text;
    const resolvedBg = bg ?? colors.surface;
    const wealthifyName = resolveWealthifyIconName(name);
    return (
        <TouchableOpacity
            activeOpacity={0.85}
            onPress={onPress}
            style={[
                styles.base,
                Shadows.sm,
                {
                    backgroundColor: resolvedBg,
                    width: size,
                    height: size,
                    borderRadius: size / 2,
                },
                style,
            ]}
        >
            {icon ? (
                icon
            ) : wealthifyName ? (
                <WealthifyIcon name={wealthifyName} size={iconSize ?? Math.round(size * 0.54)} />
            ) : (
                <Icon name={name} size={iconSize ?? Math.round(size * 0.5)} color={resolvedColor} />
            )}
        </TouchableOpacity>
    );
};

const styles = StyleSheet.create({
    base: {
        alignItems: 'center',
        justifyContent: 'center',
    },
});

export default CircleIconButton;
