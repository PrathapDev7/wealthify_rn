import React from 'react';
import { Text, View } from 'react-native';
import { StyleSheet } from 'react-native';
import CashioIcon from '@/src/components/ui/CashioIcon';
import GradientBackground from '@/src/components/ui/GradientBackground';
import { Colors, Fonts, Typography, space } from '@/src/styles/theme';

export function InitialLoader() {
    return (
        <GradientBackground style={styles.loadingContainer}>
            <View style={styles.brandRow}>
                <CashioIcon name="cashio_mark" size={34} />
                <Text style={styles.brandText}>Cashio</Text>
            </View>
        </GradientBackground>
    );
}

const styles = StyleSheet.create({
    loadingContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    brandRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: space.sm,
    },
    brandText: {
        ...Typography.titleLg,
        fontFamily: Fonts.extrabold,
        color: Colors.primary,
    },
});
