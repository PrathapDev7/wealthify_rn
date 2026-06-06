import React, { useState } from 'react';
import {
    KeyboardTypeOptions,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
    ViewStyle,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Colors, Typography, focusRing, noWebOutline, radius, space } from '@/src/styles/theme';

interface Props {
    label?: string;
    placeholder?: string;
    value: string;
    onChangeText: (text: string) => void;
    secureTextEntry?: boolean;
    keyboardType?: KeyboardTypeOptions;
    autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
    autoComplete?: any;
    leftIconName?: string;
    rightSlot?: React.ReactNode;
    style?: ViewStyle | ViewStyle[];
    error?: string;
    maxLength?: number;
    editable?: boolean;
}

const TextField: React.FC<Props> = ({
    label,
    placeholder,
    value,
    onChangeText,
    secureTextEntry,
    keyboardType,
    autoCapitalize = 'none',
    autoComplete,
    leftIconName,
    rightSlot,
    style,
    error,
    maxLength,
    editable = true,
}) => {
    const [reveal, setReveal] = useState(false);
    const [focused, setFocused] = useState(false);
    const isSecure = !!secureTextEntry && !reveal;

    return (
        <View style={[styles.wrap, style]}>
            {label ? <Text style={styles.label}>{label}</Text> : null}
            <View
                style={[
                    styles.field,
                    focused && styles.fieldFocused,
                    error ? styles.fieldError : null,
                    !editable && styles.fieldDisabled,
                ]}
            >
                {leftIconName ? (
                    <Icon
                        name={leftIconName}
                        size={18}
                        color={Colors.textSubtle}
                        style={styles.leftIcon}
                    />
                ) : null}
                <TextInput
                    placeholder={placeholder}
                    placeholderTextColor={Colors.textSubtle}
                    value={value}
                    onChangeText={onChangeText}
                    secureTextEntry={isSecure}
                    keyboardType={keyboardType}
                    autoCapitalize={autoCapitalize}
                    autoComplete={autoComplete}
                    maxLength={maxLength}
                    editable={editable}
                    onFocus={() => setFocused(true)}
                    onBlur={() => setFocused(false)}
                    style={[styles.input, noWebOutline]}
                />
                {secureTextEntry ? (
                    <TouchableOpacity onPress={() => setReveal((v) => !v)} hitSlop={10}>
                        <Icon
                            name={reveal ? 'eye-outline' : 'eye-off-outline'}
                            size={20}
                            color={Colors.textSubtle}
                        />
                    </TouchableOpacity>
                ) : null}
                {rightSlot}
            </View>
            {error ? <Text style={styles.errorText}>{error}</Text> : null}
        </View>
    );
};

const styles = StyleSheet.create({
    wrap: {
        width: '100%',
        marginBottom: space.lg,
    },
    label: {
        ...Typography.label,
        marginBottom: space.sm,
    },
    field: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.surface,
        borderWidth: 1,
        borderColor: Colors.border,
        borderRadius: radius.md,
        paddingHorizontal: space.lg,
        height: 52,
    },
    fieldFocused: {
        ...focusRing,
        borderWidth: 1.5,
    },
    fieldError: {
        borderColor: Colors.negative,
    },
    fieldDisabled: {
        backgroundColor: Colors.surfaceMuted,
    },
    leftIcon: {
        marginRight: space.sm,
    },
    input: {
        flex: 1,
        ...Typography.body,
        paddingVertical: 0,
    },
    errorText: {
        ...Typography.caption,
        color: Colors.negative,
        marginTop: space.xs,
    },
});

export default TextField;
