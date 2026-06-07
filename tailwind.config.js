/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        './app/**/*.{js,jsx,ts,tsx}',
        './src/**/*.{js,jsx,ts,tsx}',
    ],
    presets: [require('nativewind/preset')],
    theme: {
        extend: {
            colors: {
                wealthify: {
                    primary: '#7B3FF2',
                    background: '#F8F6FE',
                    text: '#130B3D',
                    subtle: '#68708F',
                    surface: '#FFFFFF',
                },
            },
            fontFamily: {
                poppins: ['Poppins_400Regular'],
                'poppins-medium': ['Poppins_500Medium'],
                'poppins-semibold': ['Poppins_600SemiBold'],
                'poppins-bold': ['Poppins_700Bold'],
            },
        },
    },
    plugins: [],
};
