import { Platform, ViewStyle } from 'react-native';
import { Colors } from './colors';

// Suppresses the default web browser focus outline. No-op on native.
// Spread into any TextInput style: `style={[styles.input, noWebOutline]}`.
export const noWebOutline: any = Platform.OS === 'web'
    ? {
          outlineStyle: 'none',
          outlineWidth: 0,
          outlineColor: 'transparent',
      }
    : {};

// Themed focus ring for input/field wrappers. Apply to the outer container
// when its inner TextInput is focused. Uses iOS/Android shadow props
// (rendered as a CSS box-shadow on web).
export const focusRing: ViewStyle = {
    borderColor: Colors.primary,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.18,
    shadowRadius: 8,
    elevation: 4,
};
