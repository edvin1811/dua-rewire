import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { Colors, Spacing, Radius, ShadowOffset } from '@/constants/theme';

interface CardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  padding?: number;
  borderRadius?: number;
  withBorder?: boolean;
  withShadow?: boolean;
}

// Flat card with border (for non-interactive content)
export function Card({
  children,
  style,
  padding = Spacing.md,
  borderRadius = Radius.lg,
  withBorder = true,
  withShadow = false,
}: CardProps) {
  return (
    <View style={[styles.container, withShadow && { paddingBottom: ShadowOffset }]}>
      {withShadow && (
        <View
          style={[
            styles.shadow,
            {
              borderRadius,
              top: ShadowOffset,
            },
          ]}
        />
      )}
      <View
        style={[
          styles.card,
          {
            padding,
            borderRadius,
            borderWidth: withBorder ? 2 : 0,
          },
          style,
        ]}
      >
        {children}
      </View>
    </View>
  );
}

// Interactive card with 3D shadow effect
interface InteractiveCardProps extends CardProps {
  isPressed?: boolean;
}

export function InteractiveCard({
  children,
  style,
  padding = Spacing.md,
  borderRadius = Radius.lg,
  isPressed = false,
}: InteractiveCardProps) {
  return (
    <View style={[styles.container, { paddingBottom: ShadowOffset }]}>
      {/* Shadow layer */}
      <View
        style={[
          styles.shadow,
          {
            borderRadius,
            top: ShadowOffset,
            opacity: isPressed ? 0 : 1,
          },
        ]}
      />
      {/* Main card */}
      <View
        style={[
          styles.card,
          {
            padding,
            borderRadius,
            borderWidth: 0,
            transform: [{ translateY: isPressed ? ShadowOffset : 0 }],
          },
          style,
        ]}
      >
        {children}
      </View>
    </View>
  );
}

// Stats card with icon (Duolingo-style)
interface StatsCardProps {
  icon: React.ReactNode;
  value: string;
  label: string;
  iconColor?: string;
  style?: ViewStyle;
}

export function StatsCard({
  icon,
  value,
  label,
  iconColor = Colors.primary.DEFAULT,
  style,
}: StatsCardProps) {
  return (
    <Card style={[styles.statsCard, style]} withBorder>
      <View style={[styles.iconContainer, { backgroundColor: iconColor + '20' }]}>
        {icon}
      </View>
      <View style={styles.statsContent}>
        <View style={styles.statsTextContainer}>
          <View style={styles.statsValueLabel}>
            <View style={styles.statsLabelOnly}>
              <View style={styles.statsTextWrapper}>
                <View style={styles.statsValueContainer}>
                  <View style={styles.valueText}>
                    {/* Value will be rendered by parent */}
                  </View>
                </View>
              </View>
            </View>
          </View>
        </View>
      </View>
    </Card>
  );
}

// Progress card with ring
interface ProgressCardProps {
  progress: number; // 0-100
  label: string;
  children?: React.ReactNode;
}

export function ProgressCard({
  progress,
  label,
  children,
}: ProgressCardProps) {
  return (
    <Card padding={Spacing.lg} withBorder>
      {children}
    </Card>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'relative',
  },
  shadow: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: '100%',
    backgroundColor: Colors.dark.cardShadow,
  },
  card: {
    backgroundColor: Colors.dark.card,
    borderColor: Colors.dark.border,
  },
  statsCard: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: Radius.sm,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  statsContent: {
    flex: 1,
  },
  statsTextContainer: {
    flex: 1,
  },
  statsValueLabel: {
    flex: 1,
  },
  statsLabelOnly: {
    flex: 1,
  },
  statsTextWrapper: {
    flex: 1,
  },
  statsValueContainer: {
    flex: 1,
  },
  valueText: {
    flex: 1,
  },
});
