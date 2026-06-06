// Cashio reference palette. Keep these values aligned with
// cashio_icon_pack/manifest.json and the separate screen references.

export const Colors = {
    // Brand
    primary: '#7B3FF2',
    primaryDark: '#6D35E8',
    primaryDarker: '#5437E7',
    primarySoft: '#EFE8FF',
    primarySoftStrong: '#E2D5FF',
    primaryGradientStart: '#8B5CFF',
    primaryGradientEnd: '#6637F4',
    deepPurple: '#160947',

    // Accents
    accent: '#9FE39A',             // mint used in Cashio chart bars
    accentDark: '#24D46B',         // success green / expense type
    accentSoft: '#E8F8EE',

    negative: '#F04D4D',           // danger / negative deltas
    negativeDark: '#D94242',
    negativeSoft: '#FFEDED',

    warning: '#FF991B',
    warningSoft: '#FFF3E2',
    info: '#3364F6',
    infoSoft: '#EAF1FF',
    pink: '#F22AC8',
    pinkSoft: '#FFEAF5',
    cyan: '#12C8D8',
    blue: '#3364F6',

    // Surfaces
    background: '#F8F6FE',         // Cashio screen body
    surface: '#FFFFFF',            // solid cards
    surfaceMuted: '#F0EDF5',       // muted fills / chips at rest
    surfaceSoft: '#F7F5FA',
    surfaceLifted: 'rgba(255, 255, 255, 0.86)',  // glassy cards w/ blur
    surfaceElevated: '#FFFFFF',
    overlay: 'rgba(19, 11, 61, 0.45)',

    // Text — ink scale
    text: '#130B3D',               // primary Cashio ink
    textStrong: '#130B3D',
    textSecondary: '#2A2550',
    textBody: '#3B365F',
    textMuted: '#3B365F',
    textSubtle: '#68708F',         // muted labels/nav
    textPlaceholder: '#B8B1C6',    // muted-2 — placeholder/inactive dots
    textInverse: '#FFFFFF',
    textOnPrimary: '#FFFFFF',

    // Borders
    border: '#E7E1F0',
    borderStrong: '#D0C8DE',
    divider: 'rgba(231, 225, 240, 0.72)',

    // Special
    fab: '#160947',                // near-black FAB center
    fabRing: 'rgba(255, 255, 255, 0.95)',  // 6px white ring around FAB
    lavenderWashTop: '#EAE0FF',
    lavenderWashTopSoft: '#F7F3FF',
    lavenderWashMid: '#FFFFFF',
    lavenderWashBottom: '#FFFFFF',

    // Category brand colors
    cat: {
        groceries:    '#24D46B',
        travel:       '#12C8D8',
        car:          '#5437E7',
        home:         '#F22AC8',
        insurance:    '#12C8D8',
        education:    '#5437E7',
        marketing:    '#FF991B',
        shopping:     '#24D46B',
        internet:     '#7B3FF2',
        water:        '#3364F6',
        rent:         '#FF6B21',
        gym:          '#FF991B',
        subscription: '#7B3FF2',
        vacation:     '#24D46B',
        other:        '#7B3FF2',
        spotify:      '#1ED760',
        wallet:       '#12C8D8',
    },

    // ─────────────────────────────────────────────
    // Legacy aliases (kept for back-compat with older files).
    secondary: '#B89BFF',
    tertiary: '#9ED5F7',
    quaternary: '#F04D4D',
    secondaryDarker: '#12C8D8',
    tertiaryDarker: '#54CCB4',
    quaternaryDarker: '#5437E7',
    body: '#3B365F',
    alternate: '#68708F',
    muted: '#68708F',
    separator: '#E7E1F0',
    separatorLight: '#F1EFF5',
    foreground: '#FFFFFF',
    backgroundLight: '#F8F6FE',
    gradient1: '#7B3FF2',
    gradient2: '#8B5CFF',
    gradient3: '#6637F4',
    lightText: '#FFFFFF',
    darkText: '#130B3D',
    textPrimary: '#130B3D',
    lightTextDarker: '#EEEEEE',
    darkTextDarker: '#000000',
    danger: '#F04D4D',
    dangerSubtle: '#FFEDED',
    warningSubtle: '#FFF3E2',
    success: '#24D46B',
    successLight: '#E8F8EE',
    successSubtle: '#E8F8EE',
    light: '#F8F5FB',
    dark: '#130B3D',
    dangerDarker: '#B91C1C',
    infoDarker: '#1D4ED8',
    warningDarker: '#B45309',
    successDarker: '#15803D',
    menuShadow: 'rgba(28, 17, 64, 0.12)',
    menuShadowNav: 'rgba(28, 17, 64, 0.05)',
    backgroundNavLight: '#FFFFFF',
    backgroundNavDark: '#7B3FF2',
    inputBackground: '#FFFFFF',
    inputBorder: '#E7E1F0',
};
