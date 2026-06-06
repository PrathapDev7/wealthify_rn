import React from 'react';
import { Image, ImageStyle, StyleSheet } from 'react-native';
import Svg, { Circle, Ellipse, G, Path } from 'react-native-svg';
import { Colors } from '@/src/styles/theme';

export type CashioIconName =
    | 'auth_lock'
    | 'balance_top_up'
    | 'cashio_mark'
    | 'category_add'
    | 'category_bills'
    | 'category_car'
    | 'category_education'
    | 'category_electricity'
    | 'category_entertainment'
    | 'category_food'
    | 'category_fuel'
    | 'category_gas'
    | 'category_gifts'
    | 'category_groceries'
    | 'category_gym'
    | 'category_healthcare'
    | 'category_home'
    | 'category_insurance'
    | 'category_internet'
    | 'category_marketing'
    | 'category_mobile'
    | 'category_other'
    | 'category_rent'
    | 'category_shopping'
    | 'category_subscription'
    | 'category_transport'
    | 'category_travel'
    | 'category_vacation'
    | 'category_water'
    | 'earn_rewards'
    | 'earn_sharing'
    | 'nav_account'
    | 'nav_add'
    | 'nav_analytics'
    | 'nav_home'
    | 'nav_transaction'
    | 'premium_account'
    | 'spending_wallet'
    | 'subscriptions'
    | 'total_balance'
    | 'track_referrals'
    | 'income_bonus'
    | 'income_business'
    | 'income_commission'
    | 'income_freelance'
    | 'income_gift'
    | 'income_interest'
    | 'income_investment'
    | 'income_other'
    | 'income_refund'
    | 'income_rental'
    | 'type_expense'
    | 'type_income'
    | 'ui_bell'
    | 'ui_calendar'
    | 'ui_settings';

