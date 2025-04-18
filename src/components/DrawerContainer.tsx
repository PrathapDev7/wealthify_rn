import React from 'react';
import {StyleSheet, View} from 'react-native';
import MenuButton from './MenuButton';
import {useDispatch} from 'react-redux';
import AsyncStorage from '@react-native-async-storage/async-storage';

export default function DrawerContainer({navigation}) {
    const dispatch = useDispatch();

    const handleLogout = async () => {
        try {
            await AsyncStorage.multiRemove([
                'wealthify_token',
                'wealthify_user',
            ]);
            //dispatch(logout());
            navigation.reset({
                index: 0,
                routes: [{name: 'LoginStack', params: {screen: 'Welcome'}}],
            });
        } catch (error) {
            console.error('Logout error:', error);
        }
    };

    return (
        <View style={styles.content}>
            <View style={styles.container}>
                <MenuButton
                    title="LOG OUT"
                    onPress={handleLogout}
                />
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    content: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
    },
    container: {
        flex: 1,
        alignItems: 'flex-start',
        paddingHorizontal: 20,
    },
});
