import React from 'react';
import { View, Text, StyleSheet, Image } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, Radius, Typography } from '@/constants/theme';

interface AppUsageBarProps {
  name: string;
  usage: string;
  percentage?: number;
  icon?: string; // URL or require
  iconColor?: string;
  barColor?: string;
}

export function AppUsageBar({
  name,
  usage,
  percentage = 0,
  icon,
  iconColor = Colors.primary.DEFAULT,
  barColor = Colors.success.DEFAULT,
}: AppUsageBarProps) {
  return (
    <View style={styles.container}>
      <View style={[styles.iconContainer, { backgroundColor: iconColor + '20' }]}>
        {icon ? (
          <Image source={{ uri: icon }} style={styles.iconImage} />
        ) : (
          <Ionicons name="apps" size={20} color={iconColor} />
        )}
      </View>

      <View style={styles.content}>
        <View style={styles.header}>
          <Text style={styles.name}>{name}</Text>
          <Text style={styles.usage}>{usage}</Text>
        </View>

        {percentage > 0 && (
          <View style={styles.barContainer}>
            <View
              style={[
                styles.bar,
                { width: `${Math.min(percentage, 100)}%`, backgroundColor: barColor },
              ]}
            />
          </View>
        )}
      </View>
    </View>
  );
}

// Category usage bar (like "Productivity", "Social", etc.)
interface CategoryUsageBarProps {
  category: string;
  usage: string;
  percentage: number;
  color: string;
  iconName: keyof typeof Ionicons.glyphMap;
}

export function CategoryUsageBar({
  category,
  usage,
  percentage,
  color,
  iconName,
}: CategoryUsageBarProps) {
  return (
    <View style={styles.categoryContainer}>
      <View style={[styles.categoryIcon, { backgroundColor: color + '20' }]}>
        <Ionicons name={iconName} size={24} color={color} />
      </View>

      <View style={styles.categoryContent}>
        <Text style={styles.categoryName}>{category}</Text>
        <View style={styles.categoryBarContainer}>
          <View
            style={[
              styles.categoryBar,
              { width: `${percentage}%`, backgroundColor: color },
            ]}
          />
        </View>
      </View>

      <Text style={styles.categoryUsage}>{usage}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: Radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  iconImage: {
    width: 24,
    height: 24,
    borderRadius: 6,
  },
  content: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.xs,
  },
  name: {
    fontSize: Typography.body.fontSize,
    fontWeight: '600',
    color: Colors.dark.textPrimary,
  },
  usage: {
    fontSize: Typography.subhead.fontSize,
    fontWeight: '600',
    color: Colors.dark.textPrimary,
  },
  barContainer: {
    height: 8,
    backgroundColor: Colors.dark.border,
    borderRadius: 4,
    overflow: 'hidden',
  },
  bar: {
    height: '100%',
    borderRadius: 4,
  },
  // Category styles
  categoryContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
  },
  categoryIcon: {
    width: 48,
    height: 48,
    borderRadius: Radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  categoryContent: {
    flex: 1,
  },
  categoryName: {
    fontSize: Typography.body.fontSize,
    fontWeight: '600',
    color: Colors.dark.textPrimary,
    marginBottom: Spacing.xs,
  },
  categoryBarContainer: {
    height: 8,
    backgroundColor: Colors.dark.border,
    borderRadius: 4,
    overflow: 'hidden',
  },
  categoryBar: {
    height: '100%',
    borderRadius: 4,
  },
  categoryUsage: {
    fontSize: Typography.subhead.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
    marginLeft: Spacing.md,
  },
});