const glyphs: Record<CashioIconName, any> = {
    auth_lock: require('../../../assets/cashio/glyph_256/auth_lock.png'),
    balance_top_up: require('../../../assets/cashio/glyph_256/balance_top_up.png'),
    cashio_mark: require('../../../assets/cashio/glyph_256/cashio_mark.png'),
    category_add: require('../../../assets/cashio/glyph_256/category_add.png'),
    category_bills: require('../../../assets/cashio/glyph_256/category_bills.png'),
    category_car: require('../../../assets/cashio/glyph_256/category_car.png'),
    category_education: require('../../../assets/cashio/glyph_256/category_education.png'),
    category_electricity: require('../../../assets/cashio/glyph_256/category_electricity.png'),
    category_entertainment: require('../../../assets/cashio/glyph_256/category_entertainment.png'),
    category_food: require('../../../assets/cashio/glyph_256/category_food.png'),
    category_fuel: require('../../../assets/cashio/glyph_256/category_fuel.png'),
    category_gas: require('../../../assets/cashio/glyph_256/category_gas.png'),
    category_gifts: require('../../../assets/cashio/glyph_256/category_gifts.png'),
    category_groceries: require('../../../assets/cashio/glyph_256/category_groceries.png'),
    category_gym: require('../../../assets/cashio/glyph_256/category_gym.png'),
    category_healthcare: require('../../../assets/cashio/glyph_256/category_healthcare.png'),
    category_home: require('../../../assets/cashio/glyph_256/category_home.png'),
    category_insurance: require('../../../assets/cashio/glyph_256/category_insurance.png'),
    category_internet: require('../../../assets/cashio/glyph_256/category_internet.png'),
    category_marketing: require('../../../assets/cashio/glyph_256/category_marketing.png'),
    category_mobile: require('../../../assets/cashio/glyph_256/category_mobile.png'),
    category_other: require('../../../assets/cashio/glyph_256/category_other.png'),
    category_rent: require('../../../assets/cashio/glyph_256/category_rent.png'),
    category_shopping: require('../../../assets/cashio/glyph_256/category_shopping.png'),
    category_subscription: require('../../../assets/cashio/glyph_256/category_subscription.png'),
    category_transport: require('../../../assets/cashio/glyph_256/category_transport.png'),
    category_travel: require('../../../assets/cashio/glyph_256/category_travel.png'),
    category_vacation: require('../../../assets/cashio/glyph_256/category_vacation.png'),
    category_water: require('../../../assets/cashio/glyph_256/category_water.png'),
    earn_rewards: require('../../../assets/cashio/glyph_256/earn_rewards.png'),
    earn_sharing: require('../../../assets/cashio/glyph_256/earn_sharing.png'),
    nav_account: require('../../../assets/cashio/glyph_256/nav_account.png'),
    nav_add: require('../../../assets/cashio/glyph_256/nav_add.png'),
    nav_analytics: require('../../../assets/cashio/glyph_256/nav_analytics.png'),
    nav_home: require('../../../assets/cashio/glyph_256/nav_home.png'),
    nav_transaction: require('../../../assets/cashio/glyph_256/nav_transaction.png'),
    premium_account: require('../../../assets/cashio/glyph_256/premium_account.png'),
    spending_wallet: require('../../../assets/cashio/glyph_256/spending_wallet.png'),
    subscriptions: require('../../../assets/cashio/glyph_256/subscriptions.png'),
    total_balance: require('../../../assets/cashio/glyph_256/total_balance.png'),
    track_referrals: require('../../../assets/cashio/glyph_256/track_referrals.png'),
    income_bonus: require('../../../assets/cashio/glyph_256/income_bonus.png'),
    income_business: require('../../../assets/cashio/glyph_256/income_business.png'),
    income_commission: require('../../../assets/cashio/glyph_256/income_commission.png'),
    income_freelance: require('../../../assets/cashio/glyph_256/income_freelance.png'),
    income_gift: require('../../../assets/cashio/glyph_256/income_gift.png'),
    income_interest: require('../../../assets/cashio/glyph_256/income_interest.png'),
    income_investment: require('../../../assets/cashio/glyph_256/income_investment.png'),
    income_other: require('../../../assets/cashio/glyph_256/income_other.png'),
    income_refund: require('../../../assets/cashio/glyph_256/income_refund.png'),
    income_rental: require('../../../assets/cashio/glyph_256/income_rental.png'),
    type_expense: require('../../../assets/cashio/glyph_256/type_expense.png'),
    type_income: require('../../../assets/cashio/glyph_256/type_income.png'),
    ui_bell: require('../../../assets/cashio/glyph_256/ui_bell.png'),
    ui_calendar: require('../../../assets/cashio/glyph_256/ui_calendar.png'),
    ui_settings: require('../../../assets/cashio/glyph_256/ui_settings.png'),
};

const aliases: Record<string, CashioIconName> = {
    add: 'category_add',
    airplane: 'category_travel',
    apps: 'category_other',
    'barbell': 'category_gym',
    'bag-handle': 'category_groceries',
    book: 'category_education',
    calendar: 'ui_calendar',
    'calendar-outline': 'ui_calendar',
    car: 'category_car',
    'car-sport': 'category_car',
    cash: 'total_balance',
    'cashio-mark': 'cashio_mark',
    diamond: 'premium_account',
    gift: 'earn_rewards',
    home: 'category_home',
    key: 'category_rent',
    lock: 'auth_lock',
    'lock-closed': 'auth_lock',
    megaphone: 'category_marketing',
    notifications: 'category_subscription',
    'notifications-outline': 'ui_bell',
    person: 'nav_account',
    receipt: 'type_expense',
    'receipt-outline': 'type_expense',
    settings: 'ui_settings',
    'settings-outline': 'ui_settings',
    shield: 'category_insurance',
    sunny: 'category_vacation',
    wallet: 'spending_wallet',
    water: 'category_water',
    wifi: 'category_internet',
    'trending-up': 'type_income',
    'trending-down': 'type_expense',
};

export const resolveCashioIconName = (name?: string): CashioIconName | undefined => {
    if (!name) return undefined;
    if (name in glyphs) return name as CashioIconName;
    return aliases[name];
};

interface Props {
    name: string;
    size?: number;
    style?: ImageStyle | ImageStyle[];
}

