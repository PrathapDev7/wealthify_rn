import { View, StyleSheet } from 'react-native';
import { Skeleton } from 'moti/skeleton';
import Spacing from "@/src/styles/spacing";

export const IncomeItemSkeleton = ({
                                       styles,
    index
                                   }) => {

    return (
        <View style={styles.incomeItemWrapper}>
            <Skeleton.Group show={true}>
                {index === 0 &&
                    <View style={Spacing.my3}>
                    <Skeleton
                        width={100}
                        height={16}
                        radius={4}
                        colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']}
                    />
                </View>}
                <View style={styles.incomeItem}>
                    <View style={styles.leftSection}>
                        <Skeleton
                            width={40}
                            height={40}
                            radius={4}
                            colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']}
                        />
                        <View style={[styles.textInfo, Spacing.ml2]}>
                            <Skeleton
                                height={16}
                                width={80}
                                radius={4}
                                colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']}
                            />
                            <View style={Spacing.mt2}>
                            <Skeleton
                                height={14}
                                width={60}
                                radius={4}
                                colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']}
                            />
                            </View>
                        </View>
                    </View>

                    <View style={styles.rightSection}>
                        <Skeleton
                            height={20}
                            width={70}
                            radius={4}
                            colors={['#dcdcdc', '#cfcfcf', '#dcdcdc']}
                        />
                    </View>
                </View>
            </Skeleton.Group>
        </View>
    );
};
