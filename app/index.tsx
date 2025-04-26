import {StyleSheet, Text, View} from "react-native";
import React, {useEffect, useState} from "react";
import {useDispatch} from "react-redux";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {InitialLoader} from "@/src/components/home/InitialLoader";
import {getUserData} from "@/src/redux/Actions/UserActions";
import APIService from "@/src/ApiService/api.service";
import AuthScreen from "@/src/components/auth/AuthScreen";


const api = new APIService();

export default function Index() {
    const [initializing, setInitializing] = useState(true);
    const [initialRoute, setInitialRoute] = useState('LoginStack');
    const dispatch: any = useDispatch();


    useEffect(() => {
        api.check()
            .then(async res => {
                const user = await AsyncStorage.getItem('wealthify_user');
                if (user) {
                    dispatch(getUserData(JSON.parse(user) || {}));
                    setInitialRoute('DrawerStack');
                }
                setInitializing(false);
            })
            .catch(err => {
                setInitializing(false);
            })
    }, []);

    if (initializing) {
        return <InitialLoader />;
    }

    return (
        <AuthScreen/>
    );
}



