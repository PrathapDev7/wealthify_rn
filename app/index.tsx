import React, {useEffect, useState} from "react";
import {useDispatch} from "react-redux";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {useRouter} from "expo-router";
import {InitialLoader} from "@/src/components/home/InitialLoader";
import {getUserData} from "@/src/redux/Actions/UserActions";
import APIService from "@/src/ApiService/api.service";
import AuthScreen from "@/src/components/auth/AuthScreen";


const api = new APIService();

export default function Index() {
    const router = useRouter();
    const [initializing, setInitializing] = useState(true);
    const [showAuth, setShowAuth] = useState(false);
    const dispatch: any = useDispatch();


    useEffect(() => {
        (async () => {
            try {
                await api.check().catch(() => {});

                const [seenWelcome, user] = await Promise.all([
                    AsyncStorage.getItem('wealthify_seen_welcome'),
                    AsyncStorage.getItem('wealthify_user'),
                ]);

                if (!seenWelcome) {
                    router.replace('/welcome');
                    return;
                }

                if (user) {
                    dispatch(getUserData(JSON.parse(user) || {}));
                    router.replace('/dashboard');
                    return;
                }

                setShowAuth(true);
            } finally {
                setInitializing(false);
            }
        })();
    }, []);

    if (initializing) {
        return <InitialLoader />;
    }

    if (showAuth) {
        return <AuthScreen/>;
    }

    return <InitialLoader />;
}



