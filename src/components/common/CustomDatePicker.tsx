import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Modal } from 'react-native';
import DatePicker from 'react-native-date-picker';
import moment from 'moment';

const CustomDatePicker = ({ value, onChange }) => {
    const [show, setShow] = useState(false);

    const handleDateChange = (selectedDate) => {
        onChange(moment(selectedDate).format('YYYY-MM-DD'));
    };

    return (
        <View style={styles.container}>
            <TouchableOpacity style={styles.input} onPress={() => setShow(true)}>
                <Text style={{ color: '#555' }}>{value || 'Select Date'}</Text>
            </TouchableOpacity>

            <DatePicker
                modal
                open={show}
                date={new Date(value || Date.now())}
                onConfirm={(date) => {
                    setShow(false);
                    handleDateChange(date)
                }}
                onCancel={() => {
                    setShow(false)
                }}
            />
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    input: {
        borderWidth: 1,
        borderColor: '#e6e1f8',
        borderRadius: 8,
        backgroundColor: '#f7f2ff',
        padding: 10,
        width: '100%',
    },
    modalOverlay: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
    },
    datePickerContainer: {
        backgroundColor: 'white',
        padding: 20,
        borderRadius: 10,
        width: 300, // Set a specific width
    },
    closeButton: {
        marginTop: 10,
        backgroundColor: '#2196F3',
        padding: 10,
        borderRadius: 5,
        alignItems: 'center',
    },
    closeButtonText: {
        color: 'white',
        fontWeight: 'bold',
    },
});

export default CustomDatePicker;
