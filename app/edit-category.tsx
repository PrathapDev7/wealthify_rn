import React, { useCallback, useMemo, useState } from 'react';
import {
    ActivityIndicator,
    Image,
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    View,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import Toast from 'react-native-toast-message';
import { useFocusEffect, useLocalSearchParams, useRouter } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { Card, CircleIconButton, PillButton, ScreenContainer, TextField, WealthifyIcon } from '@/src/components/ui';
import {
    Colors,
    Typography,
    radius,
    space,
    useColors,
    type ColorPalette,
} from '@/src/styles/theme';
import { resolveCategoryIcon } from '@/src/utils/categoryIcon';
import ConfirmationModal from '@/src/components/common/ConfirmationModal';
import APIService from '@/src/ApiService/api.service';

const api = new APIService();

type CategoryType = 'expense' | 'income';

interface Category {
    _id: string;
    title: string;
    type: CategoryType;
    icon?: string;
    color?: string;
}

const SWATCHES = [
    Colors.cat.groceries,
    Colors.cat.travel,
    Colors.cat.car,
    Colors.cat.home,
    Colors.cat.marketing,
    Colors.cat.internet,
    Colors.cat.water,
    Colors.cat.rent,
];

export default function EditCategoryScreen() {
    const router = useRouter();
    const colors = useColors();
    const styles = useMemo(() => makeStyles(colors), [colors]);
    const params = useLocalSearchParams<{ id?: string; type?: string }>();
    const id = params.id;
    const type = (params.type as CategoryType) || 'expense';
    const isEdit = !!id;

    const [loading, setLoading] = useState(isEdit);
    const [saving, setSaving] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [confirmVisible, setConfirmVisible] = useState(false);

    const [title, setTitle] = useState('');
    const [icon, setIcon] = useState<string | undefined>(undefined);
    const [color, setColor] = useState<string | undefined>(undefined);

    const load = useCallback(() => {
        if (!id) return;
        setLoading(true);
        api.getCategories(type)
            .then((res) => {
                const data: Category[] = Array.isArray(res.data) ? res.data : [];
                const found = data.find((c) => c._id === id);
                if (found) {
                    setTitle(found.title ?? '');
                    setIcon(found.icon);
                    setColor(found.color);
                }
            })
            .catch(() => {})
            .finally(() => setLoading(false));
    }, [id, type]);

    useFocusEffect(useCallback(() => { load(); }, [load]));

    const isCustomIcon = !!icon && icon.startsWith('http');
    const resolved = resolveCategoryIcon(title, type);

    const onUpload = async () => {
        try {
            const res = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 0.7 });
            if (res.canceled) return;
            const asset = res.assets[0];
            setUploading(true);
            const form = new FormData();
            form.append('image', { uri: asset.uri, name: 'icon.jpg', type: 'image/jpeg' } as any);
            form.append('folder', 'category-icons');
            const up = await api.uploadImage(form);
            setIcon(up.data.data.url);
            Toast.show({ type: 'success', text1: 'Icon uploaded' });
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to upload icon',
            });
        } finally {
            setUploading(false);
        }
    };

    const onSave = async () => {
        const trimmed = title.trim();
        if (!trimmed) {
            return Toast.show({ type: 'error', text1: 'Enter a name' });
        }
        setSaving(true);
        try {
            if (isEdit && id) {
                await api.updateCategory(id, { title: trimmed, icon, color });
                Toast.show({ type: 'success', text1: 'Category updated' });
            } else {
                await api.addCategory({ title: trimmed, type, icon, color });
                Toast.show({ type: 'success', text1: 'Category added' });
            }
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to save category',
            });
        } finally {
            setSaving(false);
        }
    };

    const onDelete = async () => {
        if (!id) return;
        setConfirmVisible(false);
        try {
            await api.deleteCategory(id);
            Toast.show({ type: 'success', text1: 'Category deleted' });
            router.back();
        } catch (err: any) {
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Failed to delete category',
            });
        }
    };

    return (
        <ScreenContainer variant="wash" extendUnderStatusBar>
            <View style={styles.header}>
                <CircleIconButton name="chevron-back" onPress={() => router.back()} />
                <Text style={styles.headerTitle}>{isEdit ? 'Edit category' : 'Add category'}</Text>
                <View style={{ width: 40 }} />
            </View>

            {loading ? (
                <View style={styles.center}>
                    <ActivityIndicator color={colors.primary} />
                </View>
            ) : (
                <ScrollView
                    showsVerticalScrollIndicator={false}
                    keyboardShouldPersistTaps="handled"
                    contentContainerStyle={styles.scroll}
                >
                    <Card style={styles.card}>
                        <View style={styles.previewRow}>
                            <View style={[styles.previewCircle, { backgroundColor: (color || colors.primary) + '22' }]}>
                                {isCustomIcon ? (
                                    <Image source={{ uri: icon }} style={styles.previewImage} />
                                ) : (
                                    <WealthifyIcon name={resolved.name} size={40} />
                                )}
                            </View>
                            <View style={styles.previewText}>
                                <Text style={styles.previewTitle} numberOfLines={1}>
                                    {title.trim() || 'New category'}
                                </Text>
                                <Text style={styles.previewSub}>{type === 'income' ? 'Income' : 'Expense'}</Text>
                            </View>
                        </View>

                        <TextField
                            label="Name"
                            placeholder="e.g. Coffee"
                            value={title}
                            onChangeText={setTitle}
                            autoCapitalize="sentences"
                            style={styles.field}
                        />

                        <Text style={styles.fieldLabel}>Color</Text>
                        <View style={styles.swatchRow}>
                            {SWATCHES.map((hex) => {
                                const active = color === hex;
                                return (
                                    <Pressable
                                        key={hex}
                                        onPress={() => setColor(hex)}
                                        style={[
                                            styles.swatch,
                                            { backgroundColor: hex },
                                            active && styles.swatchActive,
                                        ]}
                                    >
                                        {active ? <Icon name="checkmark" size={16} color={colors.textInverse} /> : null}
                                    </Pressable>
                                );
                            })}
                        </View>

                        <Text style={[styles.fieldLabel, styles.fieldLabelTop]}>Icon</Text>
                        <PillButton
                            label={uploading ? 'Uploading...' : isCustomIcon ? 'Replace custom icon' : 'Upload custom icon'}
                            variant="secondary"
                            onPress={onUpload}
                            loading={uploading}
                            leftIcon={<Icon name="cloud-upload-outline" size={18} color={colors.text} />}
                        />
                        {isCustomIcon ? (
                            <Pressable onPress={() => setIcon(undefined)} style={styles.clearIcon}>
                                <Icon name="close-circle" size={16} color={colors.textSubtle} />
                                <Text style={styles.clearIconText}>Use default icon</Text>
                            </Pressable>
                        ) : null}
                    </Card>

                    <PillButton
                        label={isEdit ? 'Save changes' : 'Add category'}
                        onPress={onSave}
                        loading={saving}
                        size="lg"
                        style={{ marginTop: space.lg }}
                    />

                    {isEdit ? (
                        <PillButton
                            label="Delete category"
                            variant="secondary"
                            onPress={() => setConfirmVisible(true)}
                            leftIcon={<Icon name="trash-outline" size={18} color={colors.negative} />}
                            textStyle={{ color: colors.negative }}
                            style={{ marginTop: space.md }}
                        />
                    ) : null}

                    <View style={{ height: 60 }} />
                </ScrollView>
            )}

            <ConfirmationModal
                visible={confirmVisible}
                onClose={() => setConfirmVisible(false)}
                onConfirm={onDelete}
                message="Delete this category? Your past transactions are kept but it will be archived."
                confirmText="Delete"
                cancelText="Cancel"
            />
        </ScreenContainer>
    );
}

