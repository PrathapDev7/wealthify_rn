import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View, ViewStyle } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Colors, Fonts, Shadows, Typography, radius, space } from '@/src/styles/theme';
import CashioIcon, { resolveCashioIconName } from './CashioIcon';

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
    iconColor = Colors.primary,
    selected,
    onPress,
    style,
}) => {
    const cashioName = resolveCashioIconName(iconName);
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
                <View style={[styles.iconWrap, { backgroundColor: `${iconColor}1A` }]}>
                    {cashioName ? (
                        <CashioIcon name={cashioName} size={18} />
                    ) : (
                        <Icon name={iconName} size={16} color={iconColor} />
                    )}
                </View>
            ) : null}
            <Text style={[styles.label, selected && styles.labelSelected]}>{label}</Text>
        </TouchableOpacity>
    );
};

const styles = StyleSheet.create({
    base: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.surface,
        borderRadius: radius.pill,
        paddingVertical: 10,
        paddingHorizontal: space.md,
        borderWidth: 1,
        borderColor: Colors.border,
        alignSelf: 'flex-start',
    },
    selected: {
        backgroundColor: Colors.primarySoft,
        borderColor: Colors.primary,
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
        color: Colors.text,
    },
    labelSelected: {
        fontFamily: Fonts.medium,
        color: Colors.primary,
    },
});

export default Chip;