const CashioIcon: React.FC<Props> = ({ name, size = 24, style }) => {
    const resolved = resolveCashioIconName(name);
    if (!resolved) return null;
    if (resolved === 'type_income') {
        return <IncomePiggyIcon size={size} style={style} />;
    }
    if (resolved === 'type_expense') {
        return <ExpenseReceiptIcon size={size} style={style} />;
    }
    return (
        <Image
            source={glyphs[resolved]}
            resizeMode="contain"
            style={[styles.icon, { width: size, height: size }, style]}
        />
    );
};

const ExpenseReceiptIcon: React.FC<{ size: number; style?: ImageStyle | ImageStyle[] }> = ({
    size,
    style,
}) => (
    <Svg
        width={size}
        height={size}
        viewBox="0 0 32 32"
        style={[styles.icon, style as any]}
    >
        <Path
            fill={Colors.negative}
            d="M23.65625,1H8.34375C6.4970703,1,5,2.4970093,5,4.34375V31l4.1571655-3.9344482L12.7000122,31L16,27.0655518 L19.2999878,31l3.5428467-3.9344482L27,31V4.34375C27,2.4970093,25.5029297,1,23.65625,1z"
        />
        <Path
            fill={Colors.negativeDark}
            opacity={0.32}
            d="M23.65625,1H8.34375C6.4970703,1,5,2.4970093,5,4.34375v2.6875C5,5.1845093,6.4970703,3.6875,8.34375,3.6875 h15.3125C25.5029297,3.6875,27,5.1845093,27,7.03125v-2.6875C27,2.4970093,25.5029297,1,23.65625,1z"
        />
        <Path
            fill={Colors.textInverse}
            d="M9.265625,7.0390625h11.1679688c0.5527344,0,1,0.4477539,1,1s-0.4472656,1-1,1H9.265625 c-0.5527344,0-1-0.4477539-1-1S8.7128906,7.0390625,9.265625,7.0390625z M9.265625,10.5546875h5.5839844 c0.5527344,0,1,0.4477539,1,1s-0.4472656,1-1,1H9.265625c-0.5527344,0-1-0.4477539-1-1 S8.7128906,10.5546875,9.265625,10.5546875z M22.734375,23.734375H9.265625c-0.5527344,0-1-0.4477539-1-1s0.4472656-1,1-1 h13.46875c0.5527344,0,1,0.4477539,1,1S23.2871094,23.734375,22.734375,23.734375z M22.734375,20.59375H9.265625 c-0.5527344,0-1-0.4477539-1-1s0.4472656-1,1-1h13.46875c0.5527344,0,1,0.4477539,1,1 S23.2871094,20.59375,22.734375,20.59375z M22.734375,17H9.265625c-0.5527344,0-1-0.4477539-1-1s0.4472656-1,1-1h13.46875 c0.5527344,0,1,0.4477539,1,1S23.2871094,17,22.734375,17z"
        />
    </Svg>
);

