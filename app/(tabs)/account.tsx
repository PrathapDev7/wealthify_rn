import React, { useEffect, useState } from 'react';
import {
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Toast from 'react-native-toast-message';
import { useDispatch } from 'react-redux';
import APIService from '@/src/ApiService/api.service';
import { getUserData } from '@/src/redux/Actions/UserActions';
import ConfirmationModal from '@/src/components/common/ConfirmationModal';
import UpdatePasswordModal from '@/src/components/modals/UpdatePasswordModal';
import {
    Card,
    PillButton,
    ScreenContainer,
} from '@/src/components/ui';
import {
    Colors,
    Fonts,
    Gradients,
    Shadows,
    Typography,
    radius,
    space,
} from '@/src/styles/theme';
import SkeletonBlock from '@/src/components/skeletons/SkeletonBlock';

const api = new APIService();

interface UserData {
    username: string;
    mobile: string;
}

export default function AccountScreen() {
    const router = useRouter();
    const dispatch: any = useDispatch();

    const [userData, setUserData] = useState<UserData>({ username: '', mobile: '' });
    const [editing, setEditing] = useState(false);
    const [draftName, setDraftName] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [showLogout, setShowLogout] = useState(false);
    const [showResetStorage, setShowResetStorage] = useState(false);
    const [loadingProfile, setLoadingProfile] = useState(true);

    useEffect(() => {
        loadProfile();
    }, []);

    const loadProfile = async () => {
        setLoadingProfile(true);
        try {
            const res = await api.getProfile();
            if (res.data?.data) {
                setUserData(res.data.data);
                setDraftName(res.data.data.username);
                dispatch(getUserData(res.data.data));
                await AsyncStorage.setItem(
                    'wealthify_user',
                    JSON.stringify(res.data.data),
                );
            }
        } catch {
            Toast.show({ type: 'error', text1: 'Failed to fetch profile' });
        } finally {
            setLoadingProfile(false);
        }
    };

    const saveName = async () => {
        if (!draftName.trim()) {
            return Toast.show({ type: 'error', text1: 'Name cannot be empty' });
        }
        try {
            const res = await api.updateProfile({ username: draftName.trim() });
            if (res.data) {
                Toast.show({ type: 'success', text1: 'Name updated' });
                setEditing(false);
                loadProfile();
            }
        } catch {
            Toast.show({ type: 'error', text1: 'Failed to update' });
        }
    };

    const logout = async () => {
        await AsyncStorage.multiRemove(['wealthify_token', 'wealthify_user']);
        router.replace('/');
    };

    const resetLocalAppData = async () => {
        await AsyncStorage.clear();
        setShowResetStorage(false);
        Toast.show({
            type: 'success',
            text1: 'Local app data reset',
            text2: 'Saved session and cached preferences were cleared.',
        });
        router.replace('/');
    };

    const initials = (userData.username || '?')
        .split(' ')
        .map((p) => p[0])
        .slice(0, 2)
        .join('')
        .toUpperCase();

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <ScrollView
                showsVerticalScrollIndicator={false}
                contentContainerStyle={styles.scroll}
            >
                <View style={styles.headerRow}>
                    <Text style={styles.title}>Account</Text>
                </View>

                {loadingProfile ? (
                    <AccountSkeleton />
                ) : (
                    <>
                <Card style={styles.userCard}>
                    <LinearGradient
                        colors={Gradients.avatarWarm as any}
                        start={{ x: 0, y: 0 }}
                        end={{ x: 1, y: 1 }}
                        style={styles.avatar}
                    >
                        <Text style={styles.avatarText}>{initials}</Text>
                    </LinearGradient>
                    <View style={styles.userBody}>
                        <Text style={styles.userName} numberOfLines={1}>
                            {userData.username || '—'}
                        </Text>
                        <Text style={styles.userSub} numberOfLines={1}>
                            +91 {userData.mobile || '—'}
                        </Text>
                    </View>
                    <TouchableOpacity
                        activeOpacity={0.85}
                        onPress={() => setEditing(true)}
                        style={styles.editBtn}
                    >
                        <Text style={styles.editText}>Edit</Text>
                    </TouchableOpacity>
                </Card>

                <TouchableOpacity
                    activeOpacity={0.9}
                    onPress={() => router.push('/premium')}
                >
                    <LinearGradient
                        colors={Gradients.premium as any}
                        start={{ x: 0, y: 0 }}
                        end={{ x: 1, y: 1 }}
                        style={styles.premiumBanner}
                    >
                        <View style={styles.premiumIcon}>
                            <Icon name="diamond" size={20} color={Colors.textInverse} />
                        </View>
                        <View style={{ flex: 1, marginLeft: space.md }}>
                            <Text style={styles.premiumTitle}>Premium Account</Text>
                            <Text style={styles.premiumSub}>Unlock advanced insights</Text>
                        </View>
                        <Icon name="chevron-forward" size={20} color={Colors.textInverse} />
                    </LinearGradient>
                </TouchableOpacity>

                <Text style={styles.sectionLabel}>Account Settings</Text>
                <Card padding={0} style={styles.groupCard}>
                    <SettingRow
                        icon="person-outline"
                        label="Account Information"
                        onPress={() => setEditing(true)}
                    />
                    <Divider />
                    <SettingRow
                        icon="key-outline"
                        label="Change Password"
                        onPress={() => setShowPassword(true)}
                    />
                    <Divider />
                    <SettingRow
                        icon="phone-portrait-outline"
                        label="Device"
                        onPress={() =>
                            Toast.show({ type: 'info', text1: 'Coming soon' })
                        }
                    />
                    <Divider />
                    <SettingRow
                        icon="business-outline"
                        label="Connect to Banks"
                        onPress={() =>
                            Toast.show({ type: 'info', text1: 'Coming soon' })
                        }
                    />
                </Card>

                <Text style={styles.sectionLabel}>Settings</Text>
                <Card padding={0} style={styles.groupCard}>
                    <SettingRow
                        icon="settings-outline"
                        label="Preferences"
                        onPress={() =>
                            Toast.show({ type: 'info', text1: 'Coming soon' })
                        }
                    />
                    <Divider />
                    <SettingRow
                        icon="trash-bin-outline"
                        label="Reset local app data"
                        danger
                        onPress={() => setShowResetStorage(true)}
                    />
                    <Divider />
                    <SettingRow
                        icon="help-circle-outline"
                        label="Help & Support"
                        onPress={() =>
                            Toast.show({ type: 'info', text1: 'Coming soon' })
                        }
                    />
                    <Divider />
                    <SettingRow
                        icon="information-circle-outline"
                        label="About"
                        onPress={() =>
                            Toast.show({ type: 'info', text1: 'Wealthify v1.0' })
                        }
                    />
                </Card>

                <PillButton
                    label="Logout"
                    variant="secondary"
                    onPress={() => setShowLogout(true)}
                    leftIcon={
                        <Icon name="log-out-outline" size={18} color={Colors.negative} />
                    }
                    textStyle={{ color: Colors.negative }}
                    style={styles.logoutBtn}
                />

                <View style={styles.bottomSpacer} />
                    </>
                )}
            </ScrollView>

            <UpdatePasswordModal
                showModal={showPassword}
                closeModal={() => setShowPassword(false)}
                userData={userData}
            />
            <ConfirmationModal
                visible={showLogout}
                onClose={() => setShowLogout(false)}
                onConfirm={logout}
                message="Are you sure you want to log out?"
                confirmText="Log me out"
                cancelText="Cancel"
            />
            <ConfirmationModal
                visible={showResetStorage}
                onClose={() => setShowResetStorage(false)}
                onConfirm={resetLocalAppData}
                message="Reset local app data on this device? This clears saved login, onboarding, tour, and cached profile data."
                confirmText="Reset data"
                cancelText="Keep data"
            />
        </ScreenContainer>
    );
}

