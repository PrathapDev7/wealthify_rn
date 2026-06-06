import React from 'react';
import { Tabs } from 'expo-router';
import BottomTabBar from '@/src/components/navigation/BottomTabBar';

export default function TabsLayout() {
    return (
        <Tabs
            screenOptions={{ headerShown: false }}
            tabBar={(props) => <BottomTabBar {...props} />}
        >
            <Tabs.Screen name="dashboard" />
            <Tabs.Screen name="transactions" />
            <Tabs.Screen name="analytics" />
            <Tabs.Screen name="account" />
        </Tabs>
    );
}
