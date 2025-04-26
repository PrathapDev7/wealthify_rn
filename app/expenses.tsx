import React, {useEffect, useState} from 'react';
import {Animated, FlatList, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View} from 'react-native';
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
import CustomDatePicker from "@/src/components/common/CustomDatePicker";
import AddExpenseModal from "@/src/components/modals/AddExpenseModal";
import MySelectDropdown from "@/src/components/common/MySelectDropdown";
import Spacing from "@/src/styles/spacing";
import AnimatedCounter from "@/src/components/Dashboard/AnimatedCounter";
import {IncomeItemSkeleton} from "@/src/components/skeletons/IncomeItemSkeleton";
import CommonSkeletonView from "@/src/components/common/CommonSkeletonView"; // For category dropdown

interface Expense {
    _id?: string;
    category?: string;
    sub_category?: string;
    amount?: number;
    date?: string;
    description?: string;
    type?: 'self' | 'credit card';
}

interface CategoryOption {
    label: string;
    value: string;
}

interface FilterState {
    keyword: string;
    start_date: Date | null;
    end_date: Date | null;
    category: string | null;
    type: number;
}

interface RangeOption {
    label: string;
    value: number;
}

const api = new APIService();

export default function ExpenseScreen() {
    const navigation = useNavigation();
    const userData = useSelector((state: any) => state?.userData?.userData) || {};
    const [expenses, setExpenses] = useState<Expense[]>([]);
    const [totalExpenses, setTotalExpenses] = useState<number>(0);
    const [filterType, setFilterType] = useState<number>(2); // 1: Today, 2: This month, 3: This year
    const [loading, setLoading] = useState<boolean>(true);
    const [addModalVisible, setAddModalVisible] = useState<boolean>(false);
    const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null);
    const [isUpdate, setIsUpdate] = useState<boolean>(false);
    const [confirmDeleteVisible, setConfirmDeleteVisible] = useState<boolean>(false);
    const [showActionMenu, setShowActionMenu] = useState<string | null>(null);
    const [categoryBasedExpensesRN, setCategoryBasedExpensesRN] = useState<CategoryOption[]>([]);
    const [filtersRN, setFiltersRN] = useState<FilterState>({
        keyword: '',
        start_date: null,
        end_date: null,
        category: null,
        type: 2, // Default to this month
    });

    const rangeOptions: RangeOption[] = [
        {label: "Today", value: 1},
        {label: "This month", value: 2},
        {label: "This year", value: 3},
    ];

    useEffect(() => {
        getCategories();
    }, []);

    useEffect(() => {
        getExpensesRN();
    }, [filtersRN]);

    const getCategories = async () => {
        try {
            const res = await api.getCategories("expense");
            if (res.data?.length) {
                setCategoryBasedExpensesRN(res.data.map((item: { title: string }) => ({
                    title: capitalize(item.title),
                    value: item.title
                })));
            }
        } catch (error: any) {
            console.error("Error fetching expense categories:", error);
        }
    };

    const getExpensesRN = async () => {
        setLoading(true);
        const data: any = {...filtersRN};
        const momentObj = moment();

        if (data.category) {
            data.keyword = data.category;
        }

        if (data.type) {
            if (Number(data.type) === 1) {
                delete data.start_date;
                delete data.end_date;
            } else if (Number(data.type) === 2) {
                data.start_date = momentObj.startOf('month').format("YYYY-MM-DD");
                data.end_date = momentObj.endOf('month').format("YYYY-MM-DD");
            } else if (Number(data.type) === 3) {
                data.start_date = momentObj.startOf('year').format("YYYY-MM-DD");
                data.end_date = momentObj.endOf('year').format("YYYY-MM-DD");
            }
        } else {
            if (data.start_date && data.end_date) {
                data.start_date = moment(data.start_date).format("YYYY-MM-DD");
                data.end_date = moment(data.end_date).format("YYYY-MM-DD");
            } else {
                delete data.start_date;
                delete data.end_date;
            }
        }

        delete data.type;
        delete data.category;

        try {
            const res = await api.getExpenses(data);
            setExpenses(res.data.expenses as Expense[]);
            setTotalExpenses(res.data.total_expenses as number);
            setLoading(false);
        } catch (error: any) {
            console.error("Error fetching expenses:", error);
            setLoading(false);
        }
    };

    const handleDeleteExpense = async () => {
        if (selectedExpense?._id) {
            setConfirmDeleteVisible(false);
            setLoading(true);
            try {
                const res = await api.deleteExpense(selectedExpense._id);
                if (res.data) {
                    await getExpensesRN();
                    console.log("Expense deleted successfully");
                    // Show success toast here
                } else {
                    console.log("Failed to delete expense");
                    // Show error toast here
                }
            } catch (error: any) {
                console.error("Error deleting expense:", error);
                // Show error toast here
            } finally {
                setLoading(false);
                setSelectedExpense(null);
            }
        }
    };

    const toggleActionMenu = (expenseId: string) => {
        setShowActionMenu(showActionMenu === expenseId ? null : expenseId);
    };

    const handleFilterChangeRN = (name: any, value: any) => {
        setFiltersRN(prevFilters => ({
            ...prevFilters,
            [name]: value,
        }));
    };

    const renderRightActions = (progress: any, dragX: any, item: Expense) => {
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
                        setSelectedExpense(item);
                        setIsUpdate(true);
                        setAddModalVisible(true);
                    }}
                >
                    <Text style={styles.actionText}>Edit</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={[styles.actionButton, styles.deleteButton]}
                    onPress={() => {
                        setSelectedExpense(item);
                        setConfirmDeleteVisible(true);
                    }}
                >
                    <Text style={styles.deleteActionText}>Delete</Text>
                </TouchableOpacity>
            </Animated.View>
        );
    };

    const renderExpenseItem = ({item}: { item: Expense }) => {
        const itemDate = moment(item?.date);
        const today = moment().startOf('day');
        const yesterday = moment().subtract(1, 'day').startOf('day');

        let sectionTitle = '';
        if (itemDate.isSame(today, 'day')) {
            sectionTitle = 'Today';
        } else if (itemDate.isSame(yesterday, 'day')) {
            sectionTitle = 'Yesterday';
        } else if (!expenses.find(exp => moment(exp.date).isSame(itemDate, 'day') && exp !== item)) {
            sectionTitle = itemDate.format('D MMM, YYYY');
        }

        return (
            <View style={styles.expenseItemWrapper}>
                {sectionTitle ? <Text style={styles.sectionHeader}>{sectionTitle}</Text> : null}
                <Swipeable
                    renderRightActions={(progress, dragX) => renderRightActions(progress, dragX, item)}
                >
                    <View style={styles.expenseItem}>
                        <View style={styles.leftSection}>
                            <View style={[styles.iconBackground, {backgroundColor: Colors.dangerSubtle}]}>
                                <Icon name="chart-line" size={18} color={Colors.danger}/>
                            </View>
                            <View style={styles.textInfo}>
                                <Text style={styles.expenseTitle}>{capitalize(item?.category) || 'Expense'}</Text>
                                <Text style={styles.expenseDate}>{itemDate.format("D MMM, YYYY")}</Text>
                            </View>
                        </View>
                        <View style={styles.rightSection}>
                            <Text style={styles.expenseAmount}>-₹{formatNumberWithCommas(item?.amount)}</Text>
                        </View>
                    </View>
                </Swipeable>
            </View>
        );
    };

    const groupedExpenses = expenses.reduce((acc: { [key: string]: Expense[] }, current) => {
        const dateKey = moment(current.date).startOf('day').format('YYYY-MM-DD');
        if (!acc[dateKey]) {
            acc[dateKey] = [];
        }
        acc[dateKey].push(current);
        return acc;
    }, {});

    const groupedExpenseArray = Object.keys(groupedExpenses)
        .sort((a, b) => moment(b).valueOf() - moment(a).valueOf())
        .map(date => ({
            title: date === moment().startOf('day').format('YYYY-MM-DD') ? 'Today' :
                date === moment().subtract(1, 'day').startOf('day').format('YYYY-MM-DD') ? 'Yesterday' :
                    moment(date).format('DD-MMM-YYYY'),
            data: groupedExpenses[date],
        }));

    const currentRangeLabel = rangeOptions.find(val => val.value === Number(filtersRN.type))?.label || '';

    return (
        <ScreenWithHeader>
            <View style={styles.container}>
                <View style={styles.header}>
                    <Text style={styles.headerTitle}>Expenses</Text>
                    <TouchableOpacity style={styles.addButton} onPress={() => setAddModalVisible(true)}>
                        <Text style={styles.addButtonText}>Add New Expense</Text>
                    </TouchableOpacity>
                </View>

                <View style={styles.card}>
                    <View style={styles.cardBody}>
                        <View style={styles.content}>
                            <View style={styles.statsHeader}>
                                <View style={styles.headerTextContainer}>
                                    <Text style={styles.headerText}>
                                        SPEND {currentRangeLabel.toUpperCase()}
                                    </Text>
                                    <View>
                                        {loading ?
                                            <CommonSkeletonView/>
                                            :
                                            <Text style={styles.amount}>
                                                <AnimatedCounter
                                                    fromValue={0}
                                                    loading={loading}
                                                    toValue={totalExpenses}
                                                    duration={1000}
                                                    style={styles.statisticValueAnimated}
                                                />
                                            </Text>}
                                    </View>
                                </View>
                            </View>
                            <View style={styles.iconContainer}>
                                <View style={styles.iconWrapper}>
                                    <Icon name="chart-line" size={18} color={Colors.danger}/>
                                </View>
                            </View>
                        </View>
                    </View>
                </View>

                <View style={styles.filterContainer}>
                    <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                        {rangeOptions.map((option) => (
                            <TouchableOpacity
                                key={option.value}
                                style={[
                                    styles.filterOption
                                ]}
                                onPress={() => handleFilterChangeRN('type', option.value)}
                            >
                                <Text style={[styles.filterText,
                                    filtersRN.type === option.value ? styles.filterOptionActiveText : {},]}>{option.label}</Text>
                            </TouchableOpacity>
                        ))}
                    </ScrollView>
                </View>

                <View style={styles.additionalFilters}>
                    <TextInput
                        style={styles.searchInput}
                        placeholder="Search expenses..."
                        value={filtersRN.keyword}
                        onChangeText={(text) => handleFilterChangeRN('keyword', text)}
                    />
                    <MySelectDropdown
                        onSelect={(value: string) => handleFilterChangeRN('category', value)}
                        placeholder={'Select category'}
                        options={categoryBasedExpensesRN}
                        value={filtersRN.category}
                    />
                    <View style={styles.datePickerRow}>
                        <View style={[styles.dateInputContainer, Spacing.mr2]}>
                            <CustomDatePicker
                                placeholder="Start Date"
                                value={filtersRN.start_date}
                                onChange={(date) => handleFilterChangeRN('start_date', date)}
                            />
                        </View>
                        <View style={styles.dateInputContainer}>
                            <CustomDatePicker
                                placeholder="End Date"
                                value={filtersRN.end_date}
                                onChange={(date) => handleFilterChangeRN('end_date', date)}
                                //minDate={filtersRN.start_date}
                            />
                        </View>
                    </View>
                    {(filtersRN.keyword || filtersRN.start_date || filtersRN.end_date || filtersRN.category) && (
                        <TouchableOpacity style={styles.clearFiltersButton} onPress={() => setFiltersRN({
                            keyword: '',
                            start_date: null,
                            end_date: null,
                            category: null,
                            type: filtersRN.type || 2,
                        })}>
                            <Text style={styles.clearFiltersText}>Clear Filters</Text>
                        </TouchableOpacity>
                    )}
                </View>

                <FlatList
                    style={styles.listContainer}
                    data={loading ? Array.from({length: 5}) : Object.values(groupedExpenses).flat()}
                    keyExtractor={(item: any, index) =>
                        loading ? `skeleton-${index}` : item?._id?.toString() || Math.random().toString()
                    }
                    renderItem={({item, index}) =>
                        loading ? <IncomeItemSkeleton styles={styles} index={index}/> : renderExpenseItem({item})
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

                {addModalVisible && (
                    <AddExpenseModal
                        visible={addModalVisible}
                        onClose={() => {
                            setAddModalVisible(false);
                            setIsUpdate(false);
                            setSelectedExpense(null);
                        }}
                        isUpdate={isUpdate}
                        selectedExpense={selectedExpense}
                        updateData={getExpensesRN}
                    />
                )}

                <ConfirmationModal
                    visible={confirmDeleteVisible}
                    onClose={() => setConfirmDeleteVisible(false)}
                    onConfirm={handleDeleteExpense}
                    message="Are you sure you want to delete this expense?"
                    confirmText="Delete"
                    cancelText="Cancel"
                />
            </View>
        </ScreenWithHeader>
    );
}

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
        backgroundColor: Colors.danger,
        paddingVertical: 8,
        paddingHorizontal: 12,
        borderRadius: 8,
    },
    addButtonText: {
        color: 'white',
        marginLeft: 8,
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
    listContainer: {
        flex: 1,
        paddingHorizontal: 16,
    },
    expenseItemWrapper: {
        backgroundColor: 'white',
        paddingHorizontal: 12,
        borderRadius: 8,
        marginBottom: 8,
        paddingBottom: 8,
    },
    expenseItem: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginRight: 10
    },
    leftSection: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    iconBackground: {
        width: 40,
        height: 40,
        borderRadius: 8,
        justifyContent: 'center',
        alignItems: 'center',
        marginRight: 12,
    },
    textInfo: {},
    expenseTitle: {
        fontSize: 16,
        fontWeight: 'bold',
        color: Colors.textPrimary,
    },
    expenseSubCategory: {
        fontSize: 12,
        color: Colors.muted,
        marginTop: 2,
    },
    expenseDate: {
        fontSize: 12,
        color: Colors.muted,
    },
    rightSection: {
        alignItems: 'flex-end',
    },
    expenseAmount: {
        fontSize: 16,
        fontWeight: '600',
        color: Colors.danger,
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
    sectionHeader: {
        fontSize: 13,
        fontWeight: '500',
        color: Colors.muted,
        marginTop: 16,
        marginBottom: 8,
    },
    rightActionsContainer: {
        flexDirection: 'row',
        width: 160,
    },
    actionButton: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
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
    },
    additionalFilters: {
        backgroundColor: 'white',
        paddingHorizontal: 16,
        paddingVertical: 12,
        marginHorizontal: 16,
        marginBottom: 10,
        borderRadius: 8,
    },
    searchInput: {
        backgroundColor: '#f7f2ff',
        borderColor: '#e6e1f8',
        borderWidth: 1,
        borderRadius: 10,
        paddingHorizontal: 12,
        paddingVertical: 10,
        marginBottom: 10,
        color: Colors.textPrimary,
    },
    datePickerRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    dateInputContainer: {
        flex: 1
    },
    clearFiltersButton: {
        backgroundColor: Colors.primary,
        paddingVertical: 10,
        borderRadius: 10,
        alignItems: 'center',
        marginTop:6
    },
    clearFiltersText: {
        color: 'white',
        fontWeight: 'bold',
    },
    card: {
        backgroundColor: 'white',
        borderRadius: 4,
        marginHorizontal: 16,
        marginVertical: 8,
    },
    cardBody: {
        padding: 16,
    },
    statsHeader: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    headerTextContainer: {
        flexGrow: 1,
    },
    headerText: {
        textTransform: 'uppercase',
        fontWeight: 'bold',
        color: Colors.muted,
        fontSize: 12,
        marginBottom: 6
    },
    content: {
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    amount: {
        fontSize: 16,
        fontWeight: 'semibold',
        color: Colors.textPrimary,
    },
    iconContainer: {
        marginLeft: 8,
    },
    iconWrapper: {
        width: 40,
        height: 40,
        borderRadius: 6,
        backgroundColor: Colors.dangerSubtle,
        alignItems: 'center',
        justifyContent: 'center',
    },
    statisticValueAnimated: {
        fontSize: 16,
        fontWeight: 'bold',
        color: Colors.textPrimary,
    },
});