const AccountSkeleton = () => (
    <>
        <Card style={styles.userCard}>
            <SkeletonBlock width={54} height={54} radius={radius.md} />
            <View style={styles.userBody}>
                <SkeletonBlock width={146} height={18} radius={9} />
                <SkeletonBlock width={112} height={14} radius={7} style={skeletonStyles.subline} />
            </View>
            <SkeletonBlock width={54} height={34} radius={17} />
        </Card>

        <View style={styles.premiumBanner}>
            <SkeletonBlock width={36} height={36} radius={18} />
            <View style={skeletonStyles.premiumBody}>
                <SkeletonBlock width={142} height={18} radius={9} />
                <SkeletonBlock width={126} height={13} radius={7} style={skeletonStyles.subline} />
            </View>
            <SkeletonBlock width={20} height={20} radius={10} />
        </View>

        <SkeletonBlock width={118} height={14} radius={7} style={skeletonStyles.sectionLabel} />
        <Card padding={0} style={styles.groupCard}>
            {Array.from({ length: 4 }).map((_, index) => (
                <View key={index}>
                    <SettingRowSkeleton width={index === 0 ? 152 : index === 1 ? 132 : 86} />
                    {index < 3 ? <Divider /> : null}
                </View>
            ))}
        </Card>

        <SkeletonBlock width={68} height={14} radius={7} style={skeletonStyles.sectionLabel} />
        <Card padding={0} style={styles.groupCard}>
            {Array.from({ length: 4 }).map((_, index) => (
                <View key={index}>
                    <SettingRowSkeleton width={[98, 142, 116, 54][index]} />
                    {index < 3 ? <Divider /> : null}
                </View>
            ))}
        </Card>

        <SkeletonBlock width="100%" height={48} radius={24} style={skeletonStyles.logout} />
        <View style={styles.bottomSpacer} />
    </>
);

