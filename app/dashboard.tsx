import React, {useEffect, useLayoutEffect, useState} from 'react';
import {ScrollView, StyleSheet, Text, TouchableOpacity, View} from 'react-native';
import {useDispatch, useSelector} from 'react-redux';
import {Colors} from "../src/styles/colors";
import Icon from 'react-native-vector-icons/FontAwesome6';
import APIService from "../src/ApiService/api.service";
import moment from 'moment';
import RecentHistorySection from "../src/components/Dashboard/RecentHistorySection";
import AnimatedCounter from "../src/components/Dashboard/AnimatedCounter";
import {getLast7DaysData} from "../src/utils/helper";
import Past7DaysStats from "../src/components/Dashboard/Past7DaysStats";
import ScreenWithHeader from "../src/components/layout/ScreenWithHeader";
import AsyncStorage from '@react-native-async-storage/async-storage';
import {getUserData} from "@/src/redux/Actions/UserActions";


const api = new APIService();

export default function Dashboard() {
    const dispatch:any = useDispatch();
    const userData = useSelector((state) => state?.userData?.userData) || {};
    const [incomes, setIncomes] = useState([]);
    const [expenses, setExpenses] = useState([]);
    const [stats, setStats] = useState({
        allData: [],
        total_incomes: 0,
        total_expenses: 0
    });
    const [loading, setLoading] = useState(true);
    const [greeting, setGreeting] = useState("Good Morning");

    const now = moment();
    const hour = now.hour();

    useEffect(() => {
        setGreeting(hour >= 5 && hour < 12 ? 'Good morning' :
            hour >= 12 && hour < 18 ? 'Good afternoon' :
                'Good evening');
        checkLoggedInUser();
        getExpenses();
        getIncomes();
        getStats();
    }, []);

    const checkLoggedInUser = async () => {
        const user = await AsyncStorage.getItem('wealthify_user');
        if(!!user) {
            dispatch(getUserData(JSON.parse(user)));
        }
    };

    const getIncomes =async () => {
        const data = {};
        const momentObj = moment();
        data.start_date = momentObj.startOf('month').format("YYYY-MM-DD");
        data.end_date = momentObj.endOf('month').format("YYYY-MM-DD");
        api.getIncomes(data).then((res) => {
            setLoading(false);
            setIncomes(res.data);
        }).catch((err) => {
            setLoading(false);
        })
    };

    const getExpenses = () => {
        const data = {};
        const momentObj = moment();
        data.start_date = momentObj.startOf('month').format("YYYY-MM-DD");
        data.end_date = momentObj.endOf('month').format("YYYY-MM-DD");

        api.getExpenses(data).then((res) => {
            if (res.data) {
                setExpenses(res.data.expenses);
            }
        }).catch((err) => {
            //
        })
    };

    const getStats = () => {
        api.getStats()
            .then(res => {
                if (res.data) {
                    setStats(res.data?.response)
                }
            })
    };


    return (
        <ScreenWithHeader>
            <ScrollView>
                {/* Greeting and Location */}
                <View style={styles.greetingSection}>
                    <Text style={styles.greetingText}>
                        {greeting}, {capitalize(userData?.username)}
                    </Text>
                    <Text style={styles.locationText}>Tamilnadu, India</Text>
                </View>

                {/* Report Section */}
                <View style={styles.reportCard}>
                    <Text style={styles.reportTitle}>Report generated for {moment().format("MMMM")}</Text>
                    <Text style={styles.reportSubtitle}>Download your report</Text>
                    <TouchableOpacity style={styles.downloadButton}>
                        <Text style={styles.downloadText}>Download {moment().format("MMMM")}'s report</Text>
                    </TouchableOpacity>
                </View>

                {/* Statistics Section */}
                <View style={styles.statisticsSection}>
                    <Text style={styles.statisticsTitle}>Statistics</Text>

                    {/* Total Incomes */}
                    <View style={styles.statisticCard}>
                        <View style={styles.statisticLeft}>
                            <Text style={styles.statisticLabel}>TOTAL INCOMES</Text>
                            <Text style={styles.statisticValue}>₹<AnimatedCounter
                                fromValue={0}
                                toValue={stats.total_incomes || 0}
                                duration={1000}
                                style={styles.statisticValueAnimated}
                            /></Text>

                            <TouchableOpacity>
                                <Text style={styles.viewDetails}>View all Incomes</Text>
                            </TouchableOpacity>
                        </View>
                        <View style={styles.statisticRight}>
                            <View style={styles.iconContainer}>
                                <Icon name="sack-dollar" size={20} color={Colors.success}/>
                            </View>
                        </View>
                    </View>

                    {/* Total Expenses */}
                    <View style={styles.statisticCard}>
                        <View style={styles.statisticLeft}>
                            <Text style={styles.statisticLabel}>TOTAL EXPENSES</Text>
                            <Text style={styles.statisticValue}>₹<AnimatedCounter
                                fromValue={0}
                                toValue={stats.total_expenses || 0}
                                duration={1000}
                                style={styles.statisticValueAnimated}
                            /></Text>

                            <TouchableOpacity>
                                <Text style={styles.viewDetails}>View all expenses</Text>
                            </TouchableOpacity>
                        </View>
                        <View style={styles.statisticRight}>
                            <View style={[styles.iconContainer, {backgroundColor: '#FFE0E0'}]}>
                                <Icon name="chart-line" size={20} color="#FF4D4D"/>
                            </View>
                        </View>
                    </View>

                    {/* Total Balance */}
                    <View style={styles.statisticCard}>
                        <View style={styles.statisticLeft}>
                            <Text style={styles.statisticLabel}>TOTAL BALANCE</Text>
                            <Text style={styles.statisticValue}>₹<AnimatedCounter
                                fromValue={0}
                                toValue={(stats.total_incomes || 0) - (stats.total_expenses || 0)}
                                duration={1000}
                                style={styles.statisticValueAnimated}
                            /></Text>

                            <TouchableOpacity>
                                <Text style={styles.viewDetails}>View all savings</Text>
                            </TouchableOpacity>
                        </View>
                        <View style={styles.statisticRight}>
                            <View style={[styles.iconContainer, {backgroundColor: '#FFF3E0'}]}>
                                <Icon name="dollar-sign" size={20} color="#FF9800"/>
                            </View>
                        </View>
                    </View>
                </View>

                {/* Recent History Section */}
                <RecentHistorySection historyData={stats.allData || []}/>


                {/* Past 7 days stats Section */}
                <Past7DaysStats incomeData={getLast7DaysData(incomes)} expenseData={getLast7DaysData(expenses)}/>
            </ScrollView>

        </ScreenWithHeader>
    );
}

