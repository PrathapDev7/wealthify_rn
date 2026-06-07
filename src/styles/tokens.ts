// Raw numeric design tokens. Matches wealthify-ui-screens.css.
// For utility-class style spacing (mt3, p2, etc.) use ./spacing instead.

export const space = {
    none: 0,
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    '2xl': 24,
    '3xl': 28,
    '4xl': 32,
    '5xl': 40,
    '6xl': 48,
    '7xl': 64,
} as const;

// Radius scale matches the Wealthify CSS: xs10 / sm14 / md18 / lg24 / xl30.
export const radius = {
    none: 0,
    xs: 10,
    sm: 14,
    md: 18,
    lg: 24,
    xl: 30,
    '2xl': 36,
    '3xl': 42,
    screen: 42,
    pill: 999,
    full: 9999,
} as const;

// Type sizes match the Wealthify CSS.
export const fontSize = {
    tiny: 10,
    caption: 11,          // rendered as 10.5px in CSS; round to 11 for RN integer
    bodySm: 12,
    body: 14,
    subtitle: 16,
    screenTitle: 18,
    title: 20,
    titleLg: 26,
    display: 30,
    displayLg: 34,        // hero amounts ($313.31)
    displayXl: 44,
} as const;

export const fontWeight = {
    regular: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    extrabold: '800',
} as const;

export const lineHeight = {
    tight: 1.08,
    snug: 1.25,
    normal: 1.45,
    relaxed: 1.55,
} as const;

export const opacity = {
    disabled: 0.4,
    muted: 0.6,
    hover: 0.85,
} as const;
