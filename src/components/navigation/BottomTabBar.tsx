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
import {
  ChartNoAxesColumn,
  FileText,
  House,
  Plus,
  UserRound,
  X,
} from "lucide-react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useRouter } from "expo-router";
import type { BottomTabBarProps } from "@react-navigation/bottom-tabs";
import LottieView from "lottie-react-native";
import type { AnimationObject } from "lottie-react-native/lib/typescript/types";
import { Colors, Fonts, Typography, space } from "@/src/styles/theme";
import AddActionSheet from "@/src/components/ui/AddActionSheet";

const ICONS: Record<string, { label: string }> = {
  dashboard: { label: "Home" },
  transactions: { label: "Transactions" },
  analytics: { label: "Analytics" },
  account: { label: "Account" },
};

const BAR_HEIGHT = 85;
const FAB_SIZE = 60;
const FAB_RING_SIZE = 76;
const ICON_SIZE = 20;
const FAB_ICON_SIZE = 36;
const INACTIVE_COLOR = "#6F7083";
const HOME_INDICATOR_WIDTH = 116;
const FAB_SLOT_WIDTH = 64;
const ADD_TOUR_SEEN_KEY = "wealthify_add_menu_tour_seen_v2";

type TourStep = "fab" | "menu" | null;
type TourAccentPlacement = "first" | "second";

const TOUR_ACCENT_OFFSETS: Record<
  TourAccentPlacement,
  {
    attachToCoach?: boolean;
    bottom: number;
    left: number;
    width: number;
    height: number;
    resizeMode: "cover" | "contain" | "center";
  }
> = {
  first: {
    attachToCoach: true,
    bottom: 0,
    left: 0,
    width: 86,
    height: 126,
    resizeMode: "contain",
  },
  second: {
    bottom: 128,
    left: 12,
    width: 116,
    height: 116,
    resizeMode: "contain",
  },
};

const NavIcon = ({ name, focused }: { name: string; focused: boolean }) => {
  const color = focused ? Colors.primary : INACTIVE_COLOR;
  const strokeWidth = focused ? 2.7 : 2.35;
  const props = { size: ICON_SIZE, color, strokeWidth };

  if (name === "transactions") return <FileText {...props} />;
  if (name === "analytics") return <ChartNoAxesColumn {...props} />;
  if (name === "account") return <UserRound {...props} />;
  return <House {...props} />;
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
        <Text
          adjustsFontSizeToFit
          minimumFontScale={0.55}
          maxFontSizeMultiplier={1}
          numberOfLines={1}
          style={[styles.tabLabel, focused && styles.tabLabelActive]}
        >
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
          {sheetOpen ? (
            <X
              size={FAB_ICON_SIZE}
              color={Colors.textInverse}
              strokeWidth={2.8}
            />
          ) : (
            <Plus
              size={FAB_ICON_SIZE}
              color={Colors.textInverse}
              strokeWidth={2.8}
            />
          )}
        </LinearGradient>
      </TouchableOpacity>

      {showTour && tourStep === "fab" ? (
        <TourCoach
          title="Add your first entry"
          body="Tap + to record an expense, add income, or set a budget."
          bottom={fabBottom + FAB_SIZE + space.lg}
          width={width}
          progress={coachAnim}
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
  const attachAccentToCoach = !!accentOffsets.attachToCoach;

  return (
    <>
      {accentSource && !attachAccentToCoach ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.tourAccentWrap,
            {
              bottom: bottom + accentOffsets.bottom,
              left: coachLeft + accentOffsets.left,
              width: accentOffsets.width,
              height: accentOffsets.height,
              opacity: progress,
              transform: [{ translateY }, { scale }],
            },
          ]}
        >
          <LottieView
            source={accentSource}
            autoPlay
            loop={accentLoop}
            resizeMode={accentOffsets.resizeMode}
            style={[
              styles.tourAccentLottie,
              {
                width: accentOffsets.width,
                height: accentOffsets.height,
              },
            ]}
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
        {accentSource && attachAccentToCoach ? (
          <View pointerEvents="none" style={styles.tourCoachAccentWrap}>
            <LottieView
              source={accentSource}
              autoPlay
              loop={accentLoop}
              resizeMode={accentOffsets.resizeMode}
              style={[
                styles.tourCoachAccentLottie,
                {
                  width: accentOffsets.width,
                  height: accentOffsets.height,
                },
              ]}
            />
          </View>
        ) : null}
        <LinearGradient
          colors={["#FFFFFF", "#F8F4FF", "#FFFFFF"]}
          locations={[0, 0.55, 1]}
          start={{ x: 0.08, y: 0 }}
          end={{ x: 0.92, y: 1 }}
          style={[
            styles.tourGradient,
            attachAccentToCoach && styles.tourGradientWithAccent,
          ]}
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
    paddingHorizontal: 4,
  },
  tab: {
    flex: 1,
    alignItems: "center",
    justifyContent: "flex-start",
    height: "100%",
    minWidth: 0,
  },
  tabLabel: {
    ...Typography.body,
    fontFamily: Fonts.medium,
    fontSize: 11.5,
    lineHeight: 16,
    color: INACTIVE_COLOR,
    marginTop: 6,
    width: "100%",
    textAlign: "center",
    includeFontPadding: false,
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
  tourGradientWithAccent: {
    paddingTop: space["2xl"],
  },
  tourCoachAccentWrap: {
    position: "absolute",
    left: 28,
    top: -104,
    zIndex: 3,
    elevation: 3,
  },
  tourCoachAccentLottie: {
    backgroundColor: "transparent",
  },
  tourAccentWrap: {
    position: "absolute",
    zIndex: 40,
    elevation: 40,
    backgroundColor: "transparent",
    overflow: "visible",
  },
  tourAccentLottie: {
    position: "absolute",
    left: 0,
    top: 0,
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
