import React from 'react';
import {View, StyleSheet, Image, TouchableOpacity, Text} from 'react-native';
import Icon from 'react-native-vector-icons/Feather';
import {Colors} from "../../styles/colors";
import {images} from "../../../assets/Constants/constants";
import {capitalize} from "../../utils/helper";
import {useSelector} from "react-redux";
import NavMobileButtons from "../NavBar";

const ScreenWithHeader = ({children}) => {
    const userData:any = useSelector((state:any) => state?.userData?.userData) || {};

    return (
        <View style={{flex: 1, backgroundColor: '#F8F8F8'}}>
            <View style={styles.topBar}>
                <View>
                    <Image source={images.logo} style={styles.logo}/>
                </View>
                <TouchableOpacity style={styles.profileButton}>
                    <Icon name="user" size={18} color={Colors.quaternary}/>
                    <Text style={styles.profileName}>{capitalize(userData?.username || '')}</Text>
                </TouchableOpacity>
            </View>
            {children}
            {/* Bottom Navigation */}
            <NavMobileButtons/>
        </View>
    );
};

const styles = StyleSheet.create({
    topBar: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        backgroundColor: Colors.primary,
        paddingHorizontal: 16,
        paddingTop: 45, // Adjust as needed for status bar
        paddingBottom: 16,
    },
    logo: {
        width: 175,
        height: 34,
    },
    profileButton: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: 'white',
        paddingHorizontal: 12,
        paddingVertical: 8,
        borderRadius: 20,
    },
    profileName: {
        color: Colors.primary,
        marginLeft: 8,
    },
});

export default ScreenWithHeader;
