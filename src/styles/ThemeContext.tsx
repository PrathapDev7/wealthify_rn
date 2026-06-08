import React, {
    createContext,
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useState,
} from 'react';
import { useColorScheme } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors } from './colors';
import { ColorsDark } from './colorsDark';

export type ThemeMode = 'light' | 'dark' | 'system';
export type ColorPalette = typeof Colors;

const STORAGE_KEY = 'wealthify_theme';

interface ThemeContextValue {
    mode: ThemeMode;
    setMode: (mode: ThemeMode) => void;
    isDark: boolean;
    colors: ColorPalette;
}

const ThemeContext = createContext<ThemeContextValue>({
    mode: 'system',
    setMode: () => {},
    isDark: false,
    colors: Colors,
});

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const systemScheme = useColorScheme(); // 'light' | 'dark' | null
    const [mode, setModeState] = useState<ThemeMode>('system');

    useEffect(() => {
        (async () => {
            try {
                const saved = await AsyncStorage.getItem(STORAGE_KEY);
                if (saved === 'light' || saved === 'dark' || saved === 'system') {
                    setModeState(saved);
                }
            } catch {
                // ignore — fall back to system default
            }
        })();
    }, []);

    const setMode = useCallback((next: ThemeMode) => {
        setModeState(next);
        AsyncStorage.setItem(STORAGE_KEY, next).catch(() => {});
    }, []);

    const isDark = mode === 'system' ? systemScheme === 'dark' : mode === 'dark';
    const colors = isDark ? ColorsDark : Colors;

    const value = useMemo<ThemeContextValue>(
        () => ({ mode, setMode, isDark, colors }),
        [mode, setMode, isDark, colors],
    );

    return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
};

export const useTheme = () => useContext(ThemeContext);
export const useColors = (): ColorPalette => useContext(ThemeContext).colors;
export const useThemeMode = () => {
    const { mode, setMode, isDark } = useContext(ThemeContext);
    return { mode, setMode, isDark };
};
