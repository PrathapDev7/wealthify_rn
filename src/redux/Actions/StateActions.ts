import {
    RESET_STATE, UPDATE_STATE
} from "./ActionTypes";

export const updateState = (state) => {
    return async (dispatch) => {
        dispatch({type: UPDATE_STATE});
        dispatch({type: UPDATE_STATE, payload: state});
    };
};

export const resetState = () => ({
    type: RESET_STATE,
    payload: {}
});
