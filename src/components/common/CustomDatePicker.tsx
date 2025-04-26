import React, {useEffect, useState} from 'react';
import {StyleSheet, View} from 'react-native';
import {Button} from 'react-native-paper';
import {DatePickerModal} from 'react-native-paper-dates';
import moment from 'moment';

export default function CustomDatePicker({value, onChange, placeholder}: {
    value: any,
    placeholder: string,
    onChange: (date: string) => void
}) {
    const [show, setShow] = useState(false);
    const [currentDate, setCurrentDate] = useState(new Date());

    useEffect(() => {
        if (value) {
            const parsedDate = moment(value, 'YYYY-MM-DD').isValid() ? new Date(value) : new Date();
            setCurrentDate(parsedDate);
        }
    }, [value]);

    const handleDateChange = (date: any) => {
        const formattedDate = moment(date).format('YYYY-MM-DD');
        setCurrentDate(date);
        onChange(formattedDate);
        setShow(false);
    };

    return (
        <View style={styles.container}>
            <Button
                mode="contained"
                compact={true}
                onPress={() => setShow(true)}
                style={styles.input}
                labelStyle={styles.inputText}
                contentStyle={styles.inputContent}
            >
                {value ? moment(value).format('MMM DD, YYYY') : (placeholder || 'Select Date')}
            </Button>

            {show && (
                <DatePickerModal
                    locale="en"
                    mode="single"
                    visible={show}
                    date={currentDate}
                    onDismiss={() => setShow(false)}
                    onConfirm={({date}) => handleDateChange(date)}
                />
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        justifyContent: 'center',
        alignItems: 'center',
        width: '100%',
    },
    input: {
        backgroundColor: '#f7f2ff',
        borderWidth: 1,
        borderColor: '#e6e1f8',
        padding: 0,
        borderRadius: 10,
        marginBottom: 4,
        width: '100%',
    },
    inputText: {
        fontSize: 12,
        color: '#333',
    },
    inputContent: {
        justifyContent: 'flex-start',
        color: '#333',
        paddingLeft: 6
    },
});
