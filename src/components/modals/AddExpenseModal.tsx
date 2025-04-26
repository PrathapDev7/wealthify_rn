import React, {useEffect, useRef, useState} from 'react';
import { Modal, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import moment from 'moment';
import APIService from "../../ApiService/api.service";
import {deepClone, formatWithCommas} from "../../utils/helper";
import spacing from "../../styles/spacing";
import CustomDatePicker from "@/src/components/common/CustomDatePicker";
import MySelectDropdown from "@/src/components/common/MySelectDropdown";
import { Colors } from '@/src/styles/colors';

interface Expense {
    _id?: string;
    category?: string;
    sub_category?: string;
    amount?: number;
    date?: string;
    description?: string;
    type?: 'self' | 'credit card';
}

interface Props {
    visible: boolean;
    onClose: () => void;
    isUpdate?: boolean;
    selectedExpense?: Expense;
    updateData: () => void;
}

const api = new APIService();

const AddExpenseModal: React.FC<Props> = ({
                                              visible,
                                              onClose,
                                              isUpdate = false,
                                              selectedExpense = {},
                                              updateData
                                          }) => {
    const [initialForm, setInitialForm] = useState<Expense>({
        category: '',
        sub_category: '',
        amount: undefined,
        date: moment().format('YYYY-MM-DD'),
        description: '',
        type: 'self', // Default value
    });
    const amountInputRef = useRef<TextInput>(null);
    const [loading, setLoading] = useState<boolean>(false);
    const [categories, setCategories] = useState<Array<any>[]>([]);
    const [subCategories, setSubCategories] = useState<Array<any>[]>([]);
    const [formData, setFormData] = useState<Expense>(deepClone(initialForm));
    const [errors, setErrors] = useState<{
        category?: string;
        amount?: string;
        submit?: boolean;
        text?: string;
    }>({});

    useEffect(() => {
        getCategories();
    }, []);

    useEffect(() => {
        if (visible) {
            setTimeout(() => {
                amountInputRef.current?.focus();
            }, 200);
        }
    }, [visible]);

    useEffect(() => {
        if (formData.category) {
            getSubCategories(formData.category);
        } else {
            setSubCategories([]);
            setFormData(prev => ({ ...prev, sub_category: '' }));
        }
    }, [formData.category]);

    const getCategories = () => {
        api.getCategories("expense").then(res => {
            if (res.data?.length) {
                setCategories(res.data.map((res: { title: string }) => ({
                    title: res.title,
                    value: res.title
                })));
            }
        });
    };

    const getSubCategories = (category: string) => {
        api.getSubCategories(category).then(res => {
            if (res.data?.length) {
                setSubCategories(res.data.map((res: { title: string }) => ({
                    title: res.title,
                    value: res.title
                })));
            } else {
                setSubCategories([]);
                setFormData(prev => ({ ...prev, sub_category: '' }));
            }
        });
    };

    useEffect(() => {
        if (isUpdate && selectedExpense) {
            setFormData({
                category: selectedExpense.category || '',
                sub_category: selectedExpense.sub_category || '',
                amount: selectedExpense.amount?.toString() ? parseFloat(selectedExpense.amount.toString()) : undefined,
                date: moment(selectedExpense.date).format('YYYY-MM-DD') || moment().format('YYYY-MM-DD'),
                description: selectedExpense.description || '',
                type: selectedExpense.type || 'self',
            });
        } else {
            setFormData(initialForm);
        }
    }, [isUpdate, selectedExpense]);

    const handleChange = (name: keyof Expense, value: string) => {
        setErrors({});
        const shallowCopy = deepClone(formData);
        shallowCopy[name] = value;
        setFormData(shallowCopy);
    };

    const handleValidation = () => {
        let valid = true;
        let temp: { category?: string; amount?: string } = {};
        if (!formData.amount) {
            temp.amount = 'Please enter amount';
            valid = false;
        }
        setErrors(temp);
        return valid;
    };

    const handleSubmit = () => {
        if (!handleValidation()) return;
        const payload: Expense = {
            ...formData,
            amount: formData.amount ? Number(formData.amount) : undefined,
            date: moment(formData.date).format('YYYY-MM-DD'),
        };
        setLoading(true);
        if (isUpdate && selectedExpense?._id) {
            api.updateExpense(selectedExpense._id, payload).then(res => {
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
            api.addExpense(payload).then(res => {
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

    const handleCreateCategory = (newCategory: string) => {
        const payload = { title: newCategory, type: "expense" };
        api.addCategory(payload).then(res => {
            if (res.data) {
                getCategories(); // Refresh categories
                setFormData(prev => ({ ...prev, category: newCategory }));
            }
        }).catch(err => {
            console.error("Error creating category:", err);
        });
    };

    const handleCreateSubCategory = (newSubCategory: string) => {
        if (formData.category) {
            const payload = { title: newSubCategory, category: formData.category };
            api.addSubCategory(payload).then(res => {
                if (res.data) {
                    getSubCategories(formData.category); // Refresh sub-categories
                    setFormData(prev => ({ ...prev, sub_category: newSubCategory }));
                }
            }).catch(err => {
                console.error("Error creating sub-category:", err);
            });
        } else {
            // Optionally show a message to select category first
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
                        style={[styles.title, spacing.mb3, spacing.pl4,]}>{isUpdate ? 'Update Expense' : 'Add Expense'}</Text>
                    <ScrollView>
                        <View style={styles.radioContainer}>
                            <TouchableOpacity
                                style={[styles.radioOption, formData.type === 'self' && styles.radioOptionActive]}
                                onPress={() => handleChange('type', 'self')}
                            >
                                <Text style={formData.type === 'self' && styles.radioOptionTextActive}>Self</Text>
                            </TouchableOpacity>
                            <TouchableOpacity
                                style={[styles.radioOption, formData.type === 'credit card' && styles.radioOptionActive]}
                                onPress={() => handleChange('type', 'credit card')}
                            >
                                <Text style={formData.type === 'credit card' && styles.radioOptionTextActive}>Credit Card</Text>
                            </TouchableOpacity>
                        </View>

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

                        <Text style={styles.label}>Category</Text>
                        <MySelectDropdown
                            onSelect={(value: string) => handleChange('category', value)}
                            //onCreateNew={(text) => handleCreateCategory(text)}
                            placeholder={'Select or create category'}
                            options={categories}
                            value={formData.category}
                        />

                        {formData.category && (
                            <>
                                <Text style={styles.label}>Sub-Category (Optional)</Text>
                                <MySelectDropdown
                                    onSelect={(value: string) => handleChange('sub_category', value)}
                                    //onCreateNew={(text) => handleCreateSubCategory(text)}
                                    placeholder={'Select or create sub-category'}
                                    options={subCategories}
                                    value={formData.sub_category}
                                />
                            </>
                        )}

                        <Text style={styles.label}>Date</Text>
                        <CustomDatePicker
                            value={formData.date}
                            onChange={(selectedDate) => {
                                if (selectedDate) {
                                    handleChange('date', moment(selectedDate).format('YYYY-MM-DD'));
                                }
                            }} placeholder={''}
                        />

                        <Text style={[styles.label, spacing.mt2]}>Description (Optional)</Text>
                        <TextInput
                            placeholder="Enter description"
                            value={formData.description}
                            onChangeText={text => handleChange('description', text)}
                            style={[styles.input, { height: 80 }]}
                            multiline
                        />
                    </ScrollView>

                    <View style={styles.buttonRow}>
                        <TouchableOpacity style={styles.cancelButton} onPress={onClose}>
                            <Text style={styles.cancelText}>Close</Text>
                        </TouchableOpacity>
                        <TouchableOpacity style={styles.submitButton} onPress={handleSubmit}>
                            <Text style={styles.submitText}>{isUpdate ? 'Update Expense' : 'Add Expense'}</Text>
                        </TouchableOpacity>
                    </View>
                    {errors.submit && <Text style={styles.error}>{errors.text}</Text>}
                </View>
            </View>
        </Modal>
    );
};

export default AddExpenseModal;

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
        fontSize: 18,
        fontWeight: '600',
        backgroundColor: '#f6f0ff', // Light orange
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
        backgroundColor: Colors.danger, // Orange
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 10,
    },
    submitText: {
        color: '#fff',
        fontWeight: '600',
    },
    radioContainer: {
        flexDirection: 'row',
        marginBottom: 15,
    },
    radioOption: {
        flex: 1,
        paddingVertical: 10,
        borderRadius: 8,
        borderWidth: 1,
        borderColor: '#ccc',
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 5,
    },
    radioOptionActive: {
        backgroundColor: Colors.primary,
        borderColor: '#ffcc80',
    },
    radioOptionTextActive: {
        fontWeight: 'bold',
        color: 'white'
    },
});
