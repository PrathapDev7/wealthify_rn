type TransactionCollectionKey = 'incomes' | 'expenses';

export const readTransactionList = (
    res: any,
    collectionKey: TransactionCollectionKey,
) => {
    const payload = res?.data;
    const candidates = [
        payload,
        payload?.[collectionKey],
        payload?.data,
        payload?.data?.[collectionKey],
        payload?.response,
        payload?.response?.[collectionKey],
        payload?.response?.data,
        payload?.response?.data?.[collectionKey],
    ];

    return candidates.find(Array.isArray) || [];
};

export const getTransactionDate = (txn: {
    date?: string;
    createdAt?: string;
    updatedAt?: string;
}) => txn.date || txn.createdAt || txn.updatedAt;
