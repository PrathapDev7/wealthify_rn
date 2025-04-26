import React, { useState } from 'react';
import { View, Text, StyleSheet, Modal, TextInput, TouchableOpacity, ActivityIndicator } from 'react-native';
import { useNavigation } from '@react-navigation/native'; // If you need navigation
import APIService from "../../ApiService/api.service";
import Toast from 'react-native-toast-message';
import Spacing from "@/src/styles/spacing";
import { Colors } from '@/src/styles/colors';


const api = new APIService();

interface FormData {
    email: string;
    old_password: string;
    new_password: string;
    confirm_new_password: string;
}

interface Props {
    showModal: boolean;
    closeModal: () => void;
    userData: { email: string };
}

const UpdatePasswordModal: React.FC<Props> = ({ showModal, closeModal, userData }) => {
    const navigation = useNavigation(); // If you need navigation
    const [message, setMessage] = useState<any>({}); // Use 'any' or a more specific type
    const [loading, setLoading] = useState(false);
    const initialFormData: FormData = {
        email: "",
        old_password: "",
        new_password: "",
        confirm_new_password: ""
    };
    const [formData, setFormData] = useState(initialFormData);

    const handleChange = (name: keyof FormData, value: string) => {
        setMessage({});
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const showToastMessage = (text1='', type='error') => {
        Toast.show({ type, text1 });
    }

    const handleSubmit = async () => {
        try {
            if (!formData.old_password) {
                showToastMessage("Please enter old password");
                return;
            }
            if (!formData.new_password) {
                showToastMessage("Please enter new password");
                return;
            }
            if (!formData.confirm_new_password) {
                showToastMessage("Please confirm new password");
                return;
            }
            if (formData.confirm_new_password !== formData.new_password) {
                showToastMessage("New password should match with confirm password");
                return;
            }

            setLoading(true);
            const data: FormData = { ...formData, email: userData.email };

            const res = await api.updatePassword(data);
            if (res.data) {
                setLoading(false);
                showToastMessage("Password updated successfully", 'success');
                handleClose();
            }
        } catch (err: any) {
            setLoading(false);
            showToastMessage(err.response?.data?.message || "Failed to update password");
        }
    };

    const handleClose = () => {
        setFormData(initialFormData);
        closeModal();
    };

    return (
        <Modal
            visible={showModal}
            onRequestClose={handleClose}
            animationType="slide" // Choose an appropriate animation
            transparent
        >
            <View style={styles.overlay}>
                <View style={styles.modalContainer}>
                    <Text style={styles.modalTitle}>Update password</Text>
                    <View style={Spacing.mt3}>
                        <View style={styles.inputRow}>
                            <Text style={styles.label}>Old password</Text>
                            <TextInput
                                style={styles.input}
                                secureTextEntry
                                value={formData.old_password}
                                onChangeText={(text) => handleChange('old_password', text)}
                                placeholder="Enter old password"
                            />
                        </View>
                        <View style={styles.inputRow}>
                            <Text style={styles.label}>New password</Text>
                            <TextInput
                                style={styles.input}
                                secureTextEntry
                                value={formData.new_password}
                                onChangeText={(text) => handleChange('new_password', text)}
                                placeholder="Enter new password"
                            />
                        </View>
                        <View style={styles.inputRow}>
                            <Text style={styles.label}>Confirm new password</Text>
                            <TextInput
                                style={styles.input}
                                secureTextEntry
                                value={formData.confirm_new_password}
                                onChangeText={(text) => handleChange('confirm_new_password', text)}
                                placeholder="Enter confirm new password"
                            />
                        </View>
                    </View>
                    <View style={styles.modalFooter}>
                        <TouchableOpacity style={styles.closeButton} onPress={handleClose}>
                            <Text style={styles.closeButtonText}>Close</Text>
                        </TouchableOpacity>
                        <TouchableOpacity
                            style={styles.saveButton}
                            onPress={handleSubmit}
                            disabled={loading}
                        >
                            {loading ? (
                                <ActivityIndicator color="white" /> // Use ActivityIndicator for loading
                            ) : (
                                <Text style={styles.saveButtonText}>Save</Text>
                            )}
                        </TouchableOpacity>
                    </View>
                </View>
            </View>
        </Modal>
    );
};

const styles = StyleSheet.create({
    overlay: {
        flex: 1,
        backgroundColor: 'rgba(0,0,0,0.3)',
        justifyContent: 'center',
        padding: 16,
    },
    modalContainer: {
        backgroundColor: '#fefefe',
        borderRadius: 16,
        padding: 20,
        maxHeight: '90%',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.2,
        shadowRadius: 4,
        elevation: 5,
    },
    modalHeader: {
        alignItems: 'center',
        paddingBottom: 12,
    },
    modalTitle: {
        fontSize: 18,
        fontWeight: '600',
        backgroundColor: '#f6f0ff', // Light orange
        paddingVertical: 12,
        paddingHorizontal: 16,
        borderTopLeftRadius: 16,
        borderTopRightRadius: 16,
        marginTop: -20,
        marginHorizontal: -20,
        color: '#333',
    },
    inputRow: {
        marginBottom: 4,
    },
    label: {
        fontSize: 14,
        color: '#7c7c7c', // Muted label color
        marginBottom: 8,
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
    modalFooter: {
        flexDirection: 'row',
        justifyContent: 'flex-end',
        marginTop: 20,
        gap: 15
    },
    closeButton: {
        backgroundColor: '#f0f0f0',
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 10,
    },
    closeButtonText: {
        color: '#333',
        fontWeight: '500',
    },
    saveButton: {
        backgroundColor:  Colors.quaternary, // Blue save button
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 10,
    },
    saveButtonText: {
        color: '#fff',
        fontWeight: '600',
    },
});

export default UpdatePasswordModal;
