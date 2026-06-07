import React from 'react';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useRouter } from 'expo-router';
import Toast from 'react-native-toast-message';
import {
    Card,
    WealthifyIcon,
    PillButton,
    ScreenContainer,
} from '@/src/components/ui';
import { Colors, Shadows, Typography, radius, space } from '@/src/styles/theme';

const INVITE_ITEMS = [
    {
        icon: 'earn_rewards',
        title: 'Earn Rewards',
        body: 'Invite & earn prizes when friends join.',
    },
    {
        icon: 'earn_sharing',
        title: 'Earn Sharing',
        body: 'Share your link and earn too.',
    },
    {
        icon: 'track_referrals',
        title: 'Track Referrals',
        body: 'See who joined and what you earn.',
    },
];

export default function InviteEarnScreen() {
    const router = useRouter();
    const start = () => Toast.show({ type: 'info', text1: 'Invite flow coming soon' });

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.headerRow}>
                <TouchableOpacity style={styles.iconBtn} onPress={() => router.back()}>
                    <Icon name="chevron-back" size={20} color={Colors.text} />
                </TouchableOpacity>
                <View style={styles.headerSpacer} />
            </View>

            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
            >
                <View style={styles.cards}>
                    {INVITE_ITEMS.map((item) => (
                        <Card key={item.title} style={styles.inviteCard}>
                            <View style={styles.inviteIcon}>
                                <WealthifyIcon name={item.icon} size={28} />
                            </View>
                            <View style={styles.inviteBody}>
                                <Text style={styles.inviteTitle}>{item.title}</Text>
                                <Text style={styles.inviteText}>{item.body}</Text>
                            </View>
                        </Card>
                    ))}
                </View>

                <View style={styles.copy}>
                    <Text style={styles.title}>Invite Other People</Text>
                    <Text style={styles.body}>
                        Connect all your accounts from any bank. Add savings, credit cards, PayPal and more.
                    </Text>
                </View>

                <PillButton label="Get Started" onPress={start} size="lg" />
            </ScrollView>
        </ScreenContainer>
    );
}

const styles = StyleSheet.create({
    headerRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: space.xl,
        paddingTop: space.lg,
    },
    iconBtn: {
        width: 38,
        height: 38,
        borderRadius: 19,
        backgroundColor: Colors.surface,
        alignItems: 'center',
        justifyContent: 'center',
        ...Shadows.xs,
    },
    headerSpacer: {
        width: 38,
    },
    scroll: {
        flexGrow: 1,
        paddingHorizontal: space.xl,
        paddingTop: space['6xl'],
        paddingBottom: space['2xl'],
        justifyContent: 'flex-end',
    },
    cards: {
        gap: space.lg,
        marginBottom: space['6xl'],
    },
    inviteCard: {
        flexDirection: 'row',
        alignItems: 'center',
        minHeight: 82,
        borderRadius: radius.md,
    },
    inviteIcon: {
        width: 42,
        height: 42,
        borderRadius: radius.sm,
        backgroundColor: Colors.surfaceSoft,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: space.md,
    },
    inviteBody: {
        flex: 1,
    },
    inviteTitle: {
        ...Typography.bodyStrong,
        marginBottom: 2,
    },
    inviteText: {
        ...Typography.caption,
        color: Colors.textMuted,
    },
    copy: {
        alignItems: 'center',
        marginBottom: space['4xl'],
        paddingHorizontal: space.md,
    },
    title: {
        ...Typography.title,
        textAlign: 'center',
        marginBottom: space.sm,
    },
    body: {
        ...Typography.bodySm,
        color: Colors.textMuted,
        textAlign: 'center',
    },
});
