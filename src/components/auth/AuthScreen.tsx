import React, { useState } from 'react';
import {
    Image,
    ImageBackground,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
    ActivityIndicator,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useDispatch } from 'react-redux';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Toast from 'react-native-toast-message';
import FlipWrapper from '../animations/FlipWrapper';
import APIService from '../ApiService/api.service';
import { getUserData } from '../redux/Actions/UserActions';
import { images } from '../../assets/Constants/constants';

const api = new APIService();

const AuthScreen = ({ navigation }) => {
    const dispatch = useDispatch();

    const [showRegisterForm, setShowRegisterForm] = useState(false);
    const [flipping, setFlipping] = useState(false);
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);

    const [loginData, setLoginData] = useState({ email: '', password: '' });
    const [registerData, setRegisterData] = useState({
        username: '',
        email: '',
        password: '',
        confirm_password: '',
    });

    const handleChange = (key, value) => {
        if (showRegisterForm) {
            setRegisterData({ ...registerData, [key]: value });
        } else {
            setLoginData({ ...loginData, [key]: value });
        }
    };

    const handleSubmit = async () => {
        const data = showRegisterForm ? registerData : loginData;

        if (showRegisterForm) {
            if (!data.username || !data.email || !data.password || !data.confirm_password) {
                return Toast.show({ type: 'error', text1: 'All fields are required' });
            }
            if (data.password !== data.confirm_password) {
                return Toast.show({ type: 'error', text1: 'Passwords do not match' });
            }
        } else {
            if (!data.email || !data.password) {
                return Toast.show({ type: 'error', text1: 'Enter email and password' });
            }
        }

        setLoading(true);
        try {
            const res = showRegisterForm ? await api.register(data) : await api.login(data);
            if (res.data) {
                console.log(res.data);
                await AsyncStorage.setItem('wealthify_token', res.data.token);
                await AsyncStorage.setItem('wealthify_user', JSON.stringify(res.data.data));
                dispatch(getUserData(res.data.user));
                Toast.show({ type: 'success', text1: showRegisterForm ? 'Registered!' : 'Logged in!' });
                navigation.navigate('DrawerStack');
            }
        } catch (err) {
            console.log(err.response);
            Toast.show({
                type: 'error',
                text1: err.response?.data?.message || 'Something went wrong',
            });
        } finally {
            setLoading(false);
        }
    };

    const handleFlip = () => {
        setFlipping(true);
        setTimeout(() => {
            setShowRegisterForm(!showRegisterForm);
            setFlipping(false);
        }, 300); // Match flip duration
    };

    const image = { uri: 'https://www.shutterstock.com/image-vector/application-smartphone-business-graph-analytics-600nw-1583248045.jpg' };

    return (
        <ImageBackground source={image} style={styles.background} blurRadius={3}>
            <View style={styles.flipContainer}>
                {!showRegisterForm && (
                    <FlipWrapper direction={flipping ? "out" : "in"} duration={400}>
                        <AuthForm
                            type="login"
                            data={loginData}
                            handleChange={handleChange}
                            handleSubmit={handleSubmit}
                            loading={loading}
                            showPassword={showPassword}
                            setShowPassword={setShowPassword}
                            onToggleForm={handleFlip}
                        />
                    </FlipWrapper>
                )}

                {showRegisterForm  && (
                    <FlipWrapper direction={flipping ? "out" : "in"} duration={400}>
                        <AuthForm
                            type="register"
                            data={registerData}
                            handleChange={handleChange}
                            handleSubmit={handleSubmit}
                            loading={loading}
                            showPassword={showPassword}
                            showConfirmPassword={showConfirmPassword}
                            setShowPassword={setShowPassword}
                            setShowConfirmPassword={setShowConfirmPassword}
                            onToggleForm={handleFlip}
                        />
                    </FlipWrapper>
                )}


            </View>
        </ImageBackground>
    );
};

