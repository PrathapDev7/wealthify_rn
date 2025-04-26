import React from 'react';
import { View, Text, TouchableOpacity, Image, StyleSheet } from 'react-native';
import { useNavigation, useRoute } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import {images} from "../../assets/Constants/constants";
import {Colors} from "../styles/colors";
import {useRouter} from "expo-router";

const NavMobileButtons = () => {
    const route = useRoute();
    const router = useRouter();

    const isActive = (path) => route.name === path;

    return (
        <View style={styles.footer}>
            <TouchableOpacity
                style={styles.button}
                onPress={() => router.push('/incomes')}
            >
                <Icon name="currency-inr" size={24}  style={styles.icon} />
                <Text style={[styles.label, isActive('Incomes') && styles.activeText]}>Income</Text>
            </TouchableOpacity>

            <TouchableOpacity
                style={styles.button}
                onPress={() => router.push('/expenses')}
            >
                <Icon name="chart-line" size={24}  style={styles.icon} />
                <Text style={[styles.label, isActive('Expenses') && styles.activeText]}>Expenses</Text>
            </TouchableOpacity>

            <TouchableOpacity
                onPress={() => router.push('/dashboard')}
                style={styles.searchTrigger}
            >
                <Image
                    source={images.iconINRWhite}
                    style={styles.searchIcon}
                    resizeMode="contain"
                />
            </TouchableOpacity>
            <TouchableOpacity style={styles.button} />
            <TouchableOpacity
                style={styles.button}
                onPress={() => router.push('/budget-analysis')}
            >
                <Icon name="view-dashboard-outline" size={24}  style={styles.icon}/>
                <Text style={[styles.label, isActive('Analysis') && styles.activeText]}>Analysis</Text>
            </TouchableOpacity>

            <TouchableOpacity
                style={styles.button}
                onPress={() => router.push('/profile')}
            >
                <Icon name="account" size={24}  style={styles.icon}  />
                <Text style={[styles.label, isActive('Profile') && styles.activeText]}>Profile</Text>
            </TouchableOpacity>
        </View>
    );
};

const styles = StyleSheet.create({
    footer: {
        flexDirection: 'row',
        justifyContent: 'space-around',
        backgroundColor: '#F2F2FD',
        paddingVertical: 10,
        borderTopWidth: 1,
        borderColor: '#ddd',
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        elevation: 10,
        zIndex: 100,
    },
    button: {
        alignItems: 'center',
    },
    label: {
        fontSize: 12,
        color: '#888',
    },
    icon :{
        color: Colors.primary,
    },
    activeText: {
        color: Colors.primary,
    },
    img: {
        width: 30,
        height: 30,
        resizeMode: 'contain',
    },
    searchTrigger: {
        width: 64,
        height: 64,
        backgroundColor: Colors.primary,
        borderRadius: 70,
        position: 'absolute',
        top: -30,
        right: '40%',
        justifyContent: 'center',
        alignItems: 'center',
        elevation: 6,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.3,
        shadowRadius: 4,
        zIndex: 10,
    },
    searchIcon: {
        width: 50,
        height: 50,
        tintColor: '#fff',
    },
});

export default NavMobileButtons;
