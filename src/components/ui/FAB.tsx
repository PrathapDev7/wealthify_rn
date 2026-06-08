import React from 'react';
import { StyleSheet, TouchableOpacity, ViewStyle } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { Shadows, useColors } from '@/src/styles/theme';

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
    bg,
    color,
    style,
}) => {
    const colors = useColors();
    const resolvedBg = bg ?? colors.fab;
    const resolvedColor = color ?? colors.textInverse;
    return (
    <TouchableOpacity
        activeOpacity={0.9}
        onPress={onPress}
        style={[
            styles.base,
            Shadows.fab,
            {
                backgroundColor: resolvedBg,
                width: size,
                height: size,
                borderRadius: size / 2,
            },
            style,
        ]}
    >
        <Icon name={iconName} size={Math.round(size * 0.42)} color={resolvedColor} />
    </TouchableOpacity>
    );
};

const styles = StyleSheet.create({
    base: {
        alignItems: 'center',
        justifyContent: 'center',
    },
});

export default FAB;
