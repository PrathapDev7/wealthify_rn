import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

// (e.g. http://localhost:5000/api/v1/). Falls back to the hosted backend.
const HOSTED_BASE_URL = 'https://expense-tracker-be-3rvm.onrender.com/api/v1/';
const ngrokURL = 'https://corset-unsigned-composed.ngrok-free.dev/api/v1/';
const baseURL = HOSTED_BASE_URL || ngrokURL || 'http://localhost:5000/api/v1/';
const getHeaders = async () => {
    const headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        Authorization: ''

    };

    const token = await AsyncStorage.getItem('wealthify_token');
    if (token) {
        headers.Authorization = `Bearer ${token}`;
    }

    return headers;
};

const request = async (method, path, body = null, query = null) => {
    const url = `${baseURL}${path}`;
    const headers = await getHeaders();

    const options = {
        method,
        url,
        headers,
        ...(body !== null && body !== undefined && { data: body }),
        ...(query && { params: query }),
    };

    try {
        return await axios(options);
    } catch (err) {
        console.log('API Error:', err?.response?.data || err.message);

        if (err.response?.status === 401) {
            await AsyncStorage.removeItem('wealthify_token');
            await AsyncStorage.removeItem('wealthify_user');

            // Optional: Navigate to login
            // You'll need to handle this using a global nav ref or Redux action
        }

        throw err; // rethrow so you can catch it in calling code if needed
    }
};

// Separate helper for multipart/form-data uploads: the JSON `request` helper
// hardcodes Content-Type, which would break the multipart boundary.
const uploadRequest = async (path, formData) => {
    const url = `${baseURL}${path}`;
    const headers = await getHeaders();
    delete headers['Content-Type']; // let axios set multipart boundary

    try {
        return await axios.post(url, formData, { headers });
    } catch (err) {
        console.log('Upload Error:', err?.response?.data || err.message);
        if (err.response?.status === 401) {
            await AsyncStorage.removeItem('wealthify_token');
            await AsyncStorage.removeItem('wealthify_user');
        }
        throw err;
    }
};

export default class APIService {

    check() {
        return request("GET", "")
    }
    login(data) {
        return request('POST', 'login', data);
    }
    register(data) {
        return request('POST', 'register', data);
    }

    getProfile() {
        return request('GET', 'get-profile');
    }

    updatePassword(data) {
        return request('POST', 'update-password', data);
    }

    updateProfile(data) {
        return request('POST', 'update-profile', data);
    }

    addIncome(data) {
        return request("POST", "add-income", data)
    }

    addExpense(data) {
        return request("POST", "add-expense", data)
    }

    updateExpense(id,data) {
        return request("PUT", `update-expense/${id}`, data)
    }

    deleteIncome(id) {
        return request("DELETE", `delete-income/${id}`)
    }

    getIncomes(query) {
        return request("GET", "get-incomes", null, query)
    }

    updateIncome(id,data) {
        return request("PUT", `update-income/${id}`, data)
    }

    getExpenses(query) {
        return request("GET", "get-expenses", null, query)
    }

    deleteExpense(id) {
        return request("DELETE", `delete-expense/${id}`)
    }

    getStats() {
        return request("GET", "get-stats")
    }

    addCategory(data) {
        return request("POST", "add-category", data)
    }

    getCategories(type) {
        return request("GET", `get-categories`, null, {type})
    }

    getRecentCategories(type) {
        return request("GET", `get-recent-categories`, null, {type})
    }

    addSubCategory(data) {
        return request("POST", "add-sub-category", data)
    }

    getSubCategories(category) {
        return request("GET", "get-sub-categories", null, {category})
    }

    addBudgets(data) {
        return request("POST", 'add-budgets', data)
    }
    updateBudgets(id, data) {
        return request("PUT", `update-budgets/${id}`, data)
    }
    getBudgets() {
        return request("GET", 'get-budgets')
    }

    // ---- categories (per-user CRUD) ----
    updateCategory(id, data) {
        return request("PUT", `update-category/${id}`, data)
    }
    deleteCategory(id) {
        return request("DELETE", `delete-category/${id}`)
    }

    // ---- image upload (S3) ----
    uploadImage(formData) {
        return uploadRequest("upload-image", formData)
    }

    // ---- recurring ----
    addRecurring(data) {
        return request("POST", "add-recurring", data)
    }
    getRecurring() {
        return request("GET", "get-recurring")
    }
    updateRecurring(id, data) {
        return request("PUT", `update-recurring/${id}`, data)
    }
    deleteRecurring(id) {
        return request("DELETE", `delete-recurring/${id}`)
    }

    // ---- goals ----
    addGoal(data) {
        return request("POST", "add-goal", data)
    }
    getGoals() {
        return request("GET", "get-goals")
    }
    updateGoal(id, data) {
        return request("PUT", `update-goal/${id}`, data)
    }
    contributeGoal(id, data) {
        return request("POST", `contribute-goal/${id}`, data)
    }
    deleteGoal(id) {
        return request("DELETE", `delete-goal/${id}`)
    }

    // ---- wallets ----
    addWallet(data) {
        return request("POST", "add-wallet", data)
    }
    getWallets() {
        return request("GET", "get-wallets")
    }
    updateWallet(id, data) {
        return request("PUT", `update-wallet/${id}`, data)
    }
    deleteWallet(id) {
        return request("DELETE", `delete-wallet/${id}`)
    }

    // ---- insights ----
    getInsights() {
        return request("GET", "get-insights")
    }
}