const SettingRowSkeleton: React.FC<{ width: number }> = ({ width }) => (
    <View style={settingStyles.row}>
        <SkeletonBlock width={32} height={32} radius={16} />
        <SkeletonBlock width={width} height={17} radius={8} style={skeletonStyles.settingLabel} />
        <SkeletonBlock width={18} height={18} radius={9} />
    </View>
);

const SettingRow: React.FC<{
    icon: string;
    label: string;
    danger?: boolean;
    onPress?: () => void;
}> = ({ icon, label, danger = false, onPress }) => (
    <TouchableOpacity
        activeOpacity={0.85}
        onPress={onPress}
        style={settingStyles.row}
    >
        <View style={settingStyles.iconWrap}>
            <Icon
                name={icon}
                size={20}
                color={danger ? Colors.negative : Colors.text}
            />
        </View>
        <Text style={[settingStyles.label, danger && settingStyles.labelDanger]}>
            {label}
        </Text>
        <Icon name="chevron-forward" size={18} color={Colors.textSubtle} />
    </TouchableOpacity>
);

const Divider = () => <View style={settingStyles.divider} />;

const styles = StyleSheet.create({
    scroll: {
        paddingHorizontal: space.xl,
        paddingTop: space.lg,
        paddingBottom: space['3xl'],
    },
    headerRow: {
        alignItems: 'center',
        paddingTop: space.md,
        paddingBottom: space.md,
        marginBottom: space.xl,
    },
    title: {
        ...Typography.screenTitle,
    },
    userCard: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: space.lg,
    },
    avatar: {
        width: 54,
        height: 54,
        borderRadius: radius.md,
        alignItems: 'center',
        justifyContent: 'center',
    },
    avatarText: {
        ...Typography.titleLg,
        fontSize: 22,
        color: Colors.deepPurple,
    },
    userBody: {
        flex: 1,
        marginLeft: space.md,
    },
    userName: {
        ...Typography.bodyMedium,
    },
    userSub: {
        ...Typography.bodySm,
    },
    editBtn: {
        paddingHorizontal: space.md,
        paddingVertical: 8,
        borderRadius: radius.pill,
        backgroundColor: Colors.primarySoft,
    },
    editText: {
        ...Typography.bodySm,
        fontFamily: Fonts.semibold,
        color: Colors.primary,
    },
    premiumBanner: {
        flexDirection: 'row',
        alignItems: 'center',
        padding: space.lg,
        borderRadius: radius.md,
        marginTop: space.md,
        ...Shadows.primaryGlow,
    },
    premiumIcon: {
        width: 36,
        height: 36,
        borderRadius: 18,
        backgroundColor: 'rgba(255,255,255,0.2)',
        alignItems: 'center',
        justifyContent: 'center',
    },
    premiumTitle: {
        ...Typography.subtitle,
        color: Colors.textInverse,
    },
    premiumSub: {
        ...Typography.caption,
        color: 'rgba(255,255,255,0.85)',
    },
    sectionLabel: {
        ...Typography.label,
        marginTop: space['2xl'],
        marginBottom: space.sm,
    },
    groupCard: {
        overflow: 'hidden',
    },
    logoutBtn: {
        marginTop: space.xl,
        borderColor: Colors.negativeSoft,
    },
    bottomSpacer: {
        height: 104,
    },
});

const settingStyles = StyleSheet.create({
    row: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: space.lg,
        paddingVertical: 15,
    },
    iconWrap: {
        width: 32,
        height: 32,
        alignItems: 'center',
        justifyContent: 'center',
    },
    label: {
        flex: 1,
        marginLeft: space.sm,
        ...Typography.bodyMedium,
    },
    labelDanger: {
        color: Colors.negative,
    },
    divider: {
        height: 1,
        backgroundColor: Colors.divider,
        marginLeft: 60,
    },
});

const skeletonStyles = StyleSheet.create({
    subline: {
        marginTop: 6,
    },
    premiumBody: {
        flex: 1,
        marginLeft: space.md,
    },
    sectionLabel: {
        marginTop: space['2xl'],
        marginBottom: space.sm,
    },
    settingLabel: {
        flex: 1,
        marginLeft: space.sm,
    },
    logout: {
        marginTop: space.xl,
    },
});
