import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Colors, Fonts, Typography, radius, space } from '@/src/styles/theme';

const KEYS = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'backspace'],
] as const;

const LETTERS: Record<string, string> = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
};

interface Props {
    onDigit: (digit: string) => void;
    onBackspace: () => void;
    style?: any;
}

const NumericKeypad: React.FC<Props> = ({ onDigit, onBackspace, style }) => (
    <View style={[styles.wrap, style]}>
        {KEYS.map((row, rowIndex) => (
            <View key={rowIndex} style={styles.row}>
                {row.map((key) => {
                    if (!key) return <View key="empty" style={styles.key} />;
                    const isBackspace = key === 'backspace';
                    return (
                        <TouchableOpacity
                            key={key}
                            activeOpacity={0.75}
                            style={styles.key}
                            onPress={() => (isBackspace ? onBackspace() : onDigit(key))}
                        >
                            {isBackspace ? (
                                <Icon name="backspace-outline" size={20} color={Colors.text} />
                            ) : (
                                <>
                                    <Text style={styles.number}>{key}</Text>
                                    <Text style={styles.letters}>{LETTERS[key] || ''}</Text>
                                </>
                            )}
                        </TouchableOpacity>
                    );
                })}
            </View>
        ))}
    </View>
);

const styles = StyleSheet.create({
    wrap: {
        backgroundColor: Colors.surface,
        borderTopWidth: 1,
        borderTopColor: Colors.divider,
        paddingHorizontal: space.xl,
        paddingTop: space.xs,
        paddingBottom: space.sm,
    },
    row: {
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    key: {
        flex: 1,
        minHeight: 54,
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: radius.xs,
    },
    number: {
        ...Typography.title,
        fontFamily: Fonts.medium,
        fontSize: 22,
        lineHeight: 25,
    },
    letters: {
        ...Typography.caption,
        fontFamily: Fonts.bold,
        fontSize: 9,
        lineHeight: 11,
        color: Colors.text,
    },
});

export default NumericKeypad;
