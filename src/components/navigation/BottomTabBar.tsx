import React, { useEffect, useRef, useState } from "react";
import {
  Animated,
  Easing,
  StyleSheet,
  Text,
  TouchableOpacity,
  useWindowDimensions,
  View,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { LinearGradient } from "expo-linear-gradient";
import Svg, {
  Defs,
  G,
  Line,
  LinearGradient as SvgLinearGradient,
  Path,
  Stop,
} from "react-native-svg";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useRouter } from "expo-router";
import type { BottomTabBarProps } from "@react-navigation/bottom-tabs";
import LottieView from "lottie-react-native";
import type { AnimationObject } from "lottie-react-native/lib/typescript/types";
import { Colors, Fonts, Typography, space } from "@/src/styles/theme";
import AddActionSheet from "@/src/components/ui/AddActionSheet";

const quickStartAccent = require("../../../assets/lottie/quick-start-accent.json");
const chooseEntryAccent = require("../../../assets/lottie/second-tour-accent/animations/0cf9aa92-0b38-4505-9f72-12bddd1e9aa9.json");

const ICONS: Record<string, { label: string }> = {
  dashboard: { label: "Home" },
  transactions: { label: "Transaction" },
  analytics: { label: "Analytics" },
  account: { label: "Account" },
};

const BAR_HEIGHT = 85;
const FAB_SIZE = 60;
const FAB_RING_SIZE = 76;
const ICON_SIZE = 22;
const INACTIVE_COLOR = "#6F7083";
const HOME_INDICATOR_WIDTH = 116;
const FAB_SLOT_WIDTH = 84;
const ADD_TOUR_SEEN_KEY = "cashio_add_menu_tour_seen_v2";

type TourStep = "fab" | "menu" | null;
type TourAccentPlacement = "first" | "second";

const TOUR_ACCENT_OFFSETS: Record<
  TourAccentPlacement,
  { bottom: number; left: number }
> = {
  first: { bottom: 144, left: 4 },
  second: { bottom: 102, left: -16 },
};

const ActiveHomeIcon = () => (
  <Svg width={ICON_SIZE} height={ICON_SIZE} viewBox="0 0 34 34">
    <Defs>
      <SvgLinearGradient id="activeHome" x1="5" y1="2" x2="27" y2="31">
        <Stop offset="0" stopColor="#9B74FF" />
        <Stop offset="0.52" stopColor="#7B3FF2" />
        <Stop offset="1" stopColor="#5F35E8" />
      </SvgLinearGradient>
    </Defs>
    <Path
      d="M16.9 2.6c2 0 3.1.4 4.7 1.7l7 5.5c1.8 1.4 2.8 3.5 2.8 5.8v9.3c0 4-2.7 6.7-6.7 6.7H9.2c-4 0-6.7-2.7-6.7-6.7v-9.3c0-2.3 1-4.4 2.8-5.8l7-5.5c1.5-1.2 2.7-1.7 4.6-1.7z"
      fill="url(#activeHome)"
    />
    <Path
      d="M17 17.3c1.8 0 3.1 1 3.5 2.6.2.8.8 1.3 1.5 1.5.8.2 1.3.9 1.3 1.8 0 1.1-.8 1.9-1.9 1.9h-8.8c-1.1 0-1.9-.8-1.9-1.9 0-.9.5-1.6 1.3-1.8.7-.2 1.3-.7 1.5-1.5.4-1.6 1.7-2.6 3.5-2.6z"
      fill="#FFFFFF"
    />
  </Svg>
);

