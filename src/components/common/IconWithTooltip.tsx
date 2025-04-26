import React from 'react';
import {IconButton, Tooltip} from 'react-native-paper';

interface IconWithTooltipProps {
    icon: string;
    tooltip: string;
    onPress?: () => void;
    size?: number;
    disabled?: boolean;
    color?: string;
}

const IconWithTooltip: React.FC<IconWithTooltipProps> = ({
                                                             icon,
                                                             tooltip,
                                                             onPress,
                                                             size = 24,
                                                             disabled = false,
                                                             color,
                                                         }) => {
    return (
        <Tooltip title={tooltip}>
            <IconButton
                icon={icon}
                onPress={() => {}}
                size={size}
                disabled={disabled}
                iconColor={color}
            />
        </Tooltip>
    );
};

export default IconWithTooltip;
