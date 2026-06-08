import React, { useMemo, useRef, useState } from 'react';
import {
    Image,
    NativeScrollEvent,
    NativeSyntheticEvent,
    ScrollView,
    StyleSheet,
    StyleProp,
    Text,
    useWindowDimensions,
    View,
    ViewStyle,
} from 'react-native';
import { useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
    PillButton,
    ScreenContainer,
    IconBadge,
} from '@/src/components/ui';
import { Colors, Shadows, Typography, space, radius, useColors, type ColorPalette } from '@/src/styles/theme';

interface Slide {
    title: string;
    body: string;
    illustration: (screenWidth: number) => React.ReactNode;
}

const EXTERNAL_ICONS = {
    megaphone: 'https://cdn-icons-png.flaticon.com/512/1379/1379940.png',
} as const;

const ImageIcon = ({
    uri,
    size,
    imageSize = size,
    elevated = false,
    bg = 'transparent',
    style,
}: {
    uri: string;
    size: number;
    imageSize?: number;
    elevated?: boolean;
    bg?: string;
    style?: StyleProp<ViewStyle>;
}) => (
    <View
        style={[
            illoStyles.imageIconFrame,
            elevated && Shadows.xs,
            { width: size, height: size, backgroundColor: bg },
            style,
        ]}
    >
        <Image
            source={{ uri }}
            resizeMode="contain"
            style={{ width: imageSize, height: imageSize }}
        />
    </View>
);

const FloatingIcons = ({ screenWidth }: { screenWidth: number }) => {
    const colors = useColors();
    const stageWidth = Math.min(screenWidth - space.xl * 4, 320);
    const center = stageWidth / 2;
    const chip = 52;
    const halfChip = chip / 2;
    const hero = 86;

    return (
        <View style={[illoStyles.orbitStage, { width: stageWidth }]}>
            <IconBadge name="bag-handle" color={Colors.cat.groceries} size={chip} iconSize={30} style={[illoStyles.float, { top: 0, left: center - halfChip }]} />
            <IconBadge name="book" color={Colors.cat.education} size={chip} iconSize={30} style={[illoStyles.float, { top: 68, left: stageWidth * 0.18 - halfChip }]} />
            <ImageIcon
                uri={EXTERNAL_ICONS.megaphone}
                size={chip}
                imageSize={42}
                bg={colors.surface}
                elevated
                style={[illoStyles.float, { top: 68, left: stageWidth * 0.82 - halfChip }]}
            />
            <IconBadge name="car-sport" color={Colors.cat.car} size={chip} iconSize={30} style={[illoStyles.float, { top: 178, left: stageWidth * 0.14 - halfChip }]} />
            <IconBadge name="home" color={Colors.cat.home} size={chip} iconSize={30} style={[illoStyles.float, { top: 178, left: stageWidth * 0.86 - halfChip }]} />
            <IconBadge name="airplane" color={Colors.cat.travel} size={chip} iconSize={30} style={[illoStyles.float, { top: 232, left: center - halfChip }]} />
            <IconBadge
                name="wallet"
                color={colors.primary}
                bg={colors.primarySoft}
                size={hero}
                iconSize={42}
                rounded="circle"
                style={[illoStyles.float, { top: 105, left: center - hero / 2 }]}
            />
        </View>
    );
};

const PieIcon = () => {
    const colors = useColors();
    return (
        <View style={illoStyles.miniOrbitStage}>
            <IconBadge
                name="pie-chart"
                color={colors.primary}
                bg={colors.primarySoft}
                size={120}
                iconSize={64}
                rounded="circle"
                style={[illoStyles.float, illoStyles.miniHero]}
            />
        </View>
    );
};

const InsightIcon = () => {
    const colors = useColors();
    return (
        <View style={illoStyles.miniOrbitStage}>
            <IconBadge
                name="bar-chart"
                color={colors.primary}
                bg={colors.primarySoft}
                size={120}
                iconSize={64}
                rounded="circle"
                style={[illoStyles.float, illoStyles.miniHero]}
            />
        </View>
    );
};

const SLIDES: Slide[] = [
    {
        title: 'Your Finances in One Place',
        body: 'Track every rupee — incomes, expenses, and budgets — without juggling apps.',
        illustration: (screenWidth) => <FloatingIcons screenWidth={screenWidth} />,
    },
    {
        title: 'Set Smart Budgets',
        body: 'Plan ahead with category budgets, and get nudged before you overspend.',
        illustration: () => <PieIcon />,
    },
    {
        title: 'Insights That Help',
        body: 'See trends month over month, spot patterns, and make better money decisions.',
        illustration: () => <InsightIcon />,
    },
];

