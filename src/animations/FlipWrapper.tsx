// components/FlipWrapper.js
import React, { useEffect } from 'react';
import Animated, {
    useSharedValue,
    useAnimatedStyle,
    withTiming
} from 'react-native-reanimated';

const FlipWrapper = ({ children, direction = 'in', duration = 600 }) => {
    const rotate = useSharedValue(direction === 'in' ? 180 : 0);

    useEffect(() => {
        if (direction === 'in') {
            rotate.value = withTiming(0, { duration });
        } else {
            rotate.value = withTiming(180, { duration });
        }
    }, [direction]);

    const animatedStyle = useAnimatedStyle(() => {
        return {
            transform: [
                {
                    rotateY: `${rotate.value}deg`,
                },
            ],
            backfaceVisibility: 'hidden',
        };
    });

    return (
        <Animated.View style={animatedStyle}>
            {children}
        </Animated.View>
    );
};

export default FlipWrapper;
