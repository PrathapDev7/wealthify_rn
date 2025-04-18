import React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import moment from 'moment';
import {Colors} from "../../src/styles/colors";
import {formatNumberWithCommas} from "../../src/utils/helper";
import spacing from "../../src/styles/spacing";

const RecentHistoryItem = ({ item }) => {
    const isIncome = item.type === 'income';
    const color = isIncome ? Colors.success : Colors.danger; // Assuming you have these colors
    const sign = isIncome ? '+' : '-';

    return (
        <View style={[styles.historyItemCard, spacing.px3, spacing.py2, { backgroundColor: color }]}>
            <Text style={styles.historyItemCategory}>{item?.title || item?.category}</Text>
            <Text style={styles.historyItemSubCategory}>{item?.sub_category}</Text>
            <View style={styles.historyItemDetails}>
                <Text style={styles.historyItemDate}>{moment(item.date).format('MMM DD, YYYY')}</Text>
                <Text style={styles.historyItemAmount}>
                    {sign} ₹{formatNumberWithCommas(Number(item.amount || 0))}
                </Text>
            </View>
        </View>
    );
};

const RecentHistorySection = ({ historyData=[] }) => {
    return (
        <View style={styles.historySection}>
            <Text style={styles.historyTitle}>Recent History</Text>
            <View style={styles.historyListContainer}>
                {historyData.length > 0 ? (
                    historyData.map((item, index) => (
                        <RecentHistoryItem key={`historyData_${index}`} item={item} />
                    ))
                ) : (
                    <View style={styles.historyCard}>
                        <Text style={styles.noHistoryText}>No recent history found</Text>
                    </View>
                )}
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    historySection: {
        paddingHorizontal: 16,
        marginTop: 24,
    },
    historyTitle: {
        fontSize: 18,
        fontWeight: 'bold',
        color: Colors.darkText,
        marginBottom: 16,
    },
    historyListContainer: {
        // No specific styling needed here, the items will handle layout
    },
    historyCard: {
        backgroundColor: 'white',
        borderRadius: 8,
        padding: 16,
        alignItems: 'center',
        justifyContent: 'center',
    },
    noHistoryText: {
        color: Colors.lightTextDarker,
        fontSize: 16,
    },
    historyItemCard: {
        borderRadius: 8,
        marginBottom: 8,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    historyItemCategory: {
        fontSize: 16,
        fontWeight: 'bold',
        color: 'white',
        flex: 1,
    },
    historyItemSubCategory: {
        fontSize: 13,
        color: 'white',
        flex: 1,
    },
    historyItemDetails: {
        alignItems: 'flex-end',
    },
    historyItemDate: {
        fontSize: 12,
        color: 'rgba(255, 255, 255, 0.8)',
    },
    historyItemAmount: {
        fontSize: 16,
        fontWeight: 'bold',
        color: 'white',
        marginLeft: 8,
    },
});

export default RecentHistorySection;
