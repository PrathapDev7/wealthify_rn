import React, { useEffect, useRef, useState } from "react";
import { BlurView } from "expo-blur";
import { LinearGradient } from "expo-linear-gradient";
import {
  Animated,
  Easing,
  Pressable,
  StyleSheet,
  Text,
  TouchableOpacity,
  useWindowDimensions,
  View,
} from "react-native";
import Icon from "react-native-vector-icons/Ionicons";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Colors, Fonts, Shadows, radius, space } from "@/src/styles/theme";

interface Action {
  key: string;
  label: string;
  icon: string;
  color: string;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSelect: (key: string) => void;
  /** Distance (px) from the wrap bottom to the bottom edge of the pill stack. */
  bottomOffset?: number;
}

const ACTIONS: Action[] = [
  {
    key: "expense",
    label: "Add Expense",
    icon: "receipt",
    color: Colors.primary,
  },
  {
    key: "income",
    label: "Add Income",
    icon: "arrow-up",
    color: Colors.accentDark,
  },
  { key: "budget", label: "Set Budget", icon: "wallet", color: Colors.warning },
];

// Speed-dial pill stack rendered above the center FAB. Tap the backdrop or
// re-tap the FAB to dismiss.
const AddActionSheet: React.FC<Props> = ({
  visible,
  onClose,
  onSelect,
  bottomOffset,
}) => {
  const insets = useSafeAreaInsets();
  const { height } = useWindowDimensions();
  const [shouldRender, setShouldRender] = useState(visible);
  const progress = useRef(new Animated.Value(visible ? 1 : 0)).current;

  useEffect(() => {
    progress.stopAnimation();

    if (visible) {
      setShouldRender(true);
      Animated.timing(progress, {
        toValue: 1,
        duration: 300,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }).start();
      return;
    }

    Animated.timing(progress, {
      toValue: 0,
      duration: 220,
      easing: Easing.in(Easing.cubic),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (finished) setShouldRender(false);
    });
  }, [progress, visible]);

  if (!shouldRender) return null;

  // Fall back to a sensible default if no offset is passed.
  const stackBottom = bottomOffset ?? Math.max(insets.bottom, space.sm) + 160;
  const backdropOpacity = progress.interpolate({
    inputRange: [0, 1],
    outputRange: [0, 1],
  });
  const glowOpacity = progress.interpolate({
    inputRange: [0, 0.45, 1],
    outputRange: [0, 0.6, 1],
  });

  return (
    <>
      {/* Backdrop extends far beyond the tab-bar wrap so taps anywhere
                on screen dismiss the speed dial. RN doesn't clip overflow
                from absolute children, so the negative top is safe. */}
      <Animated.View
        style={[styles.backdrop, { top: -height, opacity: backdropOpacity }]}
      >
        <Pressable onPress={onClose} style={styles.backdropPressable}>
          <BlurView
            pointerEvents="none"
            tint="light"
            intensity={20}
            experimentalBlurMethod="dimezisBlurView"
            style={StyleSheet.absoluteFill}
          />
          <View pointerEvents="none" style={styles.backdropTint} />
        </Pressable>
      </Animated.View>
      <Animated.View
        pointerEvents="box-none"
        style={[
          styles.stackWrap,
          {
            bottom: stackBottom,
          },
        ]}
      >
        <Animated.View
          pointerEvents="none"
          style={[styles.menuGlow, { opacity: glowOpacity }]}
        >
          <LinearGradient
            colors={[
              "rgba(123, 63, 242, 0)",
              "rgba(123, 63, 242, 0.18)",
              "rgba(123, 63, 242, 0.14)",
              "rgba(123, 63, 242, 0)",
            ]}
            locations={[0, 0.34, 0.66, 1]}
            start={{ x: 0.5, y: 0 }}
            end={{ x: 0.5, y: 1 }}
            style={StyleSheet.absoluteFill}
          />
        </Animated.View>
        {ACTIONS.map((a, index) => {
          const stackIndex = ACTIONS.length - 1 - index;
          const start = stackIndex * 0.12;
          const end = start + 0.52;
          const inputRange = start === 0 ? [0, end, 1] : [0, start, end, 1];
          const opacity = progress.interpolate({
            inputRange,
            outputRange: start === 0 ? [0, 1, 1] : [0, 0, 1, 1],
          });
          const translateY = progress.interpolate({
            inputRange,
            outputRange: start === 0 ? [54, 0, 0] : [54, 54, 0, 0],
          });
          const scale = progress.interpolate({
            inputRange,
            outputRange: start === 0 ? [0.86, 1, 1] : [0.86, 0.86, 1, 1],
          });

          return (
            <Animated.View
              key={a.key}
              style={[
                styles.pillAnimator,
                {
                  opacity,
                  transform: [{ translateY }, { scale }],
                },
              ]}
            >
              <TouchableOpacity
                activeOpacity={0.9}
                onPress={() => onSelect(a.key)}
                style={styles.pill}
              >
                <View style={[styles.iconCircle, { backgroundColor: a.color }]}>
                  <Icon name={a.icon} size={20} color={Colors.textInverse} />
                </View>
                <Text style={styles.pillLabel}>{a.label}</Text>
              </TouchableOpacity>
            </Animated.View>
          );
        })}
      </Animated.View>
    </>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 5,
    overflow: "hidden",
  },
  backdropPressable: {
    ...StyleSheet.absoluteFillObject,
  },
  backdropTint: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(123, 63, 242, 0.10)",
  },
  stackWrap: {
    position: "absolute",
    left: 0,
    right: 0,
    zIndex: 18,
    alignItems: "center",
    gap: space.lg,
    overflow: "visible",
  },
  menuGlow: {
    position: "absolute",
    top: -145,
    left: 0,
    right: 0,
    height: 430,
    zIndex: 0,
  },
  pillAnimator: {
    zIndex: 1,
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: Colors.surface,
    paddingVertical: 8,
    paddingLeft: 8,
    paddingRight: 22,
    borderRadius: radius.pill,
    width: 205,
    zIndex: 1,
    ...Shadows.primaryGlowSoft,
  },
  iconCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
    marginRight: space.lg,
  },
  pillLabel: {
    flex: 1,
    fontFamily: Fonts.medium,
    fontSize: 14,
    color: Colors.text,
    letterSpacing: 0,
    textAlign: "left",
  },
});

export default AddActionSheet;
