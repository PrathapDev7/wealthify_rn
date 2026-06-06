import React, { useState } from 'react';
import { View, Text, StyleSheet, Modal, TouchableOpacity, ActivityIndicator } from 'react-native';
import APIService from "../../ApiService/api.service";
import Toast from 'react-native-toast-message';
import Spacing from "@/src/styles/spacing";
import TextField from "@/src/components/ui/TextField";
import { Colors, Shadows, Typography, radius, space } from '@/src/styles/theme';


const api = new APIService();

interface FormData {
    old_password: string;
    new_password: string;
    confirm_new_password: string;
}

interface Props {
    showModal: boolean;
    closeModal: () => void;
    userData: { mobile: string };
}

const UpdatePasswordModal: React.FC<Props> = ({ showModal, closeModal }) => {
    const [loading, setLoading] = useState(false);
    const initialFormData: FormData = {
        old_password: "",
        new_password: "",
        confirm_new_password: ""
    };
    const [formData, setFormData] = useState(initialFormData);

    const handleChange = (name: keyof FormData, value: string) => {
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
            const res = await api.updatePassword(formData);
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
                    <View style={styles.modalHeader}>
                        <Text style={styles.modalTitle}>Update password</Text>
                    </View>
                    <View style={Spacing.mt3}>
                        <TextField
                            label="Old password"
                            placeholder="Enter old password"
                            value={formData.old_password}
                            onChangeText={(text) => handleChange('old_password', text)}
                            secureTextEntry
                            leftIconName="lock-closed-outline"
                        />
                        <TextField
                            label="New password"
                            placeholder="Enter new password"
                            value={formData.new_password}
                            onChangeText={(text) => handleChange('new_password', text)}
                            secureTextEntry
                            leftIconName="lock-closed-outline"
                        />
                        <TextField
                            label="Confirm new password"
                            placeholder="Re-enter new password"
                            value={formData.confirm_new_password}
                            onChangeText={(text) => handleChange('confirm_new_password', text)}
                            secureTextEntry
                            leftIconName="lock-closed-outline"
                        />
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
                                <ActivityIndicator color={Colors.textInverse} />
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
        backgroundColor: Colors.overlay,
        justifyContent: 'center',
        padding: space.xl,
    },
    modalContainer: {
        backgroundColor: Colors.surface,
        borderRadius: radius.md,
        padding: space.xl,
        maxHeight: '90%',
        ...Shadows.lg,
    },
    modalHeader: {
        marginBottom: space.sm,
    },
    modalTitle: {
        ...Typography.subtitle,
        color: Colors.text,
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
        marginTop: space.md,
        gap: space.md,
    },
    closeButton: {
        backgroundColor: Colors.surfaceMuted,
        paddingVertical: 11,
        paddingHorizontal: space.xl,
        borderRadius: radius.md,
    },
    closeButtonText: {
        ...Typography.bodyMedium,
        color: Colors.text,
    },
    saveButton: {
        minWidth: 92,
        backgroundColor: Colors.primary,
        paddingVertical: 11,
        paddingHorizontal: space.xl,
        borderRadius: radius.md,
        alignItems: 'center',
    },
    saveButtonText: {
        ...Typography.bodyMedium,
        color: Colors.textInverse,
    },
});

export default UpdatePasswordModal;