const AuthForm = ({
                      type,
                      data,
                      handleChange,
                      handleSubmit,
                      loading,
                      showPassword,
                      setShowPassword,
                      showConfirmPassword,
                      setShowConfirmPassword,
                      onToggleForm,
                  }) => {
    const isRegister = type === 'register';
    return (
        <View style={styles.formWrapper}>
            <View style={styles.logoContainer}>
                <Image source={images.logoDark} style={styles.logo} />
            </View>
            <Text style={styles.titleText}>
                {isRegister
                    ? 'Create your account'
                    : 'Monitor your spending, set goals, and gain insights.\nLogin to get started.'}
            </Text>

            {isRegister && (
                <Input
                    icon="person-outline"
                    placeholder="Full name"
                    value={data.username}
                    onChangeText={(text) => handleChange('username', text)}
                />
            )}

            <Input
                icon="mail-outline"
                placeholder="Email address"
                value={data.email}
                onChangeText={(text) => handleChange('email', text)}
            />

            <Input
                icon="lock-closed-outline"
                placeholder="Password"
                value={data.password}
                onChangeText={(text) => handleChange('password', text)}
                secureTextEntry={!showPassword}
                toggleSecure={() => setShowPassword && setShowPassword((prev) => !prev)}
                showToggle
                showValue={showPassword}
            />

            {isRegister && (
                <Input
                    icon="lock-closed-outline"
                    placeholder="Confirm password"
                    value={data.confirm_password}
                    onChangeText={(text) => handleChange('confirm_password', text)}
                    secureTextEntry={!showConfirmPassword}
                    toggleSecure={() => setShowConfirmPassword && setShowConfirmPassword((prev) => !prev)}
                    showToggle
                    showValue={showConfirmPassword}
                />
            )}

            <TouchableOpacity style={styles.button} onPress={handleSubmit} disabled={loading}>
                {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>{isRegister ? 'Register' : 'Login'}</Text>}
            </TouchableOpacity>

            <View style={styles.footerTextContainer}>
                <Text style={styles.footerText}>
                    {isRegister ? 'Already have an account?' : "Don't have an account?"}
                </Text>
                <TouchableOpacity onPress={onToggleForm}>
                    <Text style={styles.loginText}>{isRegister ? ' Login' : ' Register'}</Text>
                </TouchableOpacity>
            </View>
        </View>
    );
};

const Input = ({
                   icon,
                   placeholder,
                   value,
                   onChangeText,
                   secureTextEntry,
                   toggleSecure,
                   showToggle,
                   showValue,
               }) => (
    <View style={styles.inputBox}>
        <Icon name={icon} size={20} color="#888" style={styles.icon} />
        <TextInput
            placeholder={placeholder}
            style={styles.input}
            placeholderTextColor="#999"
            value={value}
            onChangeText={onChangeText}
            secureTextEntry={secureTextEntry}
        />
        {showToggle && toggleSecure && (
            <TouchableOpacity onPress={toggleSecure}>
                <Icon name={showValue ? 'eye' : 'eye-off'} size={20} color="#e85c5c" />
            </TouchableOpacity>
        )}
    </View>
);

const styles = StyleSheet.create({
    background: {
        flex: 1,
        justifyContent: 'center',
        padding: 20,
    },
    flipContainer: {
        flex: 1,
        justifyContent: 'center',
    },
    formWrapper: {
        backgroundColor: 'rgba(255,255,255,0.2)',
        borderRadius: 16,
        padding: 24,
        shadowColor: '#000',
        shadowOpacity: 0.2,
        shadowOffset: { width: 0, height: 2 },
        shadowRadius: 10,
    },
    logoContainer: {
        alignItems: 'center',
        marginBottom: 12,
    },
    logo: {
        width: 175,
        height: 34,
    },
    titleText: {
        textAlign: 'center',
        marginBottom: 20,
        fontSize: 14,
        color: '#eee',
        lineHeight: 20,
    },
    inputBox: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#fff',
        borderRadius: 8,
        paddingHorizontal: 12,
        marginBottom: 12,
    },
    input: {
        flex: 1,
        paddingVertical: 10,
        color: '#333',
    },
    icon: {
        marginRight: 8,
    },
    button: {
        backgroundColor: '#f35d5d',
        paddingVertical: 12,
        borderRadius: 8,
        marginTop: 10,
    },
    buttonText: {
        color: '#fff',
        textAlign: 'center',
        fontWeight: '600',
    },
    footerTextContainer: {
        flexDirection: 'row',
        justifyContent: 'center',
        marginTop: 16,
        flexWrap: 'wrap',
    },
    footerText: {
        color: '#eee',
    },
    loginText: {
        color: '#fff',
        fontWeight: 'bold',
    },
});

export default AuthScreen;
