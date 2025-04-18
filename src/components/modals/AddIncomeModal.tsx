import React, { useState, useEffect } from 'react';
import { Modal, View, Text, TextInput, TouchableOpacity, ScrollView, StyleSheet } from 'react-native';
import RNPickerSelect from 'react-native-picker-select';
import moment from 'moment';
import APIService from "../../ApiService/api.service";
import { deepClone } from "../../utils/helper";
import CustomDatePicker from "../common/CustomDatePicker";
import spacing from "../../styles/spacing";

const api = new APIService();

const AddIncomeModal = ({
                            visible,
                            onClose,
                            isUpdate = false,
                            selectedIncome = {},
                            updateData
                        }) => {
    const [initialForm, setInitialForm] = useState({
        title: '',
        description: '',
        amount: '',
        category: '',
        date: moment().format('YYYY-MM-DD')
    });
    const [showDatePicker, setShowDatePicker] = useState(false);

    const [loading, setLoading] = useState(false);
    const [categories, setCategories] = useState([]);
    const [formData, setFormData] = useState(deepClone(initialForm));
    const [errors, setErrors] = useState({});

    useEffect(() => {
        getCategories();
    }, []);

    const getCategories = () => {
        api.getCategories("income").then(res => {
            if (res.data?.length) {
                setCategories(res.data.map(res => ({
                    value: res.title,
                    label: res.title
                })));
            }
        });
    };

    useEffect(() => {
        if (isUpdate && selectedIncome) {
            setFormData({
                title: selectedIncome.title || '',
                description: selectedIncome.description || '',
                amount: selectedIncome.amount?.toString() || '',
                category: selectedIncome.category || '',
                date: moment(selectedIncome.date).format('YYYY-MM-DD') || '',
            });
        } else {
            setFormData(initialForm);
        }
    }, [isUpdate, selectedIncome]);

    const handleChange = (name, value) => {
        setErrors({});
        const shallowCopy = deepClone(formData);
        shallowCopy[name] = value;
        setFormData(shallowCopy);
    };

    const handleValidation = () => {
        let valid = true;
        let temp = {};
        if (!formData.title) {
            temp.title = 'Please enter title';
            valid = false;
        }
        if (!formData.category) {
            temp.category = 'Please select category';
            valid = false;
        }
        if (!formData.amount) {
            temp.amount = 'Please enter amount';
            valid = false;
        }
        setErrors(temp);
        return valid;
    };

    const handleSubmit = () => {
        if (!handleValidation()) return;
        const payload = {
            ...formData,
            amount: Number(formData.amount),
            date: moment(formData.date).format('YYYY-MM-DD'),
        };
        setLoading(true);
        if (isUpdate) {
            api.updateIncome(selectedIncome._id, payload).then(res => {
                if (res.data) {
                    setLoading(false);
                    updateData();
                    onClose();
                }
            }).catch(err => {
                setLoading(false);
                setErrors({ submit: true, text: err.response?.data?.message });
            });
        } else {
            api.addIncome(payload).then(res => {
                if (res.data) {
                    setLoading(false);
                    setFormData(initialForm);
                    onClose();
                    updateData();
                }
            }).catch(err => {
                setLoading(false);
                setErrors({ submit: true, text: err.response?.data?.message });
            });
        }
    };

    return (
        <Modal
            visible={visible}
            animationType="fade"
            transparent
            onRequestClose={onClose}
        >
            <View style={styles.overlay}>
                <View style={styles.modalContainer}>
                    <Text style={[styles.title, spacing.mb3, spacing.pl4, {fontSize: 20},]}>{isUpdate ? 'Update Income' : 'Add Income'}</Text>
                    <ScrollView>
                        <TextInput
                            placeholder="Enter title"
                            value={formData.title}
                            onChangeText={text => handleChange('title', text)}
                            style={styles.input}
                        />
                        {errors.title && <Text style={styles.error}>{errors.title}</Text>}

                        <RNPickerSelect
                            onValueChange={value => handleChange('category', value)}
                            onDonePress={() => { }}
                            placeholder={{ label: 'Search to select or create', value: null }}
                            items={categories}
                            value={formData.category}
                            style={pickerSelectStyles}
                        />
                        {errors.category && <Text style={styles.error}>{errors.category}</Text>}

                        <TextInput
                            placeholder="Enter income amount"
                            value={formData.amount}
                            keyboardType="numeric"
                            onChangeText={text => handleChange('amount', text.replace(/[^0-9]/g, ''))}
                            style={styles.input}
                        />
                        {errors.amount && <Text style={styles.error}>{errors.amount}</Text>}

                            <CustomDatePicker
                                value={formData.date }
                                onChange={(selectedDate) => {
                                    if (selectedDate) {
                                        handleChange('date', moment(selectedDate).format('YYYY-MM-DD'));
                                    }
                                }}
                            />

                        <TextInput
                            placeholder="Enter description"
                            value={formData.description}
                            onChangeText={text => handleChange('description', text)}
                            style={[styles.input, { height: 80}, spacing.mt2]}
                            multiline
                        />
                    </ScrollView>

                    <View style={styles.buttonRow}>
                        <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
                            <Text style={styles.cancelText}>Close</Text>
                        </TouchableOpacity>
                        <TouchableOpacity style={styles.submitButton} onPress={handleSubmit}>
                            <Text style={styles.submitText}>{isUpdate ? 'Update Income' : 'Add Income'}</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </View>
        </Modal>
    );
};

export default AddIncomeModal;

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
    title: {
        fontSize: 16,
        fontWeight: '600',
        backgroundColor: '#f6f0ff',
        paddingVertical: 12,
        borderTopLeftRadius: 16,
        borderTopRightRadius: 16,
        marginTop: -20,
        marginHorizontal: -20,
        color: '#333',
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
    error: {
        color: '#e74c3c',
        fontSize: 12,
        marginBottom: 10,
    },
    buttonRow: {
        display:'flex',
        flexDirection: 'row',
        justifyContent: 'flex-end',
        marginTop: 20,
        gap:15
    },
    cancelButton: {
        backgroundColor: '#f0f0f0',
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 10,
    },
    cancelText: {
        color: '#333',
        fontWeight: '500',
    },
    submitButton: {
        backgroundColor: '#ff5c5c',
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 10,
    },
    submitText: {
        color: '#fff',
        fontWeight: '600',
    },
});

const pickerSelectStyles = {
    inputIOS: {
        fontSize: 14,
        paddingVertical: 12,
        paddingHorizontal: 10,
        backgroundColor: '#f7f2ff',
        borderWidth: 1,
        borderColor: '#e6e1f8',
        borderRadius: 10,
        color: '#333',
        marginBottom: 10,
    },
    inputAndroid: {
        fontSize: 14,
        backgroundColor: '#f7f2ff',
        outlineWidth: 3,
        outlineColor: 'red',
        borderRadius: 10,
        color: '#000',
        marginBottom: 10,
    },
};
