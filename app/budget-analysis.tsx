import React, {useEffect, useState} from 'react';
import {ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View} from 'react-native';
import {Colors} from '@/src/styles/colors'; // Assuming you have a colors file
import moment from "moment";
import {Skeleton} from 'moti/skeleton';
import {useNavigation} from '@react-navigation/native';
import APIService from "@/src/ApiService/api.service";
import {arrayOfObjectsToObject, calculateBudgetPercentage, objectToArrayOfObjects} from '@/src/utils/helper';
import CustomProgressBar from "@/src/components/common/CustomProgressBar";
import ScreenWithHeader from "@/src/components/layout/ScreenWithHeader";
import IconWithTooltip from "@/src/components/common/IconWithTooltip";
import spacing from "@/src/styles/spacing";
import Spacing from "@/src/styles/spacing";

const api = new APIService();

interface Stats {
    allData: any[];
    total_incomes: number;
    total_expenses: number;
}

interface Budget {
    _id?: string;
    category: string;
    amount: number;
}

interface ExpenseCategory {
    category: string;
    totalExpenses: number;
    amount?: string;
    haveBudget?: boolean;
}

const BudgetAnalysisScreen: React.FC = () => {
    const navigation = useNavigation(); // If you need navigation

    const [stats, setStats] = useState<Stats>({
        allData: [],
        total_incomes: 0,
        total_expenses: 0
    });
    const [incomes, setIncomes] = useState<any[]>([]);
    const [budgets, setBudgets] = useState<any>({});
    const [expenses, setExpenses] = useState<any[]>([]);
    const [isEdit, setIsEdit] = useState<number[]>([]);
    const [noBudgets, setNoBudgets] = useState<boolean>(true);
    const [loading, setLoading] = useState<boolean>(true);
    const [categoryBasedExpenses, setCategoryBasedExpenses] = useState<ExpenseCategory[]>([]);

    useEffect(() => {
        getExpenses();
        getStats();
    }, []);

    const calculateCategoryTotals = (transactions: any[]): ExpenseCategory[] => {
        const categoryTotals: { [key: string]: number } = transactions.reduce((acc, transaction) => {
            const {category, amount} = transaction;
            acc[category] = (acc[category] || 0) + amount;
            return acc;
        }, {});

        return Object.keys(categoryTotals).map((category) => ({
            category: category,
            totalExpenses: categoryTotals[category],
        }));
    };

    const getIncomes = () => {
        const data: any = {};
        const momentObj = moment();
        data.start_date = momentObj.startOf('month').format("YYYY-MM-DD");
        data.end_date = momentObj.endOf('month').format("YYYY-MM-DD");
        api.getIncomes(data).then((res) => {
            setIncomes(res.data);
        }).catch((err) => {
            console.error("Error fetching incomes:", err);
        });
    };

    const getExpenses = () => {
        const data: any = {};
        const momentObj = moment();
        data.start_date = momentObj.startOf('month').format("YYYY-MM-DD");
        data.end_date = momentObj.endOf('month').format("YYYY-MM-DD");
        api.getExpenses(data).then((res) => {
            setExpenses(res.data.expenses);
            getBudgets(calculateCategoryTotals(res.data.expenses));
        }).catch((err) => {
            console.error("Error fetching expenses:", err);
        });
    };

    const getBudgets = (categories: ExpenseCategory[] = []) => {
        api.getBudgets()
            .then(res => {
                if (res.data?.response) {
                    const budget: { [key: string]: Budget } = res.data?.response?.budgets;
                    const budgetsArr = (objectToArrayOfObjects(budget));
                    setBudgets(res.data?.response);
                    setNoBudgets(false);
                    setCategoryBasedExpenses(categories.map(cat => {
                        const findCat = budgetsArr.find(val => val.category === cat.category);
                        if (findCat) {
                            return {...cat, amount: findCat.amount.toString(), haveBudget: true};
                        }
                        return {...cat, amount: "", haveBudget: false};
                    }));
                    setLoading(false);
                } else {
                    setNoBudgets(true);
                    setCategoryBasedExpenses(categories.map(val => {
                        return {...val, amount: "", haveBudget: false};
                    }));
                    setLoading(false);
                }
            })
            .catch(err => {
                console.error("Error fetching budgets:", err);
                setLoading(false);
            });
    };

    const getStats = () => {
        api.getStats()
            .then(res => {
                if (res.data?.response) {
                    setStats(res.data?.response);
                }
            })
            .catch(err => {
                console.error("Error fetching stats:", err);
            });
    };

    const handleChange = (value: string, index: number) => {
        const shallowCopy = [...categoryBasedExpenses];
        shallowCopy[index].amount = value;
        setCategoryBasedExpenses(shallowCopy);
    };

    const addBudget = (index: number) => {
        setLoading(true);
        const filteredData = categoryBasedExpenses.filter(val => !!val.amount) || [];
        const data = filteredData.map(val => ({category: val.category, amount: Number(val.amount)}));

        const BudgetData = arrayOfObjectsToObject(data);
        api.addBudgets({budgets: BudgetData})
            .then(res => {
                setLoading(false);
                handleAddClose(index);
                getExpenses();
            })
            .catch(err => {
                console.error("Error adding budget:", err);
                setLoading(false);
            });
    };

    const updateBudgets = (index: number) => {
        setLoading(true);
        const filteredData = categoryBasedExpenses.filter(val => !!val.amount) || [];
        const data = filteredData.map(val => ({category: val.category, amount: Number(val.amount)}));

        const BudgetData = arrayOfObjectsToObject(data);
        api.updateBudgets(budgets._id, {budgets: BudgetData})
            .then(res => {
                setLoading(false);
                handleAddClose(index);
                getExpenses();
            })
            .catch(err => {
                console.error("Error updating budget:", err);
                setLoading(false);
            });
    };

    const handleAddClose = (index: number) => {
        setIsEdit(prev => prev.filter(item => item !== index));
    };

    const getColor = (currentPercentage: any): string => {
        return currentPercentage >= 90
            ? Colors.danger
            : currentPercentage >= 70
                ? Colors.warning
                : Colors.success;
    };


    const handleNumberInput = (text: string, onChange: (value: string) => void) => {
        const numericValue = text.replace(/[^0-9]/g, '');
        onChange(numericValue);
    };

    return (
        <ScreenWithHeader>
            <ScrollView style={styles.container}>
                <View style={styles.pageTitleContainer}>
                    <Text style={styles.pageTitle}>Budget Analysis</Text>
                    {/* BreadcrumbList would be a custom component for React Native */}
                </View>

                <View style={styles.card}>
                    <View style={styles.cardBody}>
                        <View style={styles.cardHeader}>
                            <Text style={styles.cardTitle}>Expense limit based on incomes</Text>
                            <IconWithTooltip
                                icon="lightbulb"
                                tooltip="Total expense limit based on your income."
                                color={Colors.warning}
                            />
                        </View>
                        <View style={styles.cardContent}>
                            <View style={styles.progressContainer}>
                                <View style={styles.progressHeader}>
                                    <Text style={styles.progressLabel}>TOTAL EXPENSES</Text>
                                    <Text
                                        style={[styles.progressPercentage, {color: getColor(calculateBudgetPercentage(stats.total_incomes, stats.total_expenses))}]}>
                                        {calculateBudgetPercentage(stats.total_incomes, stats.total_expenses)}%
                                    </Text>
                                </View>
                                {loading ?
                                    <Skeleton show={true} width={'100%'} colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']}
                                              height={10} radius={0}/>
                                    :
                                    <CustomProgressBar
                                        percentage={calculateBudgetPercentage(stats.total_incomes, stats.total_expenses)}
                                    />}
                            </View>
                        </View>
                    </View>
                </View>

                <View style={styles.card}>
                    <View style={styles.cardBody}>
                        <View style={styles.cardHeader}>
                            <Text style={styles.cardTitle}>Expense limit based on budgets</Text>
                            <IconWithTooltip
                                icon="lightbulb"
                                tooltip="Your expense's category will appear here."
                                color={Colors.warning}
                            />
                        </View>
                        <View style={styles.cardContent}>
                            {loading ? (
                                Array.from({ length: 5 }).map((_, index) => <CategoryItemSkeleton key={index} index={index} />)
                            ) : (
                                <>
                                    {categoryBasedExpenses.length > 0 ? (
                                        categoryBasedExpenses.map((category, index) => {
                                            const isLast = categoryBasedExpenses.length - 1 === index;
                                            return (
                                                <View key={index}
                                                      style={[styles.categoryItem, !isLast ? spacing.mb3 : {}]}>
                                                    <View style={styles.categoryInfo}>
                                                        <View style={styles.categoryNameWrapper}>
                                                            <Text style={styles.categoryName}>{category.category}</Text>
                                                            {category.haveBudget && (
                                                                <TouchableOpacity
                                                                    onPress={() => setIsEdit(prev => [...prev, index])}
                                                                    style={styles.editButton}>
                                                                    <Text style={styles.editButtonText}>Edit</Text>
                                                                </TouchableOpacity>
                                                            )}
                                                        </View>
                                                        {category.haveBudget &&
                                                            <View style={styles.progressHeader}>
                                                                <Text
                                                                    style={[styles.progressPercentage, {color: getColor(calculateBudgetPercentage(Number(category.amount), category.totalExpenses))}]}>
                                                                    {calculateBudgetPercentage(Number(category.amount), category.totalExpenses)}%
                                                                </Text>
                                                            </View>}
                                                    </View>
                                                    {(category.haveBudget && !isEdit.includes(index)) ? (
                                                        <View style={styles.progressContainer}>
                                                            <CustomProgressBar
                                                                percentage={calculateBudgetPercentage(Number(category.amount), category.totalExpenses)}
                                                            />
                                                        </View>
                                                    ) : (
                                                        <View>
                                                            {isEdit.includes(index) ? (
                                                                <View style={styles.inputRow}>
                                                                    <TextInput
                                                                        style={styles.input}
                                                                        value={category.amount}
                                                                        keyboardType="numeric"
                                                                        maxLength={8}
                                                                        placeholder="Enter budget"
                                                                        onChangeText={(text) => handleNumberInput(text, (value) => handleChange(value, index))}
                                                                    />
                                                                    <TouchableOpacity
                                                                        disabled={!category.amount}
                                                                        onPress={() => {
                                                                            if (noBudgets) {
                                                                                addBudget(index);
                                                                            } else {
                                                                                updateBudgets(index);
                                                                            }
                                                                        }}
                                                                        style={styles.saveButton}
                                                                    >
                                                                        <Text style={styles.saveButtonText}>Save</Text>
                                                                    </TouchableOpacity>
                                                                    <TouchableOpacity
                                                                        onPress={() => handleAddClose(index)}
                                                                        style={styles.cancelButton}
                                                                    >
                                                                        <Text
                                                                            style={styles.cancelButtonText}>Cancel</Text>
                                                                    </TouchableOpacity>
                                                                </View>
                                                            ) : (
                                                                <TouchableOpacity
                                                                    onPress={() => setIsEdit(prev => [...prev, index])}
                                                                    style={styles.addButton}
                                                                >
                                                                    <Text style={styles.addButtonText}>Add Monthly
                                                                        budget for {category.category}</Text>
                                                                </TouchableOpacity>
                                                            )}
                                                        </View>
                                                    )}
                                                </View>
                                            )
                                        })
                                    ) : (
                                        <View style={styles.emptyList}>
                                            <Text style={styles.emptyListText}>No expenses found</Text>
                                        </View>
                                    )}
                                </>
                            )}
                        </View>
                    </View>
                </View>
            </ScrollView>
        </ScreenWithHeader>
    );
};

