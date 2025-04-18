import { combineReducers } from 'redux';
import userReducer from "./UserReducer";
import stateReducer from "./stateReducer";

const rootReducer = combineReducers({
    userData : userReducer,
    data : stateReducer
});

export default rootReducer;