const NavIcon = ({ name, focused }: { name: string; focused: boolean }) => {
  if (focused && name === "dashboard") {
    return <ActiveHomeIcon />;
  }

  const stroke = focused ? Colors.primary : INACTIVE_COLOR;

  if (name === "transactions") {
    return (
      <Svg width={ICON_SIZE} height={ICON_SIZE} viewBox="0 0 28 28">
        <G
          fill="none"
          stroke={stroke}
          strokeWidth={2.2}
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <Path d="M7.5 4.5h8.2c2 0 3.3 1.3 3.3 3.3v9.4c0 2-1.3 3.3-3.3 3.3H7.5c-2 0-3.3-1.3-3.3-3.3V7.8c0-2 1.3-3.3 3.3-3.3z" />
          <Path d="M8.4 9.3h6.2" />
          <Path d="M8.4 13.4h4.1" />
          <Path d="M19.1 14.1a5.2 5.2 0 1 1 0 10.4 5.2 5.2 0 0 1 0-10.4z" />
          <Path d="M19.1 17v2.6l1.8 1.2" />
        </G>
      </Svg>
    );
  }

  if (name === "analytics") {
    return (
      <Svg width={ICON_SIZE} height={ICON_SIZE} viewBox="0 0 28 28">
        <G
          fill="none"
          stroke={stroke}
          strokeWidth={2.2}
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <Path d="M7.8 4.8h12.4c1.7 0 3 1.3 3 3v12.4c0 1.7-1.3 3-3 3H7.8c-1.7 0-3-1.3-3-3V7.8c0-1.7 1.3-3 3-3z" />
          <Path d="M10.2 17.8v-4" />
          <Path d="M14 17.8V9.9" />
          <Path d="M17.8 17.8v-6.2" />
        </G>
      </Svg>
    );
  }

  if (name === "account") {
    return (
      <Svg width={ICON_SIZE} height={ICON_SIZE} viewBox="0 0 28 28">
        <G
          fill="none"
          stroke={stroke}
          strokeWidth={2.2}
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <Path d="M14 12.7a4.2 4.2 0 1 0 0-8.4 4.2 4.2 0 0 0 0 8.4z" />
          <Path d="M6.6 23.2c.4-4 3.2-6.4 7.4-6.4s7 2.4 7.4 6.4c.1.7-.4 1.3-1.1 1.3H7.7c-.7 0-1.2-.6-1.1-1.3z" />
        </G>
      </Svg>
    );
  }

  return (
    <Svg width={ICON_SIZE} height={ICON_SIZE} viewBox="0 0 34 34">
      <G
        fill="none"
        stroke={stroke}
        strokeWidth={2.4}
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <Path d="M21 27v-8a1 1 0 0 0-1-1h-6a1 1 0 0 0-1 1v8" />
        <Path d="M5.5 14.7a2.8 2.8 0 0 1 1-2.1l8.7-7.5a2.8 2.8 0 0 1 3.6 0l8.7 7.5a2.8 2.8 0 0 1 1 2.1v9.8a2.8 2.8 0 0 1-2.8 2.8H8.3a2.8 2.8 0 0 1-2.8-2.8z" />
      </G>
    </Svg>
  );
};

