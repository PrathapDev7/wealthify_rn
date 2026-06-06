import { Colors } from './colors';

// Color-stop arrays consumable by expo-linear-gradient's `colors` prop.

export const Gradients = {
    // Soft lavender wash used at the top of splash / welcome / auth / dashboard.
    lavenderWash: [
        Colors.lavenderWashTop,
        Colors.lavenderWashTopSoft,
        Colors.lavenderWashMid,
        Colors.lavenderWashBottom,
    ] as const,

    // Primary CTA gradient: #865CFF → #6738F5
    primary: [
        Colors.primaryGradientStart,
        Colors.primaryGradientEnd,
    ] as const,

    // Premium banner gradient from the profile reference.
    premium: ['#8B5CFF', '#6637F4'] as const,

    // Full-screen Premium / Promo background
    premiumScreen: ['#E7D9FF', '#F6F1FF', '#FFFFFF'] as const,

    // Profile avatar: warm orange gradient
    avatarWarm: ['#FFE2CA', '#FFD1AD'] as const,

    // Subtle white-to-transparent overlay on imagery / lists.
    fadeBottom: ['rgba(248, 245, 251, 0)', Colors.background] as const,
};

// Stop offsets keep aligned with each gradient's colors array length.
export const GradientStops = {
    lavenderWash: [0, 0.34, 0.76, 1] as const,
    primary: [0, 1] as const,
    premium: [0, 1] as const,
    premiumScreen: [0, 0.46, 1] as const,
    avatarWarm: [0, 1] as const,
    fadeBottom: [0, 1] as const,
};
