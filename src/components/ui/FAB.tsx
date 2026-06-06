import React from 'react';
import { StyleSheet, TouchableOpacity, ViewStyle } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Colors, Shadows } from '@/src/styles/theme';

interface Props {
    onPress?: () => void;
    iconName?: string;
    size?: number;
    bg?: string;
    color?: string;
    style?: ViewStyle | ViewStyle[];
}

// Center floating action button. Lives inside the tab bar slot.
const FAB: React.FC<Props> = ({
    onPress,
    iconName = 'add',
    size = 60,
    bg = Colors.fab,
    color = Colors.textInverse,
    style,
}) => (
    <TouchableOpacity
        activeOpacity={0.9}
        onPress={onPress}
        style={[
            styles.base,
            Shadows.fab,
            {
                backgroundColor: bg,
                width: size,
                height: size,
                borderRadius: size / 2,
            },
            style,
        ]}
    >
        <Icon name={iconName} size={Math.round(size * 0.42)} color={color} />
    </TouchableOpacity>
);

const styles = StyleSheet.create({
    base: {
        alignItems: 'center',
        justifyContent: 'center',
    },
});

export default FAB;
