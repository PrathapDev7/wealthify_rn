import React, { useEffect, useRef } from 'react';
import {
    Animated,
    Easing,
    type DimensionValue,
    StyleSheet,
    type ViewStyle,
} from 'react-native';

type SkeletonBlockProps = {
    width?: DimensionValue;
    height?: DimensionValue;
    radius?: number;
    style?: ViewStyle | ViewStyle[];
};

const SkeletonBlock: React.FC<SkeletonBlockProps> = ({
    width = '100%',
    height = 16,
    radius = 8,
    style,
}) => {
    const opacity = useRef(new Animated.Value(0.58)).current;

    useEffect(() => {
        const animation = Animated.loop(
            Animated.sequence([
                Animated.timing(opacity, {
                    toValue: 1,
                    duration: 760,
                    easing: Easing.inOut(Easing.ease),
                    useNativeDriver: true,
                }),
                Animated.timing(opacity, {
                    toValue: 0.58,
                    duration: 760,
                    easing: Easing.inOut(Easing.ease),
                    useNativeDriver: true,
                }),
            ]),
        );
        animation.start();

        return () => animation.stop();
    }, [opacity]);

    return (
        <Animated.View
            style={[
                styles.block,
                {
                    width,
                    height,
                    borderRadius: radius,
                    opacity,
                },
                style,
            ]}
        />
    );
};

const styles = StyleSheet.create({
    block: {
        backgroundColor: '#E7E0F0',
        overflow: 'hidden',
    },
});

export default SkeletonBlock;
