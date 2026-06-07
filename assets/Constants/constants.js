import {remoteImage} from './remoteAssets';

export const MenuItems = [
    {
        path: `/dashboard`,
        label: 'Statistics',
        icon: 'chart-2',
    },
    {
        path: `/incomes`,
        exact: true,
        redirect: true,
        label: 'Incomes',
        icon: 'money'
    },
    {
        path: `/expenses`,
        exact: true,
        redirect: true,
        label: 'Expenses',
        icon: 'chart-down'
    },
    {
        path: `/analysis`,
        exact: true,
        redirect: true,
        label: 'Budget analysis',
        icon: 'board-2'
    },
    {
        path: `/profile`,
        exact: true,
        redirect: true,
        label: 'Profile',
        icon: 'user'
    },
];

export const DIMENSION = {
    Desktop: 'desktop',
    Tablet: 'tablet',
    Mobile: 'mobile',
};

export const MENU_PLACEMENT = {
    Vertical: 'vertical',
    Horizontal: 'horizontal',
};
export const MENU_BEHAVIOUR = {
    Pinned: 'pinned',
    Unpinned: 'unpinned',
};

export const images = {
    logo: remoteImage('assets/img/logo/wealthify-main.png'),
    logoDark: remoteImage('assets/img/logo/wealthify-black.png'),
    iconINR: remoteImage('assets/icons/inr.svg'),
    iconINRWhite: remoteImage('assets/icons/inrWhite.png')
};

export const settings = {
    dots: true,
    infinite: true,
    speed: 500,
    slidesToShow: 1,
    slidesToScroll: 1
};
