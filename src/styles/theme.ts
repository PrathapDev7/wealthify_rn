// Single barrel import for the design system.
// Usage:  import { Colors, Typography, Shadows, space, radius } from '@/src/styles/theme';

export { Colors } from './colors';
export { ColorsDark } from './colorsDark';
export {
    ThemeProvider,
    useTheme,
    useColors,
    useThemeMode,
} from './ThemeContext';
export type { ThemeMode, ColorPalette } from './ThemeContext';
export { Typography } from './typography';
export { Fonts } from './fonts';
export { Shadows } from './shadows';
export { Gradients, GradientStops } from './gradients';
export { space, radius, fontSize, fontWeight, lineHeight, opacity } from './tokens';
export { noWebOutline, focusRing } from './inputStyles';
export { default as Spacing } from './spacing';
