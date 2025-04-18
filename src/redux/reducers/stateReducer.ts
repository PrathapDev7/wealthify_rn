import {
    RESET_STATE, UPDATE_STATE
} from "../Actions/ActionTypes";

const initialState = {
    error: null,
    data : {},
    loading : false
};

const stateReducer = (state = initialState, action) => {
    switch (action.type) {
        case RESET_STATE:
            return {
                ...state,
                loading: true,
                error: null,
            };
        case UPDATE_STATE:
            return {
                ...state,
                loading: false,
                error: null,
                data: action.payload,
            };
        default:
            return state;
    }
};

export default stateReducer;