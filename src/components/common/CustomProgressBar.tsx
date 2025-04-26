import React, { useState, useEffect } from 'react';
import { Animated, Easing, StyleSheet, View } from 'react-native';
import { ProgressBar } from 'react-native-paper';
import { Colors } from '@/src/styles/colors';

interface Props {
    percentage: any;
}

const CustomProgressBar: React.FC<Props> = ({ percentage}) => {
    const [currentPercentage, setCurrentPercentage] = useState(0);

    useEffect(() => {
        let interval:any;
        if (percentage > 0 ) {
            interval = setInterval(() => {
                setCurrentPercentage((prevPercentage) =>
                    prevPercentage < percentage ? prevPercentage + 1 : percentage
                );
            }, 10);
        }

        return () => {
            clearInterval(interval);
        };
    }, [percentage]);

    const progressBarColor =
        percentage >= 90
            ? Colors.danger
            : percentage >= 70
                ? Colors.warning
                : percentage >= 25
                    ? Colors.success
                    : Colors.success;

    const actualWidth = currentPercentage / 100;


    return (
        <View style={styles.container}>
            <ProgressBar
                progress={actualWidth}
                color={progressBarColor}
                style={styles.progressBar}
            />
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        width: '100%',
    },
    progressBar: {
        height: 10,
        borderRadius: 0,
        transitionProperty : 'all',
        transitionDuration: '.5s'
    },
});

export default CustomProgressBar;
