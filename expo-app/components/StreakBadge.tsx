import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, Radius, Typography } from '@/constants/theme';

interface StreakBadgeProps {
  count: number;
  variant?: 'default' | 'compact' | 'pill';
}

export function StreakBadge({ count, variant = 'default' }: StreakBadgeProps) {
  if (variant === 'pill') {
    return (
      <View style={styles.pill}>
        <Ionicons
          name="flame"
          size={16}
          color={Colors.warning.DEFAULT}
        />
        <Text style={styles.pillText}>{count}</Text>
      </View>
    );
  }

  if (variant === 'compact') {
    return (
      <View style={styles.compact}>
        <Ionicons
          name="flame"
          size={20}
          color={Colors.warning.DEFAULT}
        />
        <Text style={styles.compactCount}>{count}</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.iconContainer}>
        <Ionicons
          name="flame"
          size={24}
          color={Colors.warning.DEFAULT}
        />
      </View>
      <View style={styles.textContainer}>
        <Text style={styles.count}>{count}</Text>
        <Text style={styles.label}>DAY STREAK</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.dark.border,
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: Radius.md,
    backgroundColor: Colors.warning.DEFAULT + '20',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  textContainer: {
    alignItems: 'flex-start',
  },
  count: {
    fontSize: 24,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  label: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    letterSpacing: 0.5,
    marginTop: 2,
  },
  compact: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  compactCount: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.pill,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    gap: Spacing.xs,
    borderWidth: 1,
    borderColor: Colors.dark.border,
  },
  pillText: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
});
