import React, { useState } from 'react';
import { Text } from 'react-native';
import Animated, {
    useSharedValue,
    useDerivedValue,
    useAnimatedReaction,
    withTiming,
    Easing, runOnJS,
} from 'react-native-reanimated';
import {formatNumberWithCommas} from "../../src/utils/helper";

const AnimatedCounter = ({ fromValue, toValue, duration = 500, style }) => {
    const [displayValue, setDisplayValue] = useState(fromValue);
    const progress = useSharedValue(0);

    // Trigger animation
    React.useEffect(() => {
        progress.value = withTiming(1, {
            duration,
            easing: Easing.inOut(Easing.ease),
        });
    }, [toValue]);

    const currentValue = useDerivedValue(() => {
        return fromValue + progress.value * (toValue - fromValue);
    });

    // Sync animated value with React state
    useAnimatedReaction(
        () => Math.floor(currentValue.value),
        (value, prev) => {
            if (value !== prev) {
                // Update state on JS thread
                runOnJS(setDisplayValue)(value);
            }
        },
        [currentValue]
    );

    return <Text style={style}>{formatNumberWithCommas(Number(displayValue || 0))}</Text>;
};

export default AnimatedCounter;