export default function WelcomeScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const { width: screenWidth } = useWindowDimensions();
    const scrollRef = useRef<ScrollView>(null);
    const [page, setPage] = useState(0);
    const isLast = page === SLIDES.length - 1;

    const scrollToPage = (targetPage: number) => {
        const boundedPage = Math.min(Math.max(targetPage, 0), SLIDES.length - 1);
        setPage(boundedPage);
        scrollRef.current?.scrollTo({
            x: screenWidth * boundedPage,
            animated: true,
        });
    };

    const onScroll = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
        const idx = Math.round(e.nativeEvent.contentOffset.x / screenWidth);
        if (idx !== page) setPage(idx);
    };

    const next = async () => {
        if (isLast) {
            await AsyncStorage.setItem('wealthify_seen_welcome', '1');
            router.replace('/');
        } else {
            scrollToPage(page + 1);
        }
    };

    const skip = async () => {
        await AsyncStorage.setItem('wealthify_seen_welcome', '1');
        router.replace('/');
    };

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.skipRow}>
                {!isLast ? (
                    <Text onPress={skip} style={styles.skip}>
                        Skip
                    </Text>
                ) : <View />}
            </View>

            <ScrollView
                ref={scrollRef}
                horizontal
                pagingEnabled
                showsHorizontalScrollIndicator={false}
                onScroll={onScroll}
                onMomentumScrollEnd={onScroll}
                scrollEventThrottle={16}
                style={styles.flex}
            >
                {SLIDES.map((s, i) => (
                    <View key={i} style={[styles.slide, { width: screenWidth }]}>
                        <View style={styles.illoArea}>
                            {s.illustration(screenWidth)}
                        </View>
                        <View style={styles.copyArea}>
                            <Text style={styles.title}>{s.title}</Text>
                            <Text style={styles.body}>{s.body}</Text>
                        </View>
                    </View>
                ))}
            </ScrollView>

            <View style={styles.footer}>
                <View style={styles.dots}>
                    {SLIDES.map((_, i) => (
                        <View
                            key={i}
                            style={[
                                styles.dot,
                                i === page && styles.dotActive,
                            ]}
                        />
                    ))}
                </View>
                <PillButton
                    label={isLast ? 'Get Started' : 'Next'}
                    onPress={next}
                    size="lg"
                />
            </View>
        </ScreenContainer>
    );
}

const makeStyles = (colors: ColorPalette) => StyleSheet.create({
    flex: { flex: 1 },
    skipRow: {
        flexDirection: 'row',
        justifyContent: 'flex-end',
        paddingHorizontal: space.xl,
        paddingTop: space.lg,
        minHeight: 32,
    },
    skip: {
        ...Typography.bodyMedium,
        color: colors.textMuted,
    },
    slide: {
        flex: 1,
        paddingHorizontal: space.xl,
    },
    illoArea: {
        flex: 1.2,
        justifyContent: 'center',
    },
    copyArea: {
        flex: 1,
        paddingHorizontal: space.sm,
    },
    title: {
        ...Typography.titleLg,
        color: colors.text,
        textAlign: 'center',
        marginBottom: space.md,
    },
    body: {
        ...Typography.body,
        color: colors.textMuted,
        textAlign: 'center',
        lineHeight: 22,
    },
    footer: {
        paddingHorizontal: space.xl,
        paddingBottom: space['2xl'],
        paddingTop: space.lg,
    },
    dots: {
        flexDirection: 'row',
        justifyContent: 'center',
        marginBottom: space.xl,
    },
    dot: {
        width: 8,
        height: 8,
        borderRadius: radius.pill,
        backgroundColor: colors.borderStrong,
        marginHorizontal: 4,
    },
    dotActive: {
        width: 22,
        backgroundColor: colors.primary,
    },
});

const illoStyles = StyleSheet.create({
    orbitStage: {
        height: 290,
        alignSelf: 'center',
        position: 'relative',
    },
    miniOrbitStage: {
        width: 300,
        height: 340,
        alignSelf: 'center',
        marginTop: space['5xl'],
        position: 'relative',
    },
    miniHero: {
        top: 156,
        left: 90,
    },
    imageIconFrame: {
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'transparent',
        borderRadius: radius.md,
    },
    float: {
        position: 'absolute',
    },
});
