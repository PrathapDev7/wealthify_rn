import moment from "moment";
import React from "react";


export const handleNumberType = (event) =>{
    if(event.key === "Enter") {
        return true;
    } else {
        if (!/[0-9]/g.test(event.key) && event.key !== "Backspace") {
            event.preventDefault();
        }
    }
};

export const formatNumberWithCommas = (number) => {
    if (typeof number === 'undefined' || number === null) {
        return '0';
    }
    const numberString = number.toString();
    const [integerPart, decimalPart] = numberString.split('.');

    const formattedIntegerPart = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return decimalPart ? `${formattedIntegerPart}.${decimalPart}` : formattedIntegerPart;
};

export function objectToArrayOfObjects(obj) {
    return Object.entries(obj).map(([category, amount]) => ({ category, amount }));
}

export function arrayOfObjectsToObject(arr) {
    return arr.reduce((obj, item) => {
        obj[item.category] = item.amount;
        return obj;
    }, {});
}

export function deepClone(data) {
    return JSON.parse(JSON.stringify(data))
}

export const calculateBudgetPercentage = (total, spend) => {
    if (total === 0) {
        return 0; // To avoid division by zero
    }
    const percentage = (spend / total) * 100;
    if(percentage > 99) {
        return percentage.toFixed(2);
    }
    return Math.round(percentage); // Round the percentage to two decimal places
};

export const getLast7DaysData = (data) => {
    const today = moment().startOf('day');
    const last7Days = [...Array(7)].map((_, i) => today.clone().subtract(i, 'days').format('YYYY-MM-DD'));
    return last7Days.map((day) => {
        const obj = data.filter((item) => item.date === day );
        return !!obj?.length ? obj.reduce((a,b)=> a + b.amount,0) : 0;
        // return {
        //     amount: !!obj?.length ? obj.reduce((a,b)=> a + b.amount,0) : 0,
        //     week: moment(day).format('ddd')
        // };
    });
};

export function scrollToElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.scrollIntoView({ behavior: 'smooth' , block : "end", inline : "end"});
    }
};

export function validateEmail(email) {
    const regex = /\S+@\S+\.\S+/;
    return regex.test(email);
}

export function hasNumber(myString) {
    return /\d/.test(myString);
}

export function capitalize(string) {
    if(!!string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    } else {
        return string
    }
}

export const getEnvironment = () => {
    const userAgent = navigator.userAgent;

    if (/Android/i.test(userAgent)) {
        return "android";
    } else if (/iPhone|iPad|iPod/i.test(userAgent)) {
        return "ios";
    } else {
        return "web";
    }
};