// Capitalize function for user name
const capitalize = (str = '') => {
    if (!str) return ''
    return str.charAt(0).toUpperCase() + str.slice(1);
};

const styles = StyleSheet.create({

    greetingSection: {
        paddingHorizontal: 16,
        paddingTop: 16,
    },
    greetingText: {
        fontSize: 18,
        fontWeight: 'bold',
        color: Colors.textPrimary,
    },
    locationText: {
        fontSize: 12,
        color: Colors.muted,
        marginTop: 4,
        fontWeight: 500
    },
    reportCard: {
        backgroundColor: Colors.primary,
        borderRadius: 8,
        padding: 16,
        marginHorizontal: 16,
        marginTop: 16,
    },
    reportTitle: {
        color: 'white',
        fontSize: 16,
        fontWeight: 'bold',
        marginBottom: 8,
    },
    reportSubtitle: {
        color: 'rgba(255, 255, 255, 0.8)',
        fontSize: 14,
        marginBottom: 16,
    },
    downloadButton: {
        backgroundColor: 'white',
        borderRadius: 10,
        paddingVertical: 10,
        alignItems: 'center',
    },
    downloadText: {
        color: Colors.primary,
        fontWeight: 'bold',
        fontSize: 16,
    },
    statisticsSection: {
        paddingHorizontal: 16,
        marginTop: 24,
    },
    statisticsTitle: {
        fontSize: 18,
        fontWeight: 'bold',
        color: Colors.textPrimary,
        marginBottom: 16,
    },
    statisticCard: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        backgroundColor: 'white',
        borderRadius: 8,
        padding: 16,
        marginBottom: 12,
    },
    statisticLeft: {
        flex: 1,
    },
    statisticLabel: {
        fontSize: 14,
        color: Colors.muted,
        marginBottom: 12,
        fontWeight: 500,
    },
    statisticValue: {
        fontSize: 18,
        fontWeight: 'bold',
        color: Colors.textPrimary,
        marginBottom: 12,
    },
    viewDetails: {
        color: Colors.primary,
        fontSize: 14,
    },
    statisticRight: {
        marginLeft: 16,
        alignSelf: 'flex-end'
    },
    iconContainer: {
        backgroundColor: '#E0F7FA', // Light blue for income
        borderRadius: 8,
        padding: 12,
    },
    historySection: {
        paddingHorizontal: 16,
        marginTop: 24,
    },
    historyTitle: {
        fontSize: 18,
        fontWeight: 'bold',
        color: Colors.textPrimary,
        marginBottom: 16,
    },
    historyCard: {
        backgroundColor: 'white',
        borderRadius: 8,
        padding: 16,
        alignItems: 'center',
        justifyContent: 'center',
    },
    noHistoryText: {
        color: Colors.muted,
        fontSize: 16,
    },
    pastStatsSection: {
        paddingHorizontal: 16,
        marginTop: 24,
        marginBottom: 80,
    },
    pastStatsTitle: {
        fontSize: 18,
        fontWeight: 'bold',
        color: Colors.textPrimary,
        marginBottom: 16,
    },
    pastStatsCard: {
        backgroundColor: 'white',
        borderRadius: 8,
        padding: 16,
    },
    graphPlaceholder: {
        height: 100, // Adjust as needed
        backgroundColor: '#f0f0f0', // Placeholder color for the graph
        marginBottom: 12,
    },
    legendContainer: {
        flexDirection: 'row',
        justifyContent: 'flex-end',
    },
    legendItem: {
        flexDirection: 'row',
        alignItems: 'center',
        marginLeft: 16,
    },
    legendColor: {
        width: 10,
        height: 10,
        borderRadius: 5,
        marginRight: 4,
    },
    legendText: {
        fontSize: 12,
        color: Colors.muted,
    },
    statisticValueAnimated: {
        fontSize: 16,
        fontWeight: 'bold',
        color: Colors.textPrimary,
    },
});

