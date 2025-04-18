import React from 'react';
import { ActivityIndicator, View } from 'react-native';
import { StyleSheet } from 'react-native';
import LottieView from 'lottie-react-native';


export function InitialLoader() {
    return (
        <View style={styles.loadingContainer}>
            <View style={styles.loadingBox}>
                <LottieView
                    source={require('../../assets/lottie/loader')}
                    autoPlay
                    loop
                    style={{ width: 200, height: 200 }}
                />
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#6F6AF8'
    },
    loadingContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#6F6AF8'
    },
    loadingBox: {
        width: 100,
        height: 100,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#6F6AF8',
        borderRadius: 10,
        elevation: 10,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.8,
        shadowRadius: 2,
    },
});
