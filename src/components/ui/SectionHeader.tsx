import React, { useMemo } from 'react';
import { StyleSheet, Text, TouchableOpacity, View, ViewStyle } from 'react-native';
import { Fonts, Typography, space, useColors, type ColorPalette } from '@/src/styles/theme';

interface Props {
    title: string;
    actionLabel?: string;
    onActionPress?: () => void;
    style?: ViewStyle | ViewStyle[];
}

// "Recent Transactions          See All" pattern
const SectionHeader: React.FC<Props> = ({
    title,
    actionLabel,
    onActionPress,
    style,
}) => {
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    return (
        <View style={[styles.row, style]}>
            <Text style={styles.title}>{title}</Text>
            {actionLabel ? (
                <TouchableOpacity onPress={onActionPress} hitSlop={10}>
                    <Text style={styles.action}>{actionLabel}</Text>
                </TouchableOpacity>
            ) : null}
        </View>
    );
};

const makeStyles = (colors: ColorPalette) => StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginTop: space.lg,
        marginBottom: space.sm,
    },
    title: {
        ...Typography.subtitle,
        fontFamily: Fonts.semibold,
        color: colors.text,
    },
    action: {
        ...Typography.bodyMedium,
        fontFamily: Fonts.medium,
        color: colors.primaryGradientStart,
    },
});

export default SectionHeader;
