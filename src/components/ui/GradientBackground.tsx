import React from 'react';
import { StyleSheet, useWindowDimensions, View, ViewStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Svg, {
    Defs,
    Ellipse,
    RadialGradient,
    Rect,
    Stop,
} from 'react-native-svg';
import { Gradients, GradientStops, Colors } from '@/src/styles/theme';

type Variant = 'wash' | 'primary' | 'plain';

interface Props {
    children?: React.ReactNode;
    variant?: Variant;
    style?: ViewStyle | ViewStyle[];
    height?: number | string;
}

const GradientBackground: React.FC<Props> = ({
    children,
    variant = 'wash',
    style,
    height,
}) => {
    const { width } = useWindowDimensions();
    const reactId = React.useId();
    const glowId = React.useMemo(
        () => `cashioTopGlow${reactId.replace(/[^A-Za-z0-9_-]/g, '')}`,
        [reactId],
    );

    if (variant === 'plain') {
        return (
            <View style={[styles.plain, { height: height as any }, style]}>
                {children}
            </View>
        );
    }

    if (variant === 'primary') {
        return (
            <LinearGradient
                colors={Gradients.primary as any}
                locations={GradientStops.primary as any}
                start={{ x: 0.5, y: 0 }}
                end={{ x: 0.5, y: 1 }}
                style={[styles.gradient, { height: height as any }, style]}
            >
                {children}
            </LinearGradient>
        );
    }

    const glowRadiusX = Math.max(width * 1.18, 460);
    const glowRadiusY = Math.max(width * 1.02, 400);
    const glowCenterY = -glowRadiusY * 0.2;

    return (
        <View style={[styles.gradient, { height: height as any }, style]}>
            <LinearGradient
                colors={Gradients.lavenderWash as any}
                locations={GradientStops.lavenderWash as any}
                start={{ x: 0.5, y: 0 }}
                end={{ x: 0.5, y: 1 }}
                style={StyleSheet.absoluteFill}
            />
            <Svg
                width="100%"
                height="100%"
                style={StyleSheet.absoluteFill}
                pointerEvents="none"
            >
                <Defs>
                    <RadialGradient id={glowId} cx="50%" cy="50%" r="50%">
                        <Stop offset="0" stopColor="#8E62FF" stopOpacity="0.44" />
                        <Stop offset="0.38" stopColor="#BBA2FF" stopOpacity="0.56" />
                        <Stop offset="0.8" stopColor="#F0E9FF" stopOpacity="0.26" />
                        <Stop offset="1" stopColor="#FFFFFF" stopOpacity="0" />
                    </RadialGradient>
                </Defs>
                <Rect width="100%" height="100%" fill="transparent" />
                <Ellipse
                    cx={width / 2}
                    cy={glowCenterY}
                    rx={glowRadiusX}
                    ry={glowRadiusY}
                    fill={`url(#${glowId})`}
                />
            </Svg>
            {children}
        </View>
    );
};

const styles = StyleSheet.create({
    gradient: {
        width: '100%',
        overflow: 'hidden',
        backgroundColor: Colors.lavenderWashTopSoft,
    },
    plain: {
        width: '100%',
        backgroundColor: Colors.background,
    },
});

export default GradientBackground;
