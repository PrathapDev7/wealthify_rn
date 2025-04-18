import {
    DELETE_USER_DATA,
    FETCH_USER_REQUEST,
    FETCH_USER_SUCCESS,
    FETCH_USER_FAILURE
} from "./ActionTypes";
import API from "../../ApiService/api.service";

const api = new API();

export const getUserData = (data) => {
    return async (dispatch) => {
        dispatch({type: FETCH_USER_REQUEST});
        try {
            let response = {};
            /*await api.getProfileInfo().then((res)=>{
                response = res
            });*/
            dispatch({type: FETCH_USER_SUCCESS, payload: data});
        } catch (error) {
            dispatch({type: FETCH_USER_FAILURE, error: error.message});
        }
    };
};

export const removeUserData = () => ({
    type: DELETE_USER_DATA,
    payload: {}
});
