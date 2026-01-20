import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  StyleSheet,
  SafeAreaView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { Card } from '@/components';
import { TaskItem } from '@/components/TaskItem';
import { CategoryUsageBar } from '@/components/AppUsageBar';
import { StreakBadge } from '@/components/StreakBadge';
import { Colors, Spacing, Radius, Typography } from '@/constants/theme';

const weekDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const dates = [12, 13, 14, 15, 16, 17, 18];

const mockTasks = [
  { id: '1', title: 'Morning Reading', subtitle: '30 minutes completed', completed: true },
  { id: '2', title: 'Deep Work Session', priority: 'high' as const, completed: false },
  { id: '3', title: 'Review Goals', subtitle: 'Weekly check-in', completed: false },
];

const mockApps = [
  { name: 'Productivity', usage: '2h 15m', percentage: 80, color: Colors.primary.DEFAULT, icon: 'briefcase' as const },
  { name: 'Reading', usage: '1h 45m', percentage: 60, color: Colors.success.DEFAULT, icon: 'book' as const },
  { name: 'Social', usage: '45m', percentage: 30, color: Colors.error.DEFAULT, icon: 'logo-youtube' as const },
];

export default function InsightsScreen() {
  const [selectedDay, setSelectedDay] = useState(2); // Wednesday
  const [tasks, setTasks] = useState(mockTasks);
  const streakDays = 12;
  const screenTime = '4h 32m';

  const toggleTask = (id: string) => {
    setTasks(prev =>
      prev.map(task =>
        task.id === id ? { ...task, completed: !task.completed } : task
      )
    );
  };

  const handleDaySelect = (index: number) => {
    Haptics.selectionAsync();
    setSelectedDay(index);
  };

  const pendingTasks = tasks.filter(t => !t.completed).length;

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.title}>Insights</Text>
            <Text style={styles.subtitle}>Your focus journey</Text>
          </View>
          <StreakBadge count={streakDays} variant="pill" />
        </View>

        {/* Date Selector */}
        <View style={styles.dateSelector}>
          {weekDays.map((day, index) => (
            <Pressable
              key={day}
              onPress={() => handleDaySelect(index)}
              style={[
                styles.dateItem,
                selectedDay === index && styles.dateItemSelected,
              ]}
            >
              <Text
                style={[
                  styles.dayText,
                  selectedDay === index && styles.dayTextSelected,
                ]}
              >
                {day}
              </Text>
              <Text
                style={[
                  styles.dateText,
                  selectedDay === index && styles.dateTextSelected,
                ]}
              >
                {dates[index]}
              </Text>
            </Pressable>
          ))}
        </View>

        {/* Screen Time Card */}
        <Card style={styles.screenTimeCard} withBorder>
          <View style={styles.screenTimeHeader}>
            <View>
              <Text style={styles.screenTimeLabel}>Screen Time</Text>
              <Text style={styles.screenTimeValue}>TODAY: {screenTime}</Text>
            </View>
            <View style={[styles.chartIcon, { backgroundColor: Colors.primary.DEFAULT + '20' }]}>
              <Ionicons name="bar-chart" size={20} color={Colors.primary.DEFAULT} />
            </View>
          </View>

          {/* Mini bar chart */}
          <View style={styles.chartContainer}>
            {[30, 45, 60, 40, 55, 35, 50].map((height, index) => (
              <View key={index} style={styles.barWrapper}>
                <View
                  style={[
                    styles.bar,
                    { height: height * 1.5 },
                    index === selectedDay && styles.barSelected,
                  ]}
                />
              </View>
            ))}
          </View>

          <View style={styles.chartLabels}>
            {['9a', '10a', '11a', '12p', '1p', '2p', '3p'].map((label, index) => (
              <Text key={label} style={styles.chartLabel}>{label}</Text>
            ))}
          </View>
        </Card>

        {/* Daily Tasks Section */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Daily Tasks</Text>
            <Text style={styles.taskCount}>{pendingTasks} LEFT</Text>
          </View>

          <View style={styles.taskList}>
            {tasks.map(task => (
              <TaskItem
                key={task.id}
                title={task.title}
                subtitle={task.subtitle}
                isCompleted={task.completed}
                priority={task.priority}
                onToggle={() => toggleTask(task.id)}
              />
            ))}

            {/* Add Task Button */}
            <Pressable style={styles.addTaskButton}>
              <Ionicons name="add" size={20} color={Colors.dark.textSecondary} />
              <Text style={styles.addTaskText}>Add New Task</Text>
            </Pressable>
          </View>
        </View>

        {/* Top Apps Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Top Apps</Text>

          <View style={styles.appsList}>
            {mockApps.map((app, index) => (
              <CategoryUsageBar
                key={app.name}
                category={app.name}
                usage={app.usage}
                percentage={app.percentage}
                color={app.color}
                iconName={app.icon}
              />
            ))}
          </View>
        </View>

        {/* Bottom spacing for tab bar */}
        <View style={styles.bottomSpacer} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.dark.background,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.md,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: Spacing.lg,
  },
  title: {
    fontSize: Typography.title1.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  subtitle: {
    fontSize: Typography.subhead.fontSize,
    color: Colors.dark.textSecondary,
    marginTop: 2,
  },
  dateSelector: {
    flexDirection: 'row',
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.xl,
    padding: Spacing.xs,
    marginBottom: Spacing.lg,
    borderWidth: 1,
    borderColor: Colors.dark.border,
  },
  dateItem: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    borderRadius: Radius.lg,
  },
  dateItemSelected: {
    backgroundColor: Colors.success.DEFAULT,
  },
  dayText: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textTertiary,
    marginBottom: 4,
  },
  dayTextSelected: {
    color: '#FFFFFF',
  },
  dateText: {
    fontSize: Typography.headline.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  dateTextSelected: {
    color: '#FFFFFF',
  },
  screenTimeCard: {
    marginBottom: Spacing.lg,
  },
  screenTimeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: Spacing.lg,
  },
  screenTimeLabel: {
    fontSize: Typography.headline.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  screenTimeValue: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    marginTop: 4,
    letterSpacing: 0.5,
  },
  chartIcon: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  chartContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    height: 100,
    marginBottom: Spacing.sm,
  },
  barWrapper: {
    flex: 1,
    alignItems: 'center',
  },
  bar: {
    width: '70%',
    backgroundColor: Colors.success.light,
    borderRadius: Radius.xs,
    opacity: 0.7,
  },
  barSelected: {
    backgroundColor: Colors.success.DEFAULT,
    opacity: 1,
  },
  chartLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  chartLabel: {
    flex: 1,
    textAlign: 'center',
    fontSize: Typography.caption.fontSize,
    color: Colors.dark.textTertiary,
  },
  section: {
    marginBottom: Spacing.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  sectionTitle: {
    fontSize: Typography.title3.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  taskCount: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: Colors.success.DEFAULT,
    letterSpacing: 0.5,
  },
  taskList: {
    gap: Spacing.sm,
  },
  addTaskButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    borderRadius: Radius.lg,
    borderWidth: 2,
    borderStyle: 'dashed',
    borderColor: Colors.dark.border,
    gap: Spacing.sm,
  },
  addTaskText: {
    fontSize: Typography.subhead.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
  },
  appsList: {
    marginTop: Spacing.sm,
  },
  bottomSpacer: {
    height: 100,
  },
});
