import { Colors } from '@/src/styles/theme';

interface IconSpec {
    name: string;
    color: string;
}

type CategoryType = 'expense' | 'income';

const NORMALIZE = (s: string) => (s || '').toLowerCase().trim();

const MAP: Record<string, IconSpec> = {
    groceries:    { name: 'category_groceries',  color: Colors.cat.groceries },
    grocery:      { name: 'category_groceries',  color: Colors.cat.groceries },
    food:         { name: 'category_food',       color: Colors.warning },
    dining:       { name: 'category_food',       color: Colors.warning },
    restaurant:   { name: 'category_food',       color: Colors.warning },
    restaurants:  { name: 'category_food',       color: Colors.warning },
    travel:       { name: 'category_travel',     color: Colors.cat.travel },
    transport:    { name: 'category_transport',  color: Colors.cat.car },
    transportation: { name: 'category_transport', color: Colors.cat.car },
    car:          { name: 'category_car',        color: Colors.cat.car },
    fuel:         { name: 'category_fuel',       color: Colors.warning },
    gas:          { name: 'category_gas',        color: Colors.warning },
    petrol:       { name: 'category_fuel',       color: Colors.warning },
    home:         { name: 'category_home',       color: Colors.cat.home },
    rent:         { name: 'category_rent',       color: Colors.cat.rent },
    bills:        { name: 'category_bills',      color: Colors.deepPurple },
    bill:         { name: 'category_bills',      color: Colors.deepPurple },
    utilities:    { name: 'category_bills',      color: Colors.deepPurple },
    electricity:  { name: 'category_electricity', color: Colors.warning },
    insurance:    { name: 'category_insurance',  color: Colors.cat.insurance },
    insurances:   { name: 'category_insurance',  color: Colors.cat.insurance },
    education:    { name: 'category_education',  color: Colors.cat.education },
    marketing:    { name: 'category_marketing',  color: Colors.cat.marketing },
    shopping:     { name: 'category_shopping',   color: Colors.cat.shopping },
    internet:     { name: 'category_internet',   color: Colors.cat.internet },
    mobile:       { name: 'category_mobile',     color: Colors.blue },
    phone:        { name: 'category_mobile',     color: Colors.blue },
    healthcare:   { name: 'category_healthcare', color: Colors.negative },
    health:       { name: 'category_healthcare', color: Colors.negative },
    medical:      { name: 'category_healthcare', color: Colors.negative },
    entertainment:{ name: 'category_entertainment', color: Colors.pink },
    water:        { name: 'category_water',      color: Colors.cat.water },
    gym:          { name: 'category_gym',        color: Colors.cat.gym },
    subscription: { name: 'category_subscription', color: Colors.cat.subscription },
    subscriptions:{ name: 'category_subscription', color: Colors.cat.subscription },
    gifts:        { name: 'category_gifts',      color: Colors.warning },
    gift:         { name: 'category_gifts',      color: Colors.warning },
    vacation:     { name: 'category_vacation',   color: Colors.cat.vacation },
    salary:       { name: 'type_income',         color: Colors.primary },
    bonus:        { name: 'income_bonus',        color: Colors.warning },
    freelance:    { name: 'income_freelance',    color: Colors.cyan },
    investment:   { name: 'income_investment',   color: Colors.accentDark },
    other:        { name: 'income_other',        color: Colors.cat.other },
};

const INCOME_MAP: Record<string, IconSpec> = {
    salary:       { name: 'type_income',         color: Colors.primary },
    bonus:        { name: 'income_bonus',        color: Colors.warning },
    freelance:    { name: 'income_freelance',    color: Colors.cyan },
    business:     { name: 'income_business',     color: Colors.primary },
    sales:        { name: 'income_business',     color: Colors.primary },
    commission:   { name: 'income_commission',   color: Colors.accentDark },
    tips:         { name: 'earn_rewards',        color: Colors.warning },
    investment:   { name: 'income_investment',   color: Colors.accentDark },
    'rental income': { name: 'income_rental',    color: Colors.cat.rent },
    rent:         { name: 'income_rental',       color: Colors.cat.rent },
    interest:     { name: 'income_interest',     color: Colors.accentDark },
    dividends:    { name: 'income_investment',   color: Colors.accentDark },
    refund:       { name: 'income_refund',       color: Colors.primary },
    reimbursement:{ name: 'income_refund',       color: Colors.primary },
    gift:         { name: 'income_gift',         color: Colors.warning },
    cashback:     { name: 'earn_rewards',        color: Colors.warning },
    other:        { name: 'income_other',        color: Colors.primary },
};

const DEFAULT: IconSpec = { name: 'category_other', color: Colors.primary };

export function resolveCategoryIcon(category?: string, type?: CategoryType): IconSpec {
    if (!category) return DEFAULT;
    const key = NORMALIZE(category);
    if (type === 'income') return INCOME_MAP[key] || MAP[key] || DEFAULT;
    return MAP[key] || DEFAULT;
}
