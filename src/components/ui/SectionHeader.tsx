import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View, ViewStyle } from 'react-native';
import { Colors, Fonts, Typography, space } from '@/src/styles/theme';

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
}) => (
    <View style={[styles.row, style]}>
        <Text style={styles.title}>{title}</Text>
        {actionLabel ? (
            <TouchableOpacity onPress={onActionPress} hitSlop={10}>
                <Text style={styles.action}>{actionLabel}</Text>
            </TouchableOpacity>
        ) : null}
    </View>
);

const styles = StyleSheet.create({
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
    },
    action: {
        ...Typography.bodyMedium,
        fontFamily: Fonts.medium,
        color: Colors.primaryGradientStart,
    },
});

export default SectionHeader;
