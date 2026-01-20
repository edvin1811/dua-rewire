import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { Colors, Spacing, Radius, Typography } from '@/constants/theme';

interface TaskItemProps {
  title: string;
  subtitle?: string;
  isCompleted: boolean;
  onToggle: () => void;
  priority?: 'high' | 'medium' | 'low';
  time?: string;
}

export function TaskItem({
  title,
  subtitle,
  isCompleted,
  onToggle,
  priority,
  time,
}: TaskItemProps) {
  const handlePress = () => {
    Haptics.notificationAsync(
      isCompleted
        ? Haptics.NotificationFeedbackType.Warning
        : Haptics.NotificationFeedbackType.Success
    );
    onToggle();
  };

  const getPriorityColor = () => {
    switch (priority) {
      case 'high':
        return Colors.error.DEFAULT;
      case 'medium':
        return Colors.warning.DEFAULT;
      case 'low':
        return Colors.success.DEFAULT;
      default:
        return undefined;
    }
  };

  return (
    <View style={styles.container}>
      <Pressable
        onPress={handlePress}
        style={styles.checkbox}
      >
        {isCompleted ? (
          <View style={styles.checkboxChecked}>
            <Ionicons name="checkmark" size={16} color="#FFFFFF" />
          </View>
        ) : (
          <View style={styles.checkboxUnchecked} />
        )}
      </Pressable>

      <View style={styles.content}>
        <Text
          style={[
            styles.title,
            isCompleted && styles.titleCompleted,
          ]}
        >
          {title}
        </Text>
        {subtitle && (
          <Text
            style={[
              styles.subtitle,
              isCompleted && styles.subtitleCompleted,
            ]}
          >
            {subtitle}
          </Text>
        )}
        {priority && !isCompleted && (
          <Text style={[styles.priority, { color: getPriorityColor() }]}>
            {priority.toUpperCase()} PRIORITY
          </Text>
        )}
      </View>

      {time && (
        <Text style={styles.time}>{time}</Text>
      )}
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
  checkbox: {
    marginRight: Spacing.md,
  },
  checkboxUnchecked: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: Colors.dark.textTertiary,
    backgroundColor: 'transparent',
  },
  checkboxChecked: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: Colors.success.DEFAULT,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    flex: 1,
  },
  title: {
    fontSize: Typography.body.fontSize,
    fontWeight: '600',
    color: Colors.dark.textPrimary,
  },
  titleCompleted: {
    textDecorationLine: 'line-through',
    color: Colors.dark.textSecondary,
  },
  subtitle: {
    fontSize: Typography.caption.fontSize,
    color: Colors.dark.textSecondary,
    marginTop: 2,
  },
  subtitleCompleted: {
    textDecorationLine: 'line-through',
  },
  priority: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    marginTop: 4,
    letterSpacing: 0.5,
  },
  time: {
    fontSize: Typography.caption.fontSize,
    color: Colors.dark.textSecondary,
    marginLeft: Spacing.md,
  },
});
