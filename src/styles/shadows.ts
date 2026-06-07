import { ViewStyle } from 'react-native';

// Ink-tinted shadow presets matching wealthify-ui-screens.css.
// All shadows use rgba(28, 17, 64, *) to stay cohesive with the deep purple ink.

const INK = '#1C1140';

export const Shadows: Record<string, ViewStyle> = {
    none: {
        shadowColor: 'transparent',
        shadowOffset: { width: 0, height: 0 },
        shadowOpacity: 0,
        shadowRadius: 0,
        elevation: 0,
    },
    xs: {
        shadowColor: INK,
        shadowOffset: { width: 0, height: 3 },
        shadowOpacity: 0.03,
        shadowRadius: 10,
        elevation: 1,
    },
    sm: {
        // shadow-card-soft: 0 8px 20px rgba(28,17,64,0.06)
        shadowColor: INK,
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.06,
        shadowRadius: 20,
        elevation: 2,
    },
    md: {
        // shadow-card: 0 10px 28px rgba(28,17,64,0.08)
        shadowColor: INK,
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.08,
        shadowRadius: 28,
        elevation: 4,
    },
    lg: {
        // For modals / row separators with stronger lift
        shadowColor: INK,
        shadowOffset: { width: 0, height: 12 },
        shadowOpacity: 0.10,
        shadowRadius: 30,
        elevation: 6,
    },
    xl: {
        shadowColor: INK,
        shadowOffset: { width: 0, height: 18 },
        shadowOpacity: 0.16,
        shadowRadius: 40,
        elevation: 12,
    },
    primaryGlow: {
        // shadow under primary CTAs: 0 12px 24px rgba(124,77,255,0.28)
        shadowColor: '#7B3FF2',
        shadowOffset: { width: 0, height: 12 },
        shadowOpacity: 0.28,
        shadowRadius: 24,
        elevation: 8,
    },
    primaryGlowSoft: {
        shadowColor: '#7B3FF2',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.18,
        shadowRadius: 18,
        elevation: 6,
    },
    fab: {
        // shadow-floating: 0 16px 36px rgba(28,17,64,0.18)
        shadowColor: INK,
        shadowOffset: { width: 0, height: 16 },
        shadowOpacity: 0.18,
        shadowRadius: 36,
        elevation: 12,
    },
};
