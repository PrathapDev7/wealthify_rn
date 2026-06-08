// Dark variant of the Wealthify palette. Spreads the light Colors first so
// every key is guaranteed to exist (any not overridden falls back to its light
// value rather than rendering `undefined`), then overrides the surface/text/
// border scale and tunes brand/accent hues for legibility on a dark ground.

import { Colors } from './colors';

export const ColorsDark: typeof Colors = {
    ...Colors,

    // Brand — keep the hue, lift lightness slightly for contrast on dark.
    primary: '#9B6CFF',
    primaryDark: '#8B5CFF',
    primaryDarker: '#7B4DF5',
    primarySoft: '#2A1E54',
    primarySoftStrong: '#34276A',
    primaryGradientStart: '#8B5CFF',
    primaryGradientEnd: '#6637F4',
    deepPurple: '#0E0726',

    // Accents
    accent: '#9FE39A',
    accentDark: '#2BE07A',
    accentSoft: '#16321F',
    negative: '#FF6B6B',
    negativeDark: '#F04D4D',
    negativeSoft: '#3A1E1E',
    warning: '#FFB04D',
    warningSoft: '#3A2A12',
    info: '#5B86F8',
    infoSoft: '#1B2747',
    pink: '#F95FD6',
    pinkSoft: '#3A1730',
    cyan: '#3AD8E6',
    blue: '#5B86F8',

    // Surfaces
    background: '#0F0A24',
    surface: '#1A1140',
    surfaceMuted: '#241A4D',
    surfaceSoft: '#181030',
    surfaceLifted: 'rgba(36, 26, 77, 0.86)',
    surfaceElevated: '#221848',
    overlay: 'rgba(0, 0, 0, 0.6)',

    // Text — light ink scale on dark
    text: '#F4F1FF',
    textStrong: '#FFFFFF',
    textSecondary: '#D7D0F0',
    textBody: '#C4BCE4',
    textMuted: '#A89FCB',
    textSubtle: '#8E86AE',
    textPlaceholder: '#6A6390',
    textInverse: '#FFFFFF',     // text on the (still purple) primary surfaces
    textOnPrimary: '#FFFFFF',

    // Borders
    border: '#2E2552',
    borderStrong: '#3D3370',
    divider: 'rgba(60, 51, 112, 0.5)',

    // Special
    fab: '#FFFFFF',
    fabRing: 'rgba(15, 10, 36, 0.9)',
    lavenderWashTop: '#241A4D',
    lavenderWashTopSoft: '#1C1438',
    lavenderWashMid: '#0F0A24',
    lavenderWashBottom: '#0F0A24',

    // Category brand colors read well on dark — keep as-is.
    cat: { ...Colors.cat },

    // Legacy aliases — remap to dark equivalents.
    secondary: '#B89BFF',
    tertiary: '#9ED5F7',
    quaternary: '#FF6B6B',
    secondaryDarker: '#3AD8E6',
    tertiaryDarker: '#54CCB4',
    quaternaryDarker: '#7B4DF5',
    body: '#C4BCE4',
    alternate: '#8E86AE',
    muted: '#8E86AE',
    separator: '#2E2552',
    separatorLight: '#241A4D',
    foreground: '#1A1140',
    backgroundLight: '#0F0A24',
    lightText: '#FFFFFF',
    darkText: '#F4F1FF',
    textPrimary: '#F4F1FF',
    lightTextDarker: '#EEEEEE',
    darkTextDarker: '#FFFFFF',
    danger: '#FF6B6B',
    dangerSubtle: '#3A1E1E',
    warningSubtle: '#3A2A12',
    success: '#2BE07A',
    successLight: '#16321F',
    successSubtle: '#16321F',
    light: '#181030',
    dark: '#F4F1FF',
    dangerDarker: '#FCA5A5',
    infoDarker: '#93B4FF',
    warningDarker: '#FCD9A5',
    successDarker: '#86EFAC',
    menuShadow: 'rgba(0, 0, 0, 0.5)',
    menuShadowNav: 'rgba(0, 0, 0, 0.3)',
    backgroundNavLight: '#1A1140',
    backgroundNavDark: '#7B3FF2',
    inputBackground: '#1A1140',
    inputBorder: '#2E2552',
};