const BottomTabBar: React.FC<BottomTabBarProps> = ({ state, navigation }) => {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { width, height } = useWindowDimensions();
  const [sheetOpen, setSheetOpen] = useState(false);
  const [tourStep, setTourStep] = useState<TourStep>(null);
  const coachAnim = useRef(new Animated.Value(0)).current;
  const pulseAnim = useRef(new Animated.Value(0)).current;
  const routes = state.routes;
  const activeRoute = routes[state.index]?.name;
  const showTour = activeRoute === "dashboard" && tourStep !== null;

  useEffect(() => {
    let mounted = true;

    let timer: ReturnType<typeof setTimeout> | undefined;

    AsyncStorage.getItem(ADD_TOUR_SEEN_KEY)
      .then((seen) => {
        if (mounted && !seen && activeRoute === "dashboard") {
          timer = setTimeout(() => {
            if (mounted) setTourStep("fab");
          }, 800);
        }
      })
      .catch(() => {});

    return () => {
      mounted = false;
      if (timer) clearTimeout(timer);
    };
  }, [activeRoute]);

  useEffect(() => {
    if (activeRoute !== "dashboard") {
      setTourStep(null);
    }
  }, [activeRoute]);

  useEffect(() => {
    coachAnim.stopAnimation();

    if (!showTour) {
      coachAnim.setValue(0);
      return;
    }

    coachAnim.setValue(0);
    Animated.timing(coachAnim, {
      toValue: 1,
      duration: 360,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [coachAnim, showTour, tourStep]);

  useEffect(() => {
    pulseAnim.stopAnimation();

    if (!(showTour && tourStep === "fab")) {
      pulseAnim.setValue(0);
      return;
    }

    const pulse = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 1150,
          easing: Easing.out(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 0,
          duration: 0,
          useNativeDriver: true,
        }),
      ]),
    );

    pulse.start();
    return () => pulse.stop();
  }, [pulseAnim, showTour, tourStep]);

  const completeTour = () => {
    setTourStep(null);
    AsyncStorage.setItem(ADD_TOUR_SEEN_KEY, "1").catch(() => {});
  };

  const openTourMenu = () => {
    setSheetOpen(true);
    setTourStep("menu");
  };

  const closeSheet = () => {
    setSheetOpen(false);
    if (tourStep === "menu") {
      setTourStep("fab");
    }
  };

  const handleFabPress = () => {
    if (tourStep === "fab") {
      openTourMenu();
      return;
    }
    if (tourStep === "menu") {
      closeSheet();
      return;
    }
    setSheetOpen((v) => !v);
  };

  const handleSelect = (key: string) => {
    setSheetOpen(false);
    if (tourStep) {
      completeTour();
    }
    setTimeout(() => {
      if (key === "expense") {
        router.push({
          pathname: "/add-transaction",
          params: { type: "expense" },
        });
      } else if (key === "income") {
        router.push({
          pathname: "/add-transaction",
          params: { type: "income" },
        });
      } else if (key === "budget") {
        router.push("/set-budget");
      }
    }, 200);
  };

  const renderTab = (routeName: string, index: number) => {
    const config = ICONS[routeName];
    if (!config) return null;
    const focused = state.index === index;
    const onPress = () => {
      const event = navigation.emit({
        type: "tabPress",
        target: routes[index].key,
        canPreventDefault: true,
      });
      if (!focused && !event.defaultPrevented) {
        navigation.navigate(routes[index].name);
      }
    };
    return (
      <TouchableOpacity
        key={routeName}
        onPress={onPress}
        activeOpacity={0.7}
        style={styles.tab}
      >
        <NavIcon name={routeName} focused={focused} />
        <Text style={[styles.tabLabel, focused && styles.tabLabelActive]}>
          {config.label}
        </Text>
      </TouchableOpacity>
    );
  };

  const safeBottom = Math.max(insets.bottom, 10);
  const barHeight = BAR_HEIGHT + safeBottom;
  const fabBottom = safeBottom + BAR_HEIGHT - FAB_SIZE + 24;
  const ringBottom = fabBottom - (FAB_RING_SIZE - FAB_SIZE) / 2;
  const sheetBottom = barHeight + FAB_RING_SIZE / 2 + space.md;
  const indicatorWidth = Math.min(HOME_INDICATOR_WIDTH, width * 0.32);

  return (
    <View style={styles.wrap} pointerEvents="box-none">
      {showTour ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.tourBackdrop,
            {
              top: -height,
              opacity: coachAnim.interpolate({
                inputRange: [0, 1],
                outputRange: [0, 1],
              }),
            },
          ]}
        />
      ) : null}

      <AddActionSheet
        visible={sheetOpen}
        onClose={closeSheet}
        onSelect={handleSelect}
        bottomOffset={sheetBottom}
      />

      {showTour && tourStep === "menu" ? (
        <TourCoach
          title="Choose what happened"
          body="Use Expense for spending. Use Income for money received."
          bottom={sheetBottom + 210}
          width={width}
          progress={coachAnim}
          accentSource={chooseEntryAccent}
          accentPlacement="second"
          accentLoop
          onSkip={completeTour}
        />
      ) : null}

      <View
        style={[styles.bar, { height: barHeight }]}
        pointerEvents="box-none"
      >
        <View style={styles.tabsRow}>
          {renderTab(routes[0].name, 0)}
          {renderTab(routes[1].name, 1)}
          <View style={styles.fabSlot} />
          {renderTab(routes[2].name, 2)}
          {renderTab(routes[3].name, 3)}
        </View>
        <View
          pointerEvents="none"
          style={[
            styles.homeIndicator,
            {
              bottom: Math.max(safeBottom - 5, 13),
              width: indicatorWidth,
              left: (width - indicatorWidth) / 2,
            },
          ]}
        />
      </View>

      <View
        pointerEvents="none"
        style={[
          styles.fabRing,
          {
            bottom: ringBottom,
            opacity: showTour && tourStep === "fab" ? 0 : 1,
          },
        ]}
      />
      {showTour && tourStep === "fab" ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.fabFocusRing,
            {
              bottom: ringBottom - 6,
              opacity: pulseAnim.interpolate({
                inputRange: [0, 0.55, 1],
                outputRange: [0.55, 0.2, 0],
              }),
              transform: [
                {
                  scale: pulseAnim.interpolate({
                    inputRange: [0, 1],
                    outputRange: [1, 1.55],
                  }),
                },
              ],
            },
          ]}
        />
      ) : null}
      {showTour && tourStep === "fab" ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.fabPulseCore,
            {
              bottom: ringBottom - 2,
              opacity: pulseAnim.interpolate({
                inputRange: [0, 0.5, 1],
                outputRange: [0.85, 0.35, 0.85],
              }),
              transform: [
                {
                  scale: pulseAnim.interpolate({
                    inputRange: [0, 0.5, 1],
                    outputRange: [1, 1.1, 1],
                  }),
                },
              ],
            },
          ]}
        />
      ) : null}
      <TouchableOpacity
        onPress={handleFabPress}
        activeOpacity={0.9}
        style={[styles.fab, { bottom: fabBottom }]}
      >
        <LinearGradient
          colors={["#7446FF", "#6335F2"]}
          start={{ x: 0.2, y: 0 }}
          end={{ x: 0.86, y: 1 }}
          style={styles.fabGradient}
        >
          <Svg width={36} height={36} viewBox="0 0 42 42">
            {sheetOpen ? (
              <G
                stroke={Colors.textInverse}
                strokeWidth={3.5}
                strokeLinecap="round"
              >
                <Line x1="13" y1="13" x2="29" y2="29" />
                <Line x1="29" y1="13" x2="13" y2="29" />
              </G>
            ) : (
              <G
                stroke={Colors.textInverse}
                strokeWidth={3.5}
                strokeLinecap="round"
              >
                <Line x1="21" y1="10" x2="21" y2="32" />
                <Line x1="10" y1="21" x2="32" y2="21" />
              </G>
            )}
          </Svg>
        </LinearGradient>
      </TouchableOpacity>

      {showTour && tourStep === "fab" ? (
        <TourCoach
          title="Add your first entry"
          body="Tap + to record an expense, add income, or set a budget."
          bottom={fabBottom + FAB_SIZE + space.lg}
          width={width}
          progress={coachAnim}
          accentSource={quickStartAccent}
          accentPlacement="first"
          onSkip={completeTour}
        />
      ) : null}
    </View>
  );
};

