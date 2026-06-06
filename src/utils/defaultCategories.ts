// Default category suggestions shown in the chip strip and category picker
// when the BE returns no (or few) categories yet. Tapping one uses it as the
// category string on the saved transaction; it isn't auto-persisted to the
// Category collection.

export const DEFAULT_CATEGORIES: Record<'expense' | 'income', string[]> = {
    expense: [
        'Groceries',
        'Food',
        'Travel',
        'Transport',
        'Fuel',
        'Rent',
        'Home',
        'Shopping',
        'Bills',
        'Electricity',
        'Gas',
        'Internet',
        'Mobile',
        'Healthcare',
        'Insurance',
        'Education',
        'Entertainment',
        'Gym',
        'Subscription',
        'Gifts',
        'Other',
    ],
    income: [
        'Salary',
        'Bonus',
        'Freelance',
        'Business',
        'Commission',
        'Investment',
        'Rental Income',
        'Interest',
        'Refund',
        'Gift',
        'Other',
    ],
};
