// Currency formatting helper. The symbol is supplied by PreferencesContext so
// the whole app can switch currency display from one place.

export interface FormatCurrencyOptions {
    symbol?: string;
    maximumFractionDigits?: number;
    showSymbol?: boolean;
}

export const formatCurrency = (
    value: number | string | null | undefined,
    {symbol = '₹', maximumFractionDigits = 2, showSymbol = true}: FormatCurrencyOptions = {},
): string => {
    const num = Number(value);
    const safe = Number.isFinite(num) ? num : 0;
    const sign = safe < 0 ? '-' : '';
    const abs = Math.abs(safe);

    // Indian grouping (1,00,000) matches the app's INR default; still correct
    // for other symbols since it only affects digit grouping.
    const grouped = abs.toLocaleString('en-IN', {
        maximumFractionDigits,
        minimumFractionDigits: 0,
    });

    return `${sign}${showSymbol ? symbol : ''}${grouped}`;
};