const TourCoach = ({
  title,
  body,
  bottom,
  width,
  progress,
  accentSource,
  accentPlacement,
  accentLoop = false,
  onSkip,
}: {
  title: string;
  body: string;
  bottom: number;
  width: number;
  progress: Animated.Value;
  accentSource?: string | AnimationObject | { uri: string };
  accentPlacement?: TourAccentPlacement;
  accentLoop?: boolean;
  onSkip: () => void;
}) => {
  const coachWidth = Math.min(width - space.xl * 2, 330);
  const coachLeft = (width - coachWidth) / 2;
  const translateY = progress.interpolate({
    inputRange: [0, 1],
    outputRange: [18, 0],
  });
  const scale = progress.interpolate({
    inputRange: [0, 1],
    outputRange: [0.96, 1],
  });
  const accentOffsets =
    TOUR_ACCENT_OFFSETS[accentPlacement || "first"] ||
    TOUR_ACCENT_OFFSETS.first;

  return (
    <>
      {accentSource ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.tourAccentWrap,
            {
              bottom: bottom + accentOffsets.bottom,
              left: coachLeft + accentOffsets.left,
              opacity: progress,
              transform: [{ translateY }, { scale }],
            },
          ]}
        >
          <LottieView
            source={accentSource}
            autoPlay
            loop={accentLoop}
            resizeMode="cover"
            style={styles.tourAccentLottie}
          />
        </Animated.View>
      ) : null}
      <Animated.View
        style={[
          styles.tourCoach,
          {
            bottom,
            width: coachWidth,
            left: coachLeft,
            opacity: progress,
            transform: [{ translateY }, { scale }],
          },
        ]}
      >
        <LinearGradient
          colors={["#FFFFFF", "#F8F4FF", "#FFFFFF"]}
          locations={[0, 0.55, 1]}
          start={{ x: 0.08, y: 0 }}
          end={{ x: 0.92, y: 1 }}
          style={styles.tourGradient}
        >
          <Text style={styles.tourTitle}>{title}</Text>
          <Text style={styles.tourBody}>{body}</Text>
          <View style={styles.tourActions}>
            <TouchableOpacity
              activeOpacity={0.8}
              onPress={onSkip}
              style={styles.tourSkipButton}
            >
              <Text style={styles.tourSkipText}>Skip tour</Text>
            </TouchableOpacity>
          </View>
        </LinearGradient>
        <View style={styles.tourArrow} />
      </Animated.View>
    </>
  );
};

