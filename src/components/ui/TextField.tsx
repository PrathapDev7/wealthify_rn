import React, { useMemo, useRef, useState } from 'react';
import {
    KeyboardTypeOptions,
    Pressable,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
    ViewStyle,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Typography, noWebOutline, radius, space, useColors, type ColorPalette } from '@/src/styles/theme';

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
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const inputRef = useRef<TextInput>(null);
    const [reveal, setReveal] = useState(false);
    const [focused, setFocused] = useState(false);
    const isSecure = !!secureTextEntry && !reveal;
    const focusInput = () => inputRef.current?.focus();
    const toggleReveal = () => {
        setReveal((v) => !v);
        focusInput();
    };

    return (
        <View style={[styles.wrap, style]}>
            {label ? <Text style={styles.label}>{label}</Text> : null}
            <Pressable
                onPress={focusInput}
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
                        color={colors.textSubtle}
                        style={styles.leftIcon}
                    />
                ) : null}
                <TextInput
                    ref={inputRef}
                    placeholder={placeholder}
                    placeholderTextColor={colors.textSubtle}
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
                    <TouchableOpacity
                        onPress={toggleReveal}
                        hitSlop={10}
                        focusable={false}
                    >
                        <Icon
                            name={reveal ? 'eye-outline' : 'eye-off-outline'}
                            size={20}
                            color={colors.textSubtle}
                        />
                    </TouchableOpacity>
                ) : null}
                {rightSlot}
            </Pressable>
            {error ? <Text style={styles.errorText}>{error}</Text> : null}
        </View>
    );
};

const makeStyles = (colors: ColorPalette) => StyleSheet.create({
    wrap: {
        width: '100%',
        marginBottom: space.lg,
    },
    label: {
        ...Typography.label,
        color: colors.textSubtle,
        marginBottom: space.sm,
    },
    field: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: colors.surface,
        borderWidth: 1.5,
        borderColor: colors.border,
        borderRadius: radius.md,
        paddingHorizontal: space.lg,
        height: 52,
    },
    fieldFocused: {
        borderColor: colors.primary,
    },
    fieldError: {
        borderColor: colors.negative,
    },
    fieldDisabled: {
        backgroundColor: colors.surfaceMuted,
    },
    leftIcon: {
        marginRight: space.sm,
    },
    input: {
        flex: 1,
        ...Typography.body,
        color: colors.text,
        paddingVertical: 0,
    },
    errorText: {
        ...Typography.caption,
        color: colors.negative,
        marginTop: space.xs,
    },
});

export default TextField;
