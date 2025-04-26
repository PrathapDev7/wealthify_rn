import React, {useEffect, useState} from 'react';
import {Animated, FlatList, ScrollView, StyleSheet, Text, TouchableOpacity, View} from 'react-native';
import Icon from 'react-native-vector-icons/FontAwesome6';
import {Colors} from '@/src/styles/colors';
import moment from 'moment';
import {useSelector} from 'react-redux';
import {useNavigation} from '@react-navigation/native';
import {capitalize, formatNumberWithCommas} from '@/src/utils/helper';
import ScreenWithHeader from "../src/components/layout/ScreenWithHeader";
import APIService from "../src/ApiService/api.service";
import {Swipeable} from 'react-native-gesture-handler';
import ConfirmationModal from "../src/components/common/ConfirmationModal";
import AddIncomeModal from "../src/components/modals/AddIncomeModal";
import { IncomeItemSkeleton } from '@/src/components/skeletons/IncomeItemSkeleton';
import {Skeleton} from "moti/skeleton";

interface Income {
    _id?: string;
    title?: string;
    date?: string;
    amount?: number;
}

interface RangeOption {
    label: string;
    value: number;
}

const api = new APIService();

export default function IncomeScreen() {
    const navigation = useNavigation();
    const userData = useSelector((state: any) => state?.userData?.userData) || {};
    const [incomes, setIncomes] = useState<Income[]>([]);
    const [filterType, setFilterType] = useState<number>(2); // 1: Today, 2: This month, 3: This year
    const [loading, setLoading] = useState<boolean>(true);
    const [addModalVisible, setAddModalVisible] = useState<boolean>(false);
    const [selectedIncome, setSelectedIncome] = useState<Income | null>(null);
    const [isUpdate, setIsUpdate] = useState<boolean>(false);
    const [confirmDeleteVisible, setConfirmDeleteVisible] = useState<boolean>(false);
    const [showActionMenu, setShowActionMenu] = useState<string | null>(null); // Income ID for action menu

    const rangeOptions: RangeOption[] = [
        {label: "Today", value: 1},
        {label: "This month", value: 2},
        {label: "This year", value: 3},
    ];

    useEffect(() => {
        getIncomes();
    }, [filterType]);

    const getIncomes = () => {

        const data: any = {type: filterType};
        const momentObj = moment();

        if (filterType === 2) {
            data.start_date = momentObj.startOf('month').format("YYYY-MM-DD");
            data.end_date = momentObj.endOf('month').format("YYYY-MM-DD");
        } else if (filterType === 3) {
            data.start_date = momentObj.startOf('year').format("YYYY-MM-DD");
            data.end_date = momentObj.endOf('year').format("YYYY-MM-DD");
        } else if (filterType === 1) {
            data.start_date = momentObj.format("YYYY-MM-DD");
            data.end_date = momentObj.format("YYYY-MM-DD");
        }

        api.getIncomes(data).then(res => {
            setIncomes(res.data as Income[]);
            setLoading(false);
        }).catch(err => {
            console.error("Error fetching incomes:", err);
            setLoading(false);
        });
    };

    const handleDeleteIncome = async () => {
        if (selectedIncome?._id) {
            setConfirmDeleteVisible(false);
            setLoading(true);
            try {
                const res = await api.deleteIncome(selectedIncome._id);
                if (res.data) {
                    await getIncomes();
                    // Show success toast here (replace with your RN toast library)
                    console.log("Income deleted successfully");
                } else {
                    // Show error toast here
                    console.log("Failed to delete income");
                }
            } catch (error: any) {
                console.error("Error deleting income:", error);
                // Show error toast here
            } finally {
                setLoading(false);
                setSelectedIncome(null);
            }
        }
    };

    const toggleActionMenu = (incomeId: string) => {
        setShowActionMenu(showActionMenu === incomeId ? null : incomeId);
    };

    const handleFilterChange = (value: number) => {
        setFilterType(value);
    };

    const renderRightActions = (progress: any, dragX: any, item: Income) => {
        const trans = dragX.interpolate({
            inputRange: [-160, 0],
            outputRange: [0, 160],
            extrapolate: 'clamp',
        });

        return (
            <Animated.View style={[styles.rightActionsContainer, {transform: [{translateX: trans}]}]}>
                <TouchableOpacity
                    style={[styles.actionButton, styles.editButton]}
                    onPress={() => {
                        setSelectedIncome(item);
                        setIsUpdate(true);
                        setAddModalVisible(true);
                    }}
                >
                    <Text style={styles.actionText}>Edit</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={[styles.actionButton, styles.deleteButton]}
                    onPress={() => {
                        setSelectedIncome(item);
                        setConfirmDeleteVisible(true);
                    }}
                >
                    <Text style={styles.deleteActionText}>Delete</Text>
                </TouchableOpacity>
            </Animated.View>
        );
    };


    const renderIncomeItem = ({item}: { item: Income }) => {
        const itemDate = moment(item?.date);
        const today = moment().startOf('day');
        const yesterday = moment().subtract(1, 'day').startOf('day');

        let sectionTitle = '';
        if (itemDate.isSame(today, 'day')) {
            sectionTitle = 'Today';
        } else if (itemDate.isSame(yesterday, 'day')) {
            sectionTitle = 'Yesterday';
        } else if (!incomes.find(inc => moment(inc.date).isSame(itemDate, 'day') && inc !== item)) {
            sectionTitle = itemDate.format('D MMM, YYYY');
        }

        return (
            <View style={styles.incomeItemWrapper}>
                {sectionTitle ? <Text style={styles.sectionHeader}>{sectionTitle}</Text> : null}

                <Swipeable
                    renderRightActions={(progress, dragX) => renderRightActions(progress, dragX, item)}
                >
                    <View style={styles.incomeItem}>
                        <View style={styles.leftSection}>
                            <View style={styles.iconBackground}>
                                <Icon name="money-bill-trend-up" size={24} color={Colors.success}/>
                            </View>
                            <View style={styles.textInfo}>
                                <Text style={styles.incomeTitle}>{capitalize(item?.title) || 'Income'}</Text>
                                <Text style={styles.incomeDate}>{itemDate.format("D MMM, YYYY")}</Text>
                            </View>
                        </View>
                        <View style={styles.rightSection}>
                            <Text style={styles.incomeAmount}>+₹{formatNumberWithCommas(item?.amount)}</Text>
                        </View>
                    </View>
                </Swipeable>
            </View>
        );
    };

    const groupedIncomes = incomes.reduce((acc: { [key: string]: Income[] }, current) => {
        const dateKey = moment(current.date).startOf('day').format('YYYY-MM-DD');
        if (!acc[dateKey]) {
            acc[dateKey] = [];
        }
        acc[dateKey].push(current);
        return acc;
    }, {});

    const groupedIncomeArray = Object.keys(groupedIncomes)
        .sort((a, b) => moment(b).valueOf() - moment(a).valueOf())
        .map(date => ({
            title: date === moment().startOf('day').format('YYYY-MM-DD') ? 'Today' :
                date === moment().subtract(1, 'day').startOf('day').format('YYYY-MM-DD') ? 'Yesterday' :
                    moment(date).format('DD-MMM-YYYY'),
            data: groupedIncomes[date],
        }));

    return (
        <ScreenWithHeader>
            <View style={styles.container}>
                {/* Header */}
                <View style={styles.header}>
                    <Text style={styles.headerTitle}>Incomes</Text>
                    <TouchableOpacity style={styles.addButton} onPress={() => setAddModalVisible(true)}>
                        <Text style={styles.addButtonText}>Add New Income</Text>
                    </TouchableOpacity>
                </View>


                {/* Filter Section */}
                <View style={styles.filterContainer}>
                    <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                        {rangeOptions.map((option) => (
                            <TouchableOpacity
                                key={option.value}
                                style={[
                                    styles.filterOption
                                ]}
                                onPress={() => handleFilterChange(option.value)}
                            >
                                <Text style={[styles.filterText,
                                    filterType === option.value ? styles.filterOptionActiveText : {},]}>{option.label}</Text>
                            </TouchableOpacity>
                        ))}
                    </ScrollView>
                </View>

                <FlatList
                    style={styles.listContainer}
                    data={loading ? Array.from({ length: 5 }) : Object.values(groupedIncomes).flat()}
                    keyExtractor={(item: any, index) =>
                        loading ? `skeleton-${index}` : item?._id?.toString() || Math.random().toString()
                    }
                    renderItem={({ item , index}) =>
                        loading ? <IncomeItemSkeleton styles={styles} index={index} /> : renderIncomeItem({ item })
                    }
                    ListEmptyComponent={
                        !loading
                            ? () => (
                                <View style={styles.emptyList}>
                                    <Text style={styles.emptyListText}>No income records found.</Text>
                                </View>
                            )
                            : null
                    }
                />

                {/* Add Income Modal */}
                {addModalVisible &&
                    <AddIncomeModal
                        visible={addModalVisible}
                        onClose={() => {
                            setAddModalVisible(false);
                            setIsUpdate(false);
                            setSelectedIncome(null);
                        }}
                        isUpdate={isUpdate}
                        selectedIncome={selectedIncome}
                        updateData={getIncomes}
                    />}


                <ConfirmationModal
                    visible={confirmDeleteVisible}
                    onClose={() => setConfirmDeleteVisible(false)}
                    onConfirm={handleDeleteIncome}
                    message="Are you sure you want to delete this income?"
                    confirmText="Delete"
                    cancelText="Cancel"
                />
            </View>
        </ScreenWithHeader>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F8F8F8',
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 16,
        paddingVertical: 16,
    },
    headerTitle: {
        color: Colors.textPrimary,
        fontSize: 18,
        fontWeight: 'bold',
    },
    addButton: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.success,
        paddingVertical: 8,
        paddingHorizontal: 12,
        borderRadius: 8,
    },
    addButtonText: {
        color: 'white',
        fontWeight: 'bold',
    },
    filterContainer: {
        backgroundColor: 'white',
        paddingHorizontal: 16,
        paddingVertical: 12,
        marginBottom: 10,
        marginHorizontal: 16,
    },
    filterOption: {
        marginRight: 10,
    },
    filterText: {
        fontSize: 14,
        paddingHorizontal: 8,
        paddingVertical: 4,
    },
    filterOptionActiveText: {
        color: 'white',
        backgroundColor: Colors.secondary,
        paddingHorizontal: 8,
        paddingVertical: 4,
        borderRadius: 4
    },
    radio: {
        height: 20,
        width: 20,
        borderRadius: 10,
        borderWidth: 2,
        borderColor: Colors.primary,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 5,
    },
    radioInner: {
        height: 12,
        width: 12,
        borderRadius: 6,
        backgroundColor: Colors.primary,
    },
    listContainer: {
        flex: 1,
        paddingHorizontal: 16,
    },
    listHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingVertical: 10,
        borderBottomWidth: 1,
        borderBottomColor: '#eee',
    },
    headerTitleText: {
        fontWeight: 'bold',
        color: Colors.muted,
        fontSize: 12,
        flex: 1,
        textAlign: 'left',
    },
    incomeItemWrapper: {
        backgroundColor: 'white',
        paddingHorizontal: 12,
        borderRadius: 8,
        marginBottom: 8,
    },
    incomeItem: {
        marginBottom: 8,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    leftSection: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    iconBackground: {
        backgroundColor: Colors.successLight,
        width: 40,
        height: 40,
        borderRadius: 8,
        justifyContent: 'center',
        alignItems: 'center',
        marginRight: 12,
    },
    textInfo: {},
    incomeTitle: {
        fontSize: 16,
        fontWeight: 'bold',
        color: Colors.textPrimary,
    },
    incomeDate: {
        fontSize: 12,
        color: Colors.muted,
    },
    rightSection: {
        alignItems: 'center',
        display: 'flex',
        flexDirection: 'row'

    },
    incomeAmount: {
        fontSize: 15,
        fontWeight: 600,
        color: Colors.success,
    },
    actionsButton: {
        padding: 8,
    },
    emptyList: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        paddingVertical: 20,
    },
    emptyListText: {
        color: Colors.muted,
        fontSize: 16,
    },
    loadingOverlay: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        justifyContent: 'center',
        alignItems: 'center',
    },
    actionMenu: {
        position: 'absolute',
        top: 30,
        right: 0,
        backgroundColor: 'white',
        borderRadius: 5,
        shadowColor: '#000',
        shadowOffset: {width: 0, height: 2},
        shadowOpacity: 0.2,
        shadowRadius: 2,
        elevation: 5,
        zIndex: 10,
    },
    actionMenuItem: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: 10,
        paddingHorizontal: 15,
    },
    actionMenuText: {
        color: Colors.textPrimary,
    },
    actionMenuDivider: {
        borderBottomWidth: 1,
        borderBottomColor: '#eee',
        marginHorizontal: 5,
    },
    modalOverlay: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
    },
    modalContent: {
        backgroundColor: 'white',
        padding: 20,
        borderRadius: 10,
        width: '80%',
    },
    closeButton: {
        marginTop: 20,
        alignSelf: 'flex-end',
        padding: 10,
    },
    confirmationModal: {
        backgroundColor: 'white',
        padding: 20,
        borderRadius: 10,
        width: '80%',
        alignItems: 'center',
    },
    confirmationMessage: {
        fontSize: 16,
        color: Colors.textPrimary,
        marginBottom: 20,
        textAlign: 'center',
    },
    confirmationButtons: {
        flexDirection: 'row',
        justifyContent: 'space-around',
        width: '100%',
    },
    confirmButton: {
        backgroundColor: Colors.danger,
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 5,
    },
    confirmButtonText: {
        color: 'white',
        fontWeight: 'bold',
    },
    cancelButton: {
        backgroundColor: Colors.muted,
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 5,
    },
    cancelButtonText: {
        color: 'white',
        fontWeight: 'bold',
    },
    sectionHeader: {
        fontSize: 13,
        fontWeight: '500',
        color: Colors.muted,
        marginTop: 16,
        marginBottom: 8,
    },
    swipeActionButton: {
        justifyContent: 'center',
        alignItems: 'center',
        width: 70,
        padding: 10,
    },
    rightActionsContainer: {
        flexDirection: 'row',
        width: 160,
        paddingLeft: 12
    },
    actionButton: {
        flex: 1,
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        flexDirection: 'row',
        padding: 10,
        width: 80,
    },
    editButton: {
        backgroundColor: Colors.quaternary,
        borderTopLeftRadius: 4,
        borderBottomLeftRadius: 4,
    },
    deleteButton: {
        backgroundColor: Colors.dangerSubtle,
        borderColor: Colors.danger,
        borderWidth: 1,
        borderTopRightRadius: 4,
        borderBottomRightRadius: 4,
    },
    actionText: {
        color: 'white',
        fontWeight: '500',
        fontSize: 14
    },
    deleteActionText :{
        color: Colors.danger,
    }
});
