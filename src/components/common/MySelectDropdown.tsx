import React, { useState, useEffect } from 'react';
import {
    StyleSheet,
    Text,
    View,
    TextInput,
    TouchableOpacity,
    Keyboard,
} from 'react-native';
import SelectDropdown from 'react-native-select-dropdown';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

const MySelectDropdown = ({ options = [], onSelect, placeholder = '', value='' }) => {
    const [localOptions, setLocalOptions] = useState([]);
    const [showCustomInput, setShowCustomInput] = useState(false);
    const [customInput, setCustomInput] = useState('');

    useEffect(() => {
        setLocalOptions([...options, { title: 'Others', icon: 'dots-horizontal' }]);
    }, [options]);

    const handleSelect = (item) => {
        if (item.title === 'Others') {
            setShowCustomInput(true);
            Keyboard.dismiss();
        } else {
            setShowCustomInput(false);
            onSelect(item.value);
        }
    };

    const handleSaveCustomOption = () => {
        if (!customInput.trim()) return;
        const newItem = { title: customInput.trim(), value: customInput.trim()};
        const updatedOptions = [
            ...localOptions.slice(0, -1),
            newItem,
            { title: 'Others', value: 'Others' },
        ];
        setLocalOptions(updatedOptions);
        setShowCustomInput(false);
        setCustomInput('');
        onSelect(newItem.value);
    };

    const handleCancel = () => {
        setShowCustomInput(false);
        setCustomInput('');
        onSelect(null);
    };

    // @ts-ignore
    return (
        <View>
            <SelectDropdown
                data={localOptions}
                onSelect={handleSelect}
                defaultButtonText={placeholder}
                buttonStyle={styles.dropdownButtonStyle}
                buttonTextStyle={styles.dropdownButtonTxtStyle}
                renderButton={(selectedItem, isOpened) => (
                    <View style={styles.dropdownButtonStyle}>
                        <Text style={styles.dropdownButtonTxtStyle}>
                            {value || placeholder}
                        </Text>
                        <Icon
                            name={isOpened ? 'chevron-up' : 'chevron-down'}
                            style={styles.dropdownButtonArrowStyle}
                        />
                    </View>
                )}
                renderItem={(item, index, isSelected) => (
                    <View
                        style={{
                            ...styles.dropdownItemStyle,
                            ...(isSelected && { backgroundColor: '#D2D9DF' }),
                        }}
                    >
                        <Text style={styles.dropdownItemTxtStyle}>{item.title}</Text>
                    </View>
                )}
                showsVerticalScrollIndicator={false}
                dropdownStyle={styles.dropdownMenuStyle}
            />

            {showCustomInput && (
                <View style={styles.customInputRow}>
                    <TextInput
                        placeholder="Enter new option"
                        value={customInput}
                        onChangeText={setCustomInput}
                        style={styles.customInput}
                    />
                    <TouchableOpacity onPress={handleSaveCustomOption} style={styles.actionButton}>
                        <Text style={styles.saveText}>Save</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={handleCancel} style={styles.actionButton}>
                        <Text style={styles.cancelText}>Cancel</Text>
                    </TouchableOpacity>
                </View>
            )}
        </View>
    );
};

const styles = StyleSheet.create({
    dropdownButtonStyle: {
        width: '100%',
        height: 50,
        backgroundColor: '#f7f2ff',
        borderWidth: 1,
        borderColor: '#e6e1f8',
        borderRadius: 10,
        marginBottom: 10,
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 12,
    },
    dropdownButtonTxtStyle: {
        flex: 1,
        fontSize: 14,
        color: '#333',
    },
    dropdownButtonArrowStyle: {
        fontSize: 20,
    },
    dropdownItemStyle: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 12,
        paddingVertical: 10,
    },
    dropdownItemTxtStyle: {
        flex: 1,
        fontSize: 18,
        fontWeight: '500',
        color: '#151E26',
    },
    dropdownItemIconStyle: {
        fontSize: 24,
        marginRight: 8,
    },
    dropdownMenuStyle: {
        backgroundColor: '#E9ECEF',
        borderRadius: 8,
    },
    customInputRow: {
        flexDirection: 'row',
        alignItems: 'center',
        marginTop: 8,
        backgroundColor: '#f7f2ff',
        padding: 8,
        borderRadius: 8,
    },
    customInput: {
        flex: 1,
        height: 40,
        borderColor: '#ccc',
        borderWidth: 1,
        borderRadius: 6,
        paddingHorizontal: 10,
        backgroundColor: '#fff',
        marginRight: 8,
    },
    actionButton: {
        paddingVertical: 6,
        paddingHorizontal: 10,
    },
    saveText: {
        color: '#4CAF50',
        fontWeight: 'bold',
    },
    cancelText: {
        color: '#FF4444',
        fontWeight: 'bold',
    },
});

export default MySelectDropdown;
