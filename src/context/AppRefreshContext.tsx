import React, { createContext, useContext } from 'react';

interface AppRefreshContextValue {
    requestAppRefresh: () => void;
}

const AppRefreshContext = createContext<AppRefreshContextValue>({
    requestAppRefresh: () => {},
});

export const AppRefreshProvider: React.FC<
    React.PropsWithChildren<AppRefreshContextValue>
> = ({ children, requestAppRefresh }) => (
    <AppRefreshContext.Provider value={{ requestAppRefresh }}>
        {children}
    </AppRefreshContext.Provider>
);

export const useAppRefresh = () => useContext(AppRefreshContext);
