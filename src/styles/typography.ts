import { TextStyle } from 'react-native';
import { Colors } from './colors';
import { fontSize } from './tokens';
import { Fonts } from './fonts';

// Preset text styles aligned to the Wealthify design system. The Poppins family
// name carries the weight (Poppins_700Bold etc.), so we set fontFamily, not
// fontWeight. Letter-spacing values mirror the CSS counterparts.

export const Typography: Record<string, TextStyle> = {
    displayLg: {
        fontFamily: Fonts.extrabold,
        fontSize: fontSize.displayLg,
        color: Colors.text,
        letterSpacing: 0,
        lineHeight: fontSize.displayLg * 1.08,
    },
    display: {
        fontFamily: Fonts.extrabold,
        fontSize: fontSize.display,
        color: Colors.text,
        letterSpacing: 0,
    },
    titleLg: {
        fontFamily: Fonts.extrabold,
        fontSize: fontSize.titleLg,
        color: Colors.text,
        letterSpacing: 0,
        lineHeight: fontSize.titleLg * 1.14,
    },
    title: {
        fontFamily: Fonts.bold,
        fontSize: fontSize.title,
        color: Colors.text,
        letterSpacing: 0,
        lineHeight: fontSize.title * 1.2,
    },
    screenTitle: {
        // Top-level screen titles ("Transactions", "Select Category")
        fontFamily: Fonts.semibold,
        fontSize: fontSize.screenTitle,
        color: Colors.text,
        letterSpacing: 0,
        lineHeight: fontSize.screenTitle * 1.25,
    },
    subtitle: {
        fontFamily: Fonts.bold,
        fontSize: fontSize.subtitle,
        color: Colors.text,
        letterSpacing: 0,
    },
    body: {
        fontFamily: Fonts.regular,
        fontSize: fontSize.body,
        color: Colors.textBody,
        lineHeight: fontSize.body * 1.45,
    },
    bodyMedium: {
        fontFamily: Fonts.semibold,
        fontSize: fontSize.body,
        color: Colors.text,
    },
    bodyStrong: {
        fontFamily: Fonts.bold,
        fontSize: fontSize.body,
        color: Colors.text,
        letterSpacing: 0,
    },
    bodySm: {
        fontFamily: Fonts.regular,
        fontSize: fontSize.bodySm,
        color: Colors.textSubtle,
        lineHeight: fontSize.bodySm * 1.4,
    },
    caption: {
        fontFamily: Fonts.medium,
        fontSize: fontSize.caption,
        color: Colors.textSubtle,
        lineHeight: fontSize.caption * 1.35,
    },
    label: {
        // Field labels above inputs
        fontFamily: Fonts.semibold,
        fontSize: fontSize.caption,
        color: Colors.textSubtle,
        letterSpacing: 0,
    },
    button: {
        fontFamily: Fonts.bold,
        fontSize: fontSize.body,
        color: Colors.textInverse,
        letterSpacing: 0,
    },
    link: {
        fontFamily: Fonts.bold,
        fontSize: fontSize.bodySm,
        color: Colors.primary,
    },
    money: {
        fontFamily: Fonts.extrabold,
        fontSize: fontSize.displayLg,
        color: Colors.text,
        letterSpacing: 0,
    },
    moneyMd: {
        fontFamily: Fonts.bold,
        fontSize: 19,
        color: Colors.text,
        letterSpacing: 0,
    },
    moneySm: {
        fontFamily: Fonts.bold,
        fontSize: fontSize.bodySm,
        color: Colors.text,
        letterSpacing: 0,
    },
};
