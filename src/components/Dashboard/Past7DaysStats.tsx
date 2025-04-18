import React, {useMemo} from 'react';
import {StyleSheet, Text, View} from 'react-native';
import {BarChart} from 'react-native-gifted-charts';
import {Colors} from "../../styles/colors";
import moment from "moment";

const Past7DaysStats = ({incomeData, expenseData}) => {


    const {
        chartData,
        maxValue,
        stepValue,
        yAxisLabelTexts,
    } = useMemo(() => {
        const labels = Array(7).fill(0).map((_, index) =>
            moment().subtract(index, 'day').format('ddd')
        ).reverse();

        const chartData = labels.flatMap((label, i) => ([
            {
                value: incomeData[i] || 0,
                frontColor: '#4CAF50',
                gradientColor: '#81C784',
                spacing: 6,
                label,
            },
            {
                value: expenseData[i] || 0,
                frontColor: '#E53935',
                gradientColor: '#EF9A9A',
            }
        ]));

        const rawMax = Math.max(...incomeData, ...expenseData, 1000);
        let step = 1000;
        let sections = Math.ceil(rawMax / step);

        while (sections > 5) {
            step += 500;
            sections = Math.ceil(rawMax / step);
        }

        const maxValue = sections * step;
        const stepValue = step;
        const yAxisLabelTexts = Array.from({length: sections + 1}, (_, i) => `${i * step / 1000}k`);

        return { chartData, maxValue, stepValue, yAxisLabelTexts };
    }, [incomeData, expenseData]);


    return (
        <View style={styles.container}>
            <Text style={styles.title}>Past 7 Days Stats</Text>
            <View style={styles.chartWrapper}>
                <BarChart
                    data={chartData}
                    barWidth={16}
                    initialSpacing={10}
                    spacing={14}
                    barBorderRadius={4}
                    showGradient
                    yAxisThickness={0}
                    xAxisType={'dashed'}
                    xAxisColor={'lightgray'}
                    yAxisTextStyle={{color: 'lightgray'}}
                    stepValue={stepValue}
                    maxValue={maxValue}
                    noOfSections={yAxisLabelTexts.length - 1}
                    yAxisLabelTexts={yAxisLabelTexts}
                    labelWidth={40}
                    xAxisLabelTextStyle={{color: 'lightgray', textAlign: 'center'}}
                />
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        margin: 16,
        padding: 16,
        borderRadius: 20,
        backgroundColor: 'white',
        marginBottom: 80
    },
    title: {
        color: Colors.textPrimary,
        fontSize: 16,
        fontWeight: 'bold',
    },
    chartWrapper: {
        paddingTop: 12,
        paddingRight: 20,
        paddingBottom: 12,
        alignItems: 'center',
        overflow: 'hidden'
    },
});

export default Past7DaysStats;
