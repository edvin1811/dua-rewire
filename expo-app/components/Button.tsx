import React, { useState } from 'react';
import { Pressable, Text, View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import Animated, {
  useAnimatedStyle,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { Colors, Spacing, Radius, ShadowOffset } from '@/constants/theme';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

type ButtonVariant = 'primary' | 'secondary' | 'success' | 'warning' | 'danger' | 'accent';

interface DuoButtonProps {
  title: string;
  onPress: () => void;
  variant?: ButtonVariant;
  icon?: keyof typeof Ionicons.glyphMap;
  iconPosition?: 'left' | 'right';
  disabled?: boolean;
  fullWidth?: boolean;
}

const variantColors: Record<ButtonVariant, { bg: string; shadow: string; text: string }> = {
  primary: {
    bg: Colors.primary.DEFAULT,
    shadow: Colors.primary.dark,
    text: '#FFFFFF',
  },
  secondary: {
    bg: Colors.dark.card,
    shadow: Colors.dark.cardShadow,
    text: Colors.dark.textPrimary,
  },
  success: {
    bg: Colors.success.DEFAULT,
    shadow: Colors.success.dark,
    text: '#FFFFFF',
  },
  warning: {
    bg: Colors.warning.DEFAULT,
    shadow: Colors.warning.dark,
    text: '#FFFFFF',
  },
  danger: {
    bg: Colors.error.DEFAULT,
    shadow: Colors.error.dark,
    text: '#FFFFFF',
  },
  accent: {
    bg: Colors.accent.DEFAULT,
    shadow: Colors.accent.dark,
    text: '#3C3C3C',
  },
};

export function DuoButton({
  title,
  onPress,
  variant = 'success',
  icon,
  iconPosition = 'right',
  disabled = false,
  fullWidth = true,
}: DuoButtonProps) {
  const [isPressed, setIsPressed] = useState(false);
  const colors = variantColors[variant];

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { translateY: withSpring(isPressed ? ShadowOffset : 0, { damping: 15, stiffness: 300 }) },
        { scale: withSpring(isPressed ? 0.98 : 1, { damping: 15, stiffness: 300 }) },
      ],
    };
  }, [isPressed]);

  const shadowAnimatedStyle = useAnimatedStyle(() => {
    return {
      opacity: withTiming(isPressed ? 0 : 1, { duration: 100 }),
    };
  }, [isPressed]);

  const handlePressIn = () => {
    setIsPressed(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handlePressOut = () => {
    setIsPressed(false);
  };

  const handlePress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    onPress();
  };

  return (
    <View style={[styles.container, fullWidth && styles.fullWidth]}>
      {/* Shadow layer */}
      <Animated.View
        style={[
          styles.shadow,
          { backgroundColor: colors.shadow },
          shadowAnimatedStyle,
        ]}
      />

      {/* Main button */}
      <AnimatedPressable
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        onPress={handlePress}
        disabled={disabled}
        style={[
          styles.button,
          { backgroundColor: disabled ? Colors.dark.textTertiary : colors.bg },
          animatedStyle,
        ]}
      >
        {icon && iconPosition === 'left' && (
          <Ionicons
            name={icon}
            size={20}
            color={colors.text}
            style={styles.iconLeft}
          />
        )}
        <Text style={[styles.text, { color: colors.text }]}>
          {title}
        </Text>
        {icon && iconPosition === 'right' && (
          <Ionicons
            name={icon}
            size={20}
            color={colors.text}
            style={styles.iconRight}
          />
        )}
      </AnimatedPressable>
    </View>
  );
}

// Circular action button (like the quick add button)
interface CircleButtonProps {
  icon: keyof typeof Ionicons.glyphMap;
  onPress: () => void;
  size?: number;
  variant?: ButtonVariant;
}

export function CircleButton({
  icon,
  onPress,
  size = 56,
  variant = 'success',
}: CircleButtonProps) {
  const [isPressed, setIsPressed] = useState(false);
  const colors = variantColors[variant];

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { translateY: withSpring(isPressed ? ShadowOffset : 0, { damping: 15, stiffness: 300 }) },
        { scale: withSpring(isPressed ? 0.98 : 1, { damping: 15, stiffness: 300 }) },
      ],
    };
  }, [isPressed]);

  const handlePressIn = () => {
    setIsPressed(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handlePressOut = () => {
    setIsPressed(false);
  };

  const handlePress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    onPress();
  };

  return (
    <View style={{ width: size, height: size + ShadowOffset }}>
      {/* Shadow */}
      <View
        style={[
          styles.circleShadow,
          {
            width: size,
            height: size,
            borderRadius: size / 2,
            backgroundColor: colors.shadow,
            top: ShadowOffset,
          },
        ]}
      />

      {/* Main button */}
      <AnimatedPressable
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        onPress={handlePress}
        style={[
          styles.circleButton,
          {
            width: size,
            height: size,
            borderRadius: size / 2,
            backgroundColor: colors.bg,
          },
          animatedStyle,
        ]}
      >
        <Ionicons name={icon} size={size * 0.45} color={colors.text} />
      </AnimatedPressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'relative',
    minHeight: 50 + ShadowOffset,
  },
  fullWidth: {
    width: '100%',
  },
  shadow: {
    position: 'absolute',
    top: ShadowOffset,
    left: 0,
    right: 0,
    height: 50,
    borderRadius: Radius.md,
  },
  button: {
    height: 50,
    borderRadius: Radius.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.lg,
  },
  text: {
    fontSize: 17,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  iconLeft: {
    marginRight: Spacing.sm,
  },
  iconRight: {
    marginLeft: Spacing.sm,
  },
  circleShadow: {
    position: 'absolute',
  },
  circleButton: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