const makeStyles = (colors: ColorPalette) =>
    StyleSheet.create({
        header: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingHorizontal: space.xl,
            paddingTop: space.md,
            paddingBottom: space.md,
        },
        headerTitle: { ...Typography.screenTitle, color: colors.text },
        center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
        scroll: { paddingHorizontal: space.xl, paddingTop: space.sm, paddingBottom: space['3xl'] },
        card: { gap: space.sm },
        previewRow: { flexDirection: 'row', alignItems: 'center', marginBottom: space.md },
        previewCircle: {
            width: 64, height: 64, borderRadius: 32,
            alignItems: 'center', justifyContent: 'center', marginRight: space.md,
        },
        previewImage: { width: 44, height: 44, borderRadius: 12 },
        previewText: { flex: 1 },
        previewTitle: { ...Typography.subtitle, color: colors.text },
        previewSub: { ...Typography.bodySm, color: colors.textSubtle, marginTop: 2 },
        field: { marginBottom: 0 },
        fieldLabel: { ...Typography.label, color: colors.textSubtle, marginBottom: space.sm },
        fieldLabelTop: { marginTop: space.md },
        swatchRow: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm },
        swatch: {
            width: 36, height: 36, borderRadius: 18,
            alignItems: 'center', justifyContent: 'center',
            borderWidth: 2, borderColor: 'transparent',
        },
        swatchActive: {
            borderColor: colors.text,
        },
        clearIcon: {
            flexDirection: 'row',
            alignItems: 'center',
            alignSelf: 'center',
            gap: space.xs,
            marginTop: space.sm,
        },
        clearIconText: { ...Typography.bodySm, color: colors.textSubtle },
    });
