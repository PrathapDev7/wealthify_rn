import React, {
    createContext,
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useState,
} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {formatCurrency as baseFormatCurrency, FormatCurrencyOptions} from '@/src/utils/currency';

export type TxnType = 'expense' | 'income';
export type WeekStart = 'monday' | 'sunday';

export interface Preferences {
    currencySymbol: string;
    currencyCode: string;
    defaultTxnType: TxnType;
    defaultCategory: string | null;
    defaultWallet: string | null;
    weekStart: WeekStart;
    dateFormat: string;
}

export const DEFAULT_PREFERENCES: Preferences = {
    currencySymbol: '₹',
    currencyCode: 'INR',
    defaultTxnType: 'expense',
    defaultCategory: null,
    defaultWallet: null,
    weekStart: 'monday',
    dateFormat: 'DD MMM YYYY',
};

const STORAGE_KEY = 'wealthify_prefs';

interface PreferencesContextValue {
    prefs: Preferences;
    ready: boolean;
    setPreference: <K extends keyof Preferences>(key: K, value: Preferences[K]) => void;
    setPreferences: (partial: Partial<Preferences>) => void;
    formatCurrency: (value: number | string | null | undefined, options?: FormatCurrencyOptions) => string;
}

const PreferencesContext = createContext<PreferencesContextValue>({
    prefs: DEFAULT_PREFERENCES,
    ready: false,
    setPreference: () => {},
    setPreferences: () => {},
    formatCurrency: (v) => baseFormatCurrency(v),
});

export const PreferencesProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [prefs, setPrefs] = useState<Preferences>(DEFAULT_PREFERENCES);
    const [ready, setReady] = useState(false);

    useEffect(() => {
        (async () => {
            try {
                const saved = await AsyncStorage.getItem(STORAGE_KEY);
                if (saved) {
                    setPrefs({...DEFAULT_PREFERENCES, ...JSON.parse(saved)});
                }
            } catch {
                // ignore — keep defaults
            } finally {
                setReady(true);
            }
        })();
    }, []);

    const persist = useCallback((next: Preferences) => {
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(() => {});
    }, []);

    const setPreferences = useCallback((partial: Partial<Preferences>) => {
        setPrefs((prev) => {
            const next = {...prev, ...partial};
            persist(next);
            return next;
        });
    }, [persist]);

    const setPreference = useCallback(<K extends keyof Preferences>(key: K, value: Preferences[K]) => {
        setPreferences({[key]: value} as Partial<Preferences>);
    }, [setPreferences]);

    const formatCurrency = useCallback(
        (value: number | string | null | undefined, options?: FormatCurrencyOptions) =>
            baseFormatCurrency(value, {symbol: prefs.currencySymbol, ...options}),
        [prefs.currencySymbol],
    );

    const value = useMemo<PreferencesContextValue>(
        () => ({prefs, ready, setPreference, setPreferences, formatCurrency}),
        [prefs, ready, setPreference, setPreferences, formatCurrency],
    );

    return <PreferencesContext.Provider value={value}>{children}</PreferencesContext.Provider>;
};

export const usePreferences = () => useContext(PreferencesContext);