const IncomePiggyIcon: React.FC<{ size: number; style?: ImageStyle | ImageStyle[] }> = ({
    size,
    style,
}) => {
    const outline = Colors.deepPurple;
    const body = Colors.primary;
    const highlight = Colors.primarySoft;
    const income = Colors.accentDark;
    const shade = Colors.primaryDarker;

    return (
        <Svg
            width={size}
            height={size}
            viewBox="0 0 504.35 504.35"
            style={[styles.icon, style as any]}
        >
            <Ellipse
                opacity={0.28}
                fill={Colors.primarySoftStrong}
                cx="249.553"
                cy="424.928"
                rx="190.7"
                ry="47.3"
            />
            <Path
                fill={outline}
                d="M76.153,173.428c-2.3,0-4.6-0.7-6.6-2c-5.5-3.6-53.3-36.6-53.3-74c0-2.2,0.1-4.3,0.2-6.4 c-11.6-9.5-17.5-24.5-16.3-42.4c0.4-6.6,6.2-11.6,12.8-11.2c6.6,0.4,11.6,6.2,11.2,12.8c-0.3,4.5,0,8.5,1,11.9 c6-9.6,14.1-15.4,22-18.1c13.1-4.4,26.7-0.4,34.6,10.1c8.2,10.9,8.7,23.2,1.5,32.9c-8.3,11.1-25.9,16.6-42.7,14.2 c3.5,20,31.9,43.1,42.3,50.1c5.5,3.7,7,11.1,3.3,16.6C83.853,171.528,80.053,173.428,76.153,173.428z M44.053,77.628 c8.9,1.3,17.5-1.5,20-4.8c0.2-0.3,0.8-1.1-1.5-4.2c-2.4-3.1-6.3-2.3-7.8-1.7C50.953,68.128,46.853,71.528,44.053,77.628z"
            />
            <Path
                fill={body}
                d="M476.153,188.128h-21.6c-5.2-32.8-22.9-62.6-49.4-86.3l3.7-57.7l-48.9,27.4 c-31.8-15.7-69.4-24.8-109.7-24.8c-113.8,0-206,72.2-206,161.4c0,49.8,28.8,94.4,74.1,124l-8,20.8c-8.7,22.7,2.6,48.1,25.3,56.9 c22.7,8.7,48.1-2.6,56.9-25.3l7.6-19.8c16,3.1,32.8,4.8,50.1,4.8c16.5,0,32.5-1.6,47.9-4.4l7.4,19.4c8.7,22.7,34.2,34,56.9,25.3 c22.7-8.7,34-34.2,25.3-56.9l-7.5-19.6c22.1-14.1,40.4-31.8,53.5-51.8h42.5c8.8,0,16-7.2,16-16v-61.4 C492.153,195.328,485.053,188.128,476.153,188.128z"
            />
            <Path
                fill={highlight}
                d="M299.553,64.128c24,0,47.1,2.5,69.2,7.1c-33.3-17.1-73.4-27.1-116.6-27.1c-114.9,0-208,70.7-208,158 c0,5.5,0.4,11,1.1,16.4C71.453,130.128,175.353,64.128,299.553,64.128z"
            />
            <G opacity={0.22}>
                <Path
                    fill={shade}
                    d="M430.953,285.328c-54.8,22.8-98.8,30.8-176.8,26.8c-107.1-5.5-194.9-66.2-201.5-149.8 c-5.5,14.5-8.5,29.9-8.5,45.8c0,49.8,28.8,94.4,74.1,124l-8,20.8c-8.7,22.7,2.6,48.1,25.3,56.9c22.7,8.7,48.1-2.6,56.9-25.3 l7.6-19.8c16,3.1,32.8,4.8,50.1,4.8c16.5,0,32.5-1.6,47.9-4.4l7.4,19.4c8.7,22.7,34.2,34,56.9,25.3c22.7-8.7,34-34.2,25.3-56.9 l-7.5-19.6C400.853,320.128,418.053,303.728,430.953,285.328z"
                />
                <Path
                    fill={shade}
                    d="M428.153,276.128l48,5.3c8.8,0,16-7.2,16-16v-13.3h-52 C440.153,252.128,435.853,273.328,428.153,276.128z"
                />
            </G>
            <Path
                fill={highlight}
                d="M188.153,100.128c19-6.4,40-9.9,62-9.9c20.5,0,40,3.1,58,8.6"
            />
            <Path
                fill={outline}
                d="M188.153,112.128c-5,0-9.7-3.2-11.4-8.2c-2.1-6.3,1.3-13.1,7.5-15.2c20.7-7,42.9-10.5,65.8-10.5 c21,0,41.7,3.1,61.5,9.1c6.3,1.9,9.9,8.6,8,15c-1.9,6.3-8.6,9.9-15,8c-17.5-5.4-35.9-8.1-54.5-8.1c-20.3,0-39.9,3.1-58.2,9.3 C190.753,111.928,189.453,112.128,188.153,112.128z"
            />
            <Circle fill={outline} cx="382.153" cy="182.128" r="18" />
            <Path
                fill={income}
                d="M256.153,277.428c-24.3,0-38.9-13.9-40.5-15.5l17-17l-0.1-0.1c0.4,0.4,9.2,8.6,23.6,8.6 c10.5,0,16-4.1,16-12c0-6.9-6.2-10.4-23.6-16.8c-15.4-5.6-36.4-13.3-36.4-35.2c0-21.5,16.1-36,40-36c19.1,0,33.1,9,34.7,10 c5.5,3.7,7,11.1,3.3,16.6s-11.1,7-16.6,3.4c-0.3-0.2-9.6-6-21.4-6c-10.6,0-16,4-16,12c0,4.8,8.2,8.1,20.6,12.7 c16.6,6.1,39.4,14.4,39.4,39.3C296.153,259.328,283.753,277.428,256.153,277.428z"
            />
            <Path
                fill={income}
                d="M252.153,296.128c-2.2,0-4-1.8-4-4v-152c0-2.2,1.8-4,4-4s4,1.8,4,4v152 C256.153,294.328,254.353,296.128,252.153,296.128z"
            />
            <Path
                fill={outline}
                d="M246.153,372.128c-4.4,0-8-3.6-8-8s3.6-8,8-8c30.6,0,59.9-5.4,87.1-16.2c4.1-1.6,8.8,0.4,10.4,4.5 s-0.4,8.8-4.5,10.4C310.053,366.328,278.853,372.128,246.153,372.128z"
            />
            <Path
                fill={outline}
                d="M164.153,356.128c-0.9,0-1.8-0.1-2.7-0.5c-23.2-8.2-44.1-19.5-62.3-33.7c-3.5-2.7-4.1-7.8-1.4-11.2 c2.7-3.5,7.8-4.1,11.2-1.4c16.8,13.1,36.2,23.6,57.7,31.2c4.2,1.5,6.4,6,4.9,10.2C170.553,354.028,167.453,356.128,164.153,356.128 z"
            />
            <Path
                fill={outline}
                d="M346.653,424.728c-23.1,0-44.1-14.4-52.3-35.9l-3.9-10.3c-13.5,2-27,3-40.2,3 c-14.2,0-28.4-1.1-42.4-3.3l-4.1,10.6c-8.5,21.8-29,35.9-52.3,35.9c-6.9,0-13.6-1.3-20.1-3.7c-28.8-11.2-43.2-43.6-32.2-72.4 l4.6-12c-45.6-32.8-71.5-79.2-71.5-128.5c0-46.9,23.1-90.8,64.9-123.6c41-32.1,95.4-49.8,153.1-49.8c38.5,0,76.1,8,109.3,23.3 l43.5-24.4c3.8-2.1,8.5-2,12.3,0.3c3.7,2.3,5.9,6.5,5.6,10.9l-3.3,52c24,22.9,40.1,50,46.9,79.2h11.7c15.3,0,27.9,12.5,28.1,27.9 v0.1v61.4c0,15.4-12.6,28-28,28h-36.3c-11.9,16.6-27.3,31.8-45.2,44.4l4.1,10.7c11.1,28.9-3.4,61.3-32.2,72.4 C360.253,423.528,353.553,424.728,346.653,424.728z M298.153,353.128c4.9,0,9.4,3,11.2,7.7l7.4,19.4c4.7,12.3,16.7,20.5,29.9,20.5 c3.9,0,7.8-0.7,11.5-2.1c16.5-6.3,24.7-24.9,18.4-41.4l-7.5-19.6c-2-5.3-0.1-11.3,4.8-14.4c20.6-13.1,37.8-29.8,49.9-48.3 c2.2-3.4,6-5.4,10-5.4h42.5c2.2,0,4-1.8,4-4v-61.3c0-2.3-1.9-4.1-4.1-4.1h-21.6c-5.9,0-10.9-4.3-11.9-10.1 c-4.7-29.3-20.4-56.7-45.5-79.2c-2.7-2.5-4.2-6-4-9.7l2.3-35.7l-29.6,16.6c-3.5,1.9-7.6,2-11.2,0.3 c-31.2-15.4-67.3-23.6-104.4-23.6c-107,0-194,67-194,149.4c0,43.9,25,85.4,68.7,114c4.7,3.1,6.7,9.1,4.6,14.4l-8,20.8 c-6.3,16.4,2,35,18.4,41.4c3.7,1.4,7.5,2.1,11.4,2.1c13.3,0,25.1-8.1,29.9-20.6l7.6-19.8c2.1-5.4,7.8-8.6,13.5-7.5 c15.7,3,31.8,4.6,47.8,4.6c15,0,30.4-1.4,45.8-4.2C296.753,353.228,297.453,353.128,298.153,353.128z"
            />
        </Svg>
    );
};

const styles = StyleSheet.create({
    icon: {
        display: 'flex',
    },
});

export default CashioIcon;
