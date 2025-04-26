import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Replace with your actual API base URL
// const baseURL = 'https://wealthify-be.onrender.com/api/v1/';
const baseURL = 'https://wealthify-be.onrender.com/api/v1/';

const getHeaders = async () => {
    const headers = {
        'Content-Type': 'application/json', Authorization: ''

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
        ...(body && { data: body }),
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
    verifyOTP(data) {
        return request('POST', 'verify-otp', data);
    }

    resendOTP(data) {
        return request('POST', 'resend-otp', data);
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
        return request("GET", "get-incomes", {}, query)
    }

    updateIncome(id,data) {
        return request("PUT", `update-income/${id}`, data)
    }

    getExpenses(query) {
        return request("GET", "get-expenses", {}, query)
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
        return request("GET", `get-categories`, {}, {type})
    }

    addSubCategory(data) {
        return request("POST", "add-sub-category", data)
    }

    getSubCategories(category) {
        return request("GET", `get-sub-categories`, {}, {category})
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
}
