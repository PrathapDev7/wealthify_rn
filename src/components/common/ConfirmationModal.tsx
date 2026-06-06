import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Colors, Shadows, Typography, radius, space } from '@/src/styles/theme';

const ConfirmationModal = ({
                               visible,
                               onClose,
                               onConfirm,
                               message = 'Are you sure?',
                               confirmText = 'Delete',
                               cancelText = 'Cancel',
                           }) => {
    return (
        <Modal
            animationType="fade"
            transparent
            visible={visible}
            onRequestClose={onClose}
        >
            <View style={styles.overlay}>
                <View style={styles.modalContainer}>
                    <Text style={styles.message}>{message}</Text>
                    <View style={styles.buttonRow}>
                        <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
                            <Text style={styles.cancelText}>{cancelText}</Text>
                        </TouchableOpacity>
                        <TouchableOpacity style={styles.confirmButton} onPress={onConfirm}>
                            <Text style={styles.confirmText}>{confirmText}</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </View>
        </Modal>
    );
};

export default ConfirmationModal;

const styles = StyleSheet.create({
    overlay: {
        flex: 1,
        backgroundColor: Colors.overlay,
        justifyContent: 'center',
        alignItems: 'center',
        padding: space.xl,
    },
    modalContainer: {
        backgroundColor: Colors.surface,
        width: '100%',
        maxWidth: 360,
        borderRadius: radius.md,
        padding: space.xl,
        alignItems: 'center',
        ...Shadows.lg,
    },
    message: {
        ...Typography.bodyMedium,
        textAlign: 'center',
        marginBottom: space.xl,
        color: Colors.text,
    },
    buttonRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        width: '100%',
        gap: space.md,
    },
    confirmButton: {
        flex: 1,
        backgroundColor: Colors.negative,
        paddingVertical: 11,
        borderRadius: radius.md,
        alignItems: 'center',
    },
    cancelButton: {
        flex: 1,
        backgroundColor: Colors.surfaceMuted,
        paddingVertical: 11,
        borderRadius: radius.md,
        alignItems: 'center',
    },
    confirmText: {
        ...Typography.bodyMedium,
        color: Colors.textInverse,
    },
    cancelText: {
        ...Typography.bodyMedium,
        color: Colors.text,
    },
});
