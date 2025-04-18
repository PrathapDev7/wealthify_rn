import {
    FETCH_USER_REQUEST,
    FETCH_USER_SUCCESS,
    FETCH_USER_FAILURE, DELETE_USER_DATA
} from "../Actions/ActionTypes";

const initialState = {
    error: null,
    userData : {},
    loading : false
};

const userReducer = (state = initialState, action) => {
    switch (action.type) {
        case FETCH_USER_REQUEST:
            return {
                ...state,
                loading: true,
                error: null,
            };
        case FETCH_USER_SUCCESS:
            return {
                ...state,
                loading: false,
                error: null,
                userData: action.payload,
            };
        case FETCH_USER_FAILURE:
            return {
                ...state,
                loading: false,
                error: action.error,
            };
        case DELETE_USER_DATA:
            return {
                userData: action.payload,
                loading: false,
                error: null,
            };
        default:
            return state;
    }
};

export default userReducer;