const CategoryItemSkeleton = ({ index }: { index: number }) => {
    return (
        <View style={[styles.categoryItem, { marginBottom: 12 }]}>
            <Skeleton.Group show={true}>
                <View style={styles.categoryInfo}>
                    <View style={[styles.categoryNameWrapper, Spacing.pl2, Spacing.py2]}>
                        <Skeleton height={16} width={'70%'} radius={4} colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']} />
                    </View>
                    <View style={styles.progressHeader}>
                        <Skeleton height={14} width={30} radius={4} colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']} />
                    </View>
                </View>
                <Skeleton height={10} width={'100%'} radius={4} colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']} />
            </Skeleton.Group>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: Colors.background,
        padding: 16,
    },
    pageTitleContainer: {
        marginBottom: 16,
    },
    pageTitle: {
        fontSize: 20,
        fontWeight: 'bold',
        color: Colors.textPrimary,
    },
    card: {
        backgroundColor: Colors.lightText,
        borderRadius: 8,
        marginBottom: 16,
    },
    cardBody: {
        padding: 16
    },
    cardHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 4,
    },
    cardTitle: {
        fontSize: 15,
        fontWeight: 'bold',
        color: Colors.textPrimary,
    },
    cardContent: {},
    progressContainer: {},
    progressHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        backgroundColor: Colors.background,
        padding: 8,
        borderTopLeftRadius: 4,
        borderTopRightRadius: 4,
    },
    progressLabel: {
        fontSize: 13,
        fontWeight: 'bold',
        color: Colors.darkText,
    },
    progressPercentage: {
        fontWeight: 'bold',
        fontSize: 14,
    },
    skeletonItem: {
        marginBottom: 12,
    },
    categoryItem: {
        backgroundColor: Colors.background,
        borderRadius: 4,
    },
    categoryInfo: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center'
    },
    categoryNameWrapper: {
        flexDirection: 'row',
        alignItems: 'center'
    },
    categoryName: {
        fontWeight: 'bold',
        textTransform: 'uppercase',
        color: Colors.textPrimary,
        paddingHorizontal: 8,
    },
    editButton: {
        backgroundColor: Colors.quaternary,
        paddingVertical: 2,
        paddingHorizontal: 10,
        borderRadius: 4,
    },
    editButtonText: {
        color: Colors.lightText,
        fontSize: 12,
    },
    inputRow: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    input: {
        flex: 1,
        borderWidth: 1,
        borderColor: Colors.inputBorder,
        paddingVertical: 7,
        paddingHorizontal: 12,
        marginRight: 8,
        color: Colors.textPrimary,
        backgroundColor: Colors.inputBackground,
    },
    saveButton: {
        backgroundColor: Colors.quaternary,
        paddingVertical: 8,
        paddingHorizontal: 12,
        borderRadius: 4,
        marginRight: 8,
    },
    saveButtonText: {
        color: Colors.lightText,
        fontWeight: 'bold',
    },
    cancelButton: {
        backgroundColor: Colors.dangerSubtle,
        paddingVertical: 8,
        paddingHorizontal: 12,
        borderRadius: 4,
    },
    cancelButtonText: {
        color: Colors.danger,
        fontWeight: 'bold',
    },
    addButton: {
        backgroundColor: Colors.quaternary,
        paddingVertical: 8,
        paddingHorizontal: 12,
        borderRadius: 2,
    },
    addButtonText: {
        color: Colors.lightText,
        fontWeight: 'bold',
        fontSize: 13
    },
    emptyList: {
        alignItems: 'center',
        paddingVertical: 20,
    },
    emptyListText: {
        color: Colors.muted,
        fontSize: 16,
    }
});

export default BudgetAnalysisScreen;