const styles = StyleSheet.create({
  wrap: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: "transparent",
    overflow: "visible",
  },
  bar: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 1,
    overflow: "visible",
    backgroundColor: Colors.surface,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    shadowColor: "#1C1140",
    shadowOffset: { width: 0, height: -10 },
    shadowOpacity: 0.08,
    shadowRadius: 28,
    elevation: 16,
  },
  tabsRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    height: BAR_HEIGHT,
    paddingTop: 24,
    paddingHorizontal: 8,
  },
  tab: {
    flex: 1,
    alignItems: "center",
    justifyContent: "flex-start",
    height: "100%",
  },
  tabLabel: {
    ...Typography.body,
    fontFamily: Fonts.medium,
    fontSize: 12,
    lineHeight: 18,
    color: INACTIVE_COLOR,
    marginTop: 6,
    textAlign: "center",
  },
  tabLabelActive: {
    color: Colors.primary,
  },
  fabSlot: {
    width: FAB_SLOT_WIDTH,
  },
  fabRing: {
    position: "absolute",
    left: "50%",
    zIndex: 8,
    marginLeft: -FAB_RING_SIZE / 2,
    width: FAB_RING_SIZE,
    height: FAB_RING_SIZE,
    borderRadius: FAB_RING_SIZE / 2,
    backgroundColor: Colors.surface,
    shadowColor: "#1C1140",
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.08,
    shadowRadius: 24,
    elevation: 12,
  },
  fab: {
    position: "absolute",
    left: "50%",
    zIndex: 12,
    marginLeft: -FAB_SIZE / 2,
    width: FAB_SIZE,
    height: FAB_SIZE,
    borderRadius: FAB_SIZE / 2,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 14 },
    shadowOpacity: 0.24,
    shadowRadius: 26,
    elevation: 14,
  },
  fabFocusRing: {
    position: "absolute",
    left: "50%",
    zIndex: 10,
    marginLeft: -(FAB_RING_SIZE + 12) / 2,
    width: FAB_RING_SIZE + 12,
    height: FAB_RING_SIZE + 12,
    borderRadius: (FAB_RING_SIZE + 12) / 2,
    borderWidth: 2,
    borderColor: Colors.primaryGradientStart,
    backgroundColor: "rgba(123, 63, 242, 0.10)",
  },
  fabPulseCore: {
    position: "absolute",
    left: "50%",
    zIndex: 10,
    marginLeft: -(FAB_RING_SIZE + 4) / 2,
    width: FAB_RING_SIZE + 4,
    height: FAB_RING_SIZE + 4,
    borderRadius: (FAB_RING_SIZE + 4) / 2,
    borderWidth: 2,
    borderColor: Colors.primaryGradientStart,
  },
  fabGradient: {
    width: "100%",
    height: "100%",
    borderRadius: FAB_SIZE / 2,
    alignItems: "center",
    justifyContent: "center",
  },
  homeIndicator: {
    position: "absolute",
    height: 5,
    borderRadius: 999,
    backgroundColor: "#211D43",
  },
  tourBackdrop: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 4,
    backgroundColor: "rgba(19, 11, 61, 0.28)",
  },
  tourCoach: {
    position: "absolute",
    zIndex: 30,
    backgroundColor: Colors.surface,
    borderRadius: 22,
    overflow: "visible",
    borderWidth: 1,
    borderColor: Colors.primarySoftStrong,
    shadowColor: "#1C1140",
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.18,
    shadowRadius: 30,
    elevation: 18,
  },
  tourGradient: {
    borderRadius: 21,
    paddingHorizontal: space.xl,
    paddingTop: space.lg,
    paddingBottom: space.md,
  },
  tourAccentWrap: {
    position: "absolute",
    width: 122,
    height: 122,
    zIndex: 32,
    backgroundColor: "transparent",
  },
  tourAccentLottie: {
    width: 122,
    height: 122,
    backgroundColor: "transparent",
  },
  tourTitle: {
    ...Typography.title,
    fontFamily: Fonts.semibold,
    textAlign: "center",
  },
  tourBody: {
    ...Typography.body,
    color: Colors.textMuted,
    textAlign: "center",
    marginTop: space.sm,
  },
  tourActions: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    marginTop: space.sm,
  },
  tourSkipButton: {
    minHeight: 34,
    paddingHorizontal: space.lg,
    borderRadius: 999,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: "center",
    justifyContent: "center",
  },
  tourSkipText: {
    ...Typography.bodySm,
    fontFamily: Fonts.medium,
    color: Colors.textSubtle,
  },
  tourArrow: {
    position: "absolute",
    alignSelf: "center",
    bottom: -9,
    width: 18,
    height: 18,
    backgroundColor: "#FFFFFF",
    borderRightWidth: 1,
    borderBottomWidth: 1,
    borderColor: Colors.border,
    transform: [{ rotate: "45deg" }],
  },
});

export default BottomTabBar;
