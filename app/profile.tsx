import React, {useEffect, useState} from 'react';
import {ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View} from 'react-native';
import {Button} from 'react-native-paper'; // For the "Update password" button
import Icon from 'react-native-vector-icons/Feather'; // For icons
import AsyncStorage from '@react-native-async-storage/async-storage'; // For persistent storage
import APIService from "@/src/ApiService/api.service";
import ConfirmationModal from "@/src/components/common/ConfirmationModal";
import ScreenWithHeader from "@/src/components/layout/ScreenWithHeader";
import Toast from 'react-native-toast-message';
import {useRouter} from "expo-router";
import { Colors } from '@/src/styles/colors';
import UpdatePasswordModal from "@/src/components/modals/UpdatePasswordModal";
import {useDispatch} from "react-redux";
import {getUserData} from "@/src/redux/Actions/UserActions";

const api = new APIService();

interface UserData {
    username: string;
    email: string;
}

const ProfileScreen = () => {
    const router = useRouter();
    const dispatch: any = useDispatch();
    const [userData, setUserData] = useState<UserData>({username: '', email: ''});
    const [initialUserData, setInitialUserData] = useState<UserData>({username: '', email: ''});
    const [confirmModal, setConfirmModal] = useState(false);
    const [showModal, setShowModal] = useState(false); // Corrected state name

    useEffect(() => {
        getUserProfile();
    }, []);

    const getUserProfile = async () => {
        try {
            const res = await api.getProfile();
            if (res.data?.data) {
                setUserData(res.data.data);
                setInitialUserData(res.data.data);
                dispatch(getUserData(res.data.data));
                await AsyncStorage.setItem('wealthify_user', JSON.stringify(res.data.data));
            }
        } catch (error) {
            showToastMessage("Failed to fetch profile");
        }
    };

    const handleSubmit = async () => {
        try {
            if (!userData.username) {
                showToastMessage("Invalid user name");
                return;
            }

            const res = await api.updateProfile(userData);
            if (res.data) {
                showToastMessage("Full name updated successfully", 'success');
                getUserProfile();
            }
        } catch (error) {
            showToastMessage("Failed to update profile");
        }
    };

    const handleChange = (name: keyof UserData, value: string) => {
        setUserData(prev => ({...prev, [name]: value}));
    };

    const handleLogout = async () => {
        try {
            await AsyncStorage.multiRemove([
                'wealthify_token',
                'wealthify_user',
            ]);
            router.push('/');
        } catch (error) {
            console.error('Logout error:', error);
        }
    };

    const showToastMessage = (text1='', type='error') => {
        Toast.show({ type, text1 });
    }

    return (
        <ScreenWithHeader>
            <ScrollView style={styles.container}>
                <View style={styles.pageTitleContainer}>
                    <Text style={styles.pageTitle}>Profile</Text>
                    {/* BreadcrumbList  */}
                </View>

                <View style={styles.card}>
                    <View style={styles.cardBody}>
                        <View>
                            <View style={styles.actionLabel}>
                                <Text style={styles.label}>Full name</Text>
                                {(JSON.stringify(initialUserData) !== JSON.stringify(userData)) && (
                                    <TouchableOpacity
                                        style={styles.updateButton}
                                        onPress={handleSubmit}
                                    >
                                        <Text style={styles.updateButtonText}>
                                            Update profile
                                        </Text>
                                    </TouchableOpacity>
                                )}
                            </View>
                            <TextInput
                                style={styles.input}
                                autoComplete="off"
                                value={userData.username}
                                onChangeText={(text) => handleChange('username', text)}
                                placeholder="Full name"
                            />
                        </View>
                        <View>
                            <Text style={styles.label}>Email</Text>
                            <TouchableOpacity onPress={() => {
                                showToastMessage("You can't update your email. Contact admin.")
                            }}>
                                <Text style={styles.input}>{userData.email}</Text>
                            </TouchableOpacity>
                        </View>

                        <View>
                            <Text style={styles.label}>Update password</Text>
                            <TouchableOpacity
                                style={styles.passwordButton}
                                onPress={() => {
                                    setShowModal(true);
                                }}
                            >
                                <Text style={styles.passwordButtonText}>
                                Update password
                                </Text>
                            </TouchableOpacity>
                        </View>
                    </View>
                </View>

                <View style={styles.card}>
                    <View style={[styles.cardBody, styles.logoutContainer]}>
                        <TouchableOpacity
                            onPress={() => {
                                setConfirmModal(true);
                            }}
                            style={styles.logoutButton}
                        >
                            <Icon name="log-out" size={18} color="#f9736c"/>
                            <Text style={styles.logoutText}>Logout</Text>
                        </TouchableOpacity>
                    </View>
                </View>

                <UpdatePasswordModal
                    closeModal={() => setShowModal(false)}
                    userData={userData}
                    showModal={showModal}
                />
                <ConfirmationModal
                    visible={confirmModal}
                    onClose={() => setConfirmModal(false)}
                    onConfirm={handleLogout}
                    message="Are you sure you want logout?"
                    confirmText="Log me out"
                    cancelText="Cancel"
                />
            </ScrollView>
        </ScreenWithHeader>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f8f9fa', // Light background
        padding: 16,
    },
    pageTitleContainer: {
        marginBottom: 16,
    },
    pageTitle: {
        fontSize: 24,
        fontWeight: 'bold',
        color: '#2c3e50', // Darker title
    },
    card: {
        backgroundColor: 'white',
        borderRadius: 8,
        marginBottom: 16,
        shadowColor: '#000',
        shadowOffset: {width: 0, height: 2},
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 2,
    },
    cardBody: {
        padding: 16,
    },
    actionLabel: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems:'flex-start'
    },
    label: {
        fontSize: 14,
        marginBottom: 8,
        color: '#7c7c7c',
    },
    input: {
        backgroundColor: '#f7f2ff',
        borderWidth: 1,
        borderColor: '#e6e1f8',
        padding: 12,
        borderRadius: 10,
        marginBottom: 10,
        fontSize: 14,
        color: '#333',
    },
    passwordButton: {
        backgroundColor: Colors.quaternary,
        paddingVertical: 8,
        paddingHorizontal: 12,
        borderRadius: 8
    },
    passwordButtonText: {
        color: 'white',
        fontSize: 14,
    },
    updateButton: {
        backgroundColor: Colors.success,
        paddingVertical: 4,
        paddingHorizontal: 12,
        borderRadius: 4,
        alignItems: 'center'
    },
    updateButtonText: {
        color: 'white',
        fontWeight: 'bold',
        fontSize: 12,
        flexDirection: 'row',
        alignItems: 'center',
    },
    logoutContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
    },
    logoutButton: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: 0,
    },
    logoutText: {
        color: Colors.darkText,
        fontSize: 16,
        marginLeft: 8,
    }
});

export default ProfileScreen;
