import React, { useMemo } from 'react';
import { StyleSheet, Text, TouchableOpacity, View, ViewStyle } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Fonts, Shadows, Typography, radius, space, useColors, type ColorPalette } from '@/src/styles/theme';
import WealthifyIcon, { resolveWealthifyIconName } from './WealthifyIcon';

interface Props {
    label: string;
    iconName?: string;
    iconColor?: string;
    selected?: boolean;
    onPress?: () => void;
    style?: ViewStyle | ViewStyle[];
}

// White rounded-pill with a colored leading dot/icon — used for category selection
// strips below the amount input in Add Expense/Income.
const Chip: React.FC<Props> = ({
    label,
    iconName,
    iconColor,
    selected,
    onPress,
    style,
}) => {
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const resolvedIconColor = iconColor ?? colors.primary;
    const wealthifyName = resolveWealthifyIconName(iconName);
    return (
        <TouchableOpacity
            activeOpacity={onPress ? 0.85 : 1}
            onPress={onPress}
            style={[
                styles.base,
                selected && styles.selected,
                Shadows.xs,
                style,
            ]}
        >
            {iconName ? (
                <View style={[styles.iconWrap, { backgroundColor: `${resolvedIconColor}1A` }]}>
                    {wealthifyName ? (
                        <WealthifyIcon name={wealthifyName} size={18} />
                    ) : (
                        <Icon name={iconName} size={16} color={resolvedIconColor} />
                    )}
                </View>
            ) : null}
            <Text style={[styles.label, selected && styles.labelSelected]}>{label}</Text>
        </TouchableOpacity>
    );
};

const makeStyles = (colors: ColorPalette) => StyleSheet.create({
    base: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: colors.surface,
        borderRadius: radius.pill,
        paddingVertical: 10,
        paddingHorizontal: space.md,
        borderWidth: 1,
        borderColor: colors.border,
        alignSelf: 'flex-start',
    },
    selected: {
        backgroundColor: colors.primarySoft,
        borderColor: colors.primary,
    },
    iconWrap: {
        width: 24,
        height: 24,
        borderRadius: 12,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: space.sm,
    },
    label: {
        ...Typography.bodySm,
        fontFamily: Fonts.medium,
        fontSize: 14,
        color: colors.text,
    },
    labelSelected: {
        fontFamily: Fonts.medium,
        color: colors.primary,
    },
});

export default Chip;
