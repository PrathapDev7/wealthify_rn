import React from 'react';
import { StyleSheet, View, ViewStyle } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Colors, Shadows, radius } from '@/src/styles/theme';
import CashioIcon, { resolveCashioIconName } from './CashioIcon';

interface Props {
    name: string;
    color?: string;
    bg?: string;
    size?: number;
    iconSize?: number;
    rounded?: 'square' | 'circle';
    elevated?: boolean;
    style?: ViewStyle | ViewStyle[];
}

// Square or circular chip with a centered colored glyph.
// Used for category icons across the app.
const IconBadge: React.FC<Props> = ({
    name,
    color = Colors.primary,
    bg = Colors.surface,
    size = 44,
    iconSize,
    rounded = 'square',
    elevated = true,
    style,
}) => {
    const computedRadius = rounded === 'circle' ? size / 2 : radius.md;
    const cashioName = resolveCashioIconName(name);
    return (
        <View
            style={[
                styles.base,
                elevated && Shadows.xs,
                {
                    backgroundColor: bg,
                    width: size,
                    height: size,
                    borderRadius: computedRadius,
                },
                style,
            ]}
        >
            {cashioName ? (
                <CashioIcon name={cashioName} size={iconSize ?? Math.round(size * 0.52)} />
            ) : (
                <Icon name={name} size={iconSize ?? Math.round(size * 0.5)} color={color} />
            )}
        </View>
    );
};

const styles = StyleSheet.create({
    base: {
        alignItems: 'center',
        justifyContent: 'center',
    },
});

export default IconBadge;
