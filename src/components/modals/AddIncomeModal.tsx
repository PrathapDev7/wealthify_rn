import React, {useEffect, useRef, useState} from 'react';
import {Modal, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View} from 'react-native';
import moment from 'moment';
import APIService from "../../ApiService/api.service";
import {deepClone, formatWithCommas} from "../../utils/helper";
import CustomDatePicker from "../common/CustomDatePicker";
import spacing from "../../styles/spacing";
import MySelectDropdown from "@/src/components/common/MySelectDropdown";
import { Colors } from '@/src/styles/colors';


interface Income {
    _id?: string;
    title?: string;
    description?: string;
    amount?: number;
    category?: string;
    date?: string;
}

interface Props {
    visible: boolean;
    onClose: () => void;
    isUpdate?: boolean;
    selectedIncome?: Income;
    updateData: () => void;
}

const api = new APIService();

const AddIncomeModal: React.FC<Props> = ({
                                             visible,
                                             onClose,
                                             isUpdate = false,
                                             selectedIncome = {},
                                             updateData
                                         }) => {
    const [initialForm, setInitialForm] = useState<Income>({
        title: '',
        description: '',
        amount: undefined,
        category: '',
        date: moment().format('YYYY-MM-DD')
    });
    const amountInputRef = useRef<TextInput>(null);
    const [loading, setLoading] = useState(false);
    const [categories, setCategories] = useState<Array<any>[]>([]);
    const [formData, setFormData] = useState<Income>(deepClone(initialForm));
    const [errors, setErrors] = useState<{
        amount?: string;
        submit?: boolean;
        text?: string;
    }>({});

    useEffect(() => {
        if (visible) {
            setTimeout(() => {
                amountInputRef.current?.focus();
            }, 200);
        }
    }, [visible]);

    useEffect(() => {
        getCategories();
    }, []);

    const getCategories = () => {
        api.getCategories("income").then(res => {
            if (res.data?.length) {
                setCategories(res.data.map((res: { title: string }) => ({
                    title: res.title,
                    value: res.title
                })));
            }
        });
    };

    useEffect(() => {
        if (isUpdate && selectedIncome) {
            setFormData({
                title: selectedIncome.title || '',
                description: selectedIncome.description || '',
                amount: selectedIncome.amount?.toString() ? parseFloat(selectedIncome.amount.toString()) : undefined,
                category: selectedIncome.category || '',
                date: moment(selectedIncome.date).format('YYYY-MM-DD') || moment().format('YYYY-MM-DD'),
            });
        } else {
            setFormData(initialForm);
        }
    }, [isUpdate, selectedIncome]);

    const handleChange = (name: keyof Income, value: string) => {
        setErrors({});
        const shallowCopy = deepClone(formData);
        shallowCopy[name] = value;
        setFormData(shallowCopy);
    };

    const handleValidation = () => {
        let valid = true;
        let temp: { amount?: string } = {};
        if (!formData.amount) {
            temp.amount = 'Please enter amount';
            valid = false;
        }
        setErrors(temp);
        return valid;
    };

    const handleSubmit = () => {
        if (!handleValidation()) return;
        const payload: Income = {
            ...formData,
            amount: formData.amount ? Number(formData.amount) : undefined,
            date: moment(formData.date).format('YYYY-MM-DD'),
        };
        setLoading(true);
        if (isUpdate && selectedIncome?._id) {
            api.updateIncome(selectedIncome._id, payload).then(res => {
                if (res.data) {
                    setLoading(false);
                    updateData();
                    onClose();
                }
            }).catch(err => {
                setLoading(false);
                setErrors({submit: true, text: err.response?.data?.message});
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
                setErrors({submit: true, text: err.response?.data?.message});
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
                    <Text
                        style={[styles.title, spacing.mb3, spacing.pl4,]}>{isUpdate ? 'Update Income' : 'Add Income'}</Text>
                    <ScrollView>
                        <Text style={styles.label}>Amount</Text>
                        <TextInput
                            ref={amountInputRef}
                            placeholder="Enter income amount"
                            value={formData.amount ? `₹ ${formatWithCommas(formData.amount.toString())}` : '₹ '}
                            keyboardType="numeric"
                            onChangeText={text => {
                                const raw = text.replace(/[^0-9]/g, ''); // Remove non-numeric
                                handleChange('amount', raw); // Store raw numeric string/number
                            }}
                            style={[styles.input, errors.amount ? { borderColor: 'red' } : {}]}
                        />
                        <Text style={styles.label}>Title</Text>
                        <TextInput
                            placeholder="Enter title"
                            value={formData.title}
                            onChangeText={text => handleChange('title', text)}
                            style={styles.input}
                        />
                        {errors.amount && <Text style={styles.error}>{errors.amount}</Text>}
                        <Text style={styles.label}>Category</Text>
                        <MySelectDropdown
                            onSelect={(value: string) => handleChange('category', value)}
                            placeholder={'Select category'}
                            options={categories}
                            value={formData.category}
                        />
                        <Text style={styles.label}>Date</Text>
                        <CustomDatePicker
                            value={formData.date}
                            onChange={(selectedDate) => {
                                if (selectedDate) {
                                    handleChange('date', moment(selectedDate).format('YYYY-MM-DD'));
                                }
                            }} placeholder={''}
                        />
                        <Text style={[styles.label, spacing.mt2]}>Additional Info (Optional)</Text>
                        <TextInput
                            placeholder="Enter additional Info"
                            value={formData.description}
                            onChangeText={text => handleChange('description', text)}
                            style={[styles.input, {height: 80}]}
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
                    {errors.submit && <Text style={styles.error}>{errors.text}</Text>}
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
        shadowOffset: {width: 0, height: 2},
        shadowOpacity: 0.2,
        shadowRadius: 4,
        elevation: 5,
    },
    title: {
        fontSize: 18,
        fontWeight: '600',
        backgroundColor: '#f6f0ff',
        paddingVertical: 12,
        borderTopLeftRadius: 16,
        borderTopRightRadius: 16,
        marginTop: -20,
        marginHorizontal: -20,
        color: '#333',
    },
    label: {
        fontSize: 14,
        marginBottom: 8,
        color: '#7c7c7c',
    },
    input: {
        backgroundColor: '#f7f2ff',
        borderColor: '#e6e1f8',
        borderWidth: 1,
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
        display: 'flex',
        flexDirection: 'row',
        justifyContent: 'flex-end',
        marginTop: 20,
        gap: 15
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
        backgroundColor: Colors.success,
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 10,
    },
    submitText: {
        color: '#fff',
        fontWeight: '600',
    },
});
