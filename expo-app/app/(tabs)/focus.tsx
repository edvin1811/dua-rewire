import React, { useState, useEffect } from 'react';
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
import { DuoButton, Card } from '@/components';
import { StreakBadge } from '@/components/StreakBadge';
import { Colors, Spacing, Radius, Typography } from '@/constants/theme';

const routineTemplates = [
  {
    id: '1',
    name: 'Morning Routine',
    apps: '6 APPS',
    duration: '45M SESSION',
    icon: 'sunny',
    color: Colors.warning.DEFAULT,
  },
  {
    id: '2',
    name: 'School Mode',
    apps: 'SOCIALS &',
    subtitle: 'ENTERTAINMENT',
    icon: 'book',
    color: Colors.primary.DEFAULT,
  },
  {
    id: '3',
    name: 'Deep Work',
    apps: 'ALL NON-ESSENTIAL',
    subtitle: 'APPS',
    icon: 'bulb',
    color: Colors.purple.DEFAULT,
  },
];

export default function FocusScreen() {
  const [isBlocking, setIsBlocking] = useState(true);
  const [timeRemaining, setTimeRemaining] = useState({ hours: 0, minutes: 24, seconds: 12 });
  const streakDays = 12;

  // Countdown timer simulation
  useEffect(() => {
    if (!isBlocking) return;

    const interval = setInterval(() => {
      setTimeRemaining(prev => {
        let { hours, minutes, seconds } = prev;
        if (seconds > 0) {
          seconds--;
        } else if (minutes > 0) {
          minutes--;
          seconds = 59;
        } else if (hours > 0) {
          hours--;
          minutes = 59;
          seconds = 59;
        }
        return { hours, minutes, seconds };
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [isBlocking]);

  const formatTime = (num: number) => num.toString().padStart(2, '0');

  const handleStopBlocking = () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    setIsBlocking(false);
  };

  const handleStartTemplate = (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setIsBlocking(true);
    setTimeRemaining({ hours: 0, minutes: 45, seconds: 0 });
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Active Blocking</Text>
          <StreakBadge count={streakDays} variant="pill" />
        </View>

        {/* Mascot Message */}
        <View style={styles.mascotRow}>
          <View style={styles.mascotCircle}>
            <Text style={styles.mascotEmoji}>🦉</Text>
            <View style={styles.checkBadge}>
              <Ionicons name="checkmark" size={12} color="#FFFFFF" />
            </View>
          </View>
          <View style={styles.messageBubble}>
            <Text style={styles.messageText}>
              "Keep going! You're 80% through this session!"
            </Text>
          </View>
        </View>

        {/* Active Session Card */}
        {isBlocking && (
          <Card style={styles.sessionCard} withBorder>
            <View style={styles.sessionHeader}>
              <Ionicons name="lock-closed" size={16} color={Colors.dark.textSecondary} />
              <Text style={styles.sessionMode}>DEEP FOCUS MODE</Text>
              <View style={styles.strictBadge}>
                <Text style={styles.strictText}>STRICT</Text>
              </View>
            </View>

            {/* Timer */}
            <View style={styles.timerContainer}>
              <Text style={styles.timerText}>
                {formatTime(timeRemaining.hours)} : {formatTime(timeRemaining.minutes)} : {formatTime(timeRemaining.seconds)}
              </Text>
              <Text style={styles.timerLabel}>REMAINING TIME</Text>
            </View>

            {/* Stop Button */}
            <DuoButton
              title="STOP BLOCKING"
              icon="close-circle"
              iconPosition="left"
              onPress={handleStopBlocking}
              variant="danger"
            />
          </Card>
        )}

        {/* Routine Templates */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Routine Templates</Text>
            <Pressable style={styles.addNewButton}>
              <Text style={styles.addNewText}>+ ADD NEW</Text>
            </Pressable>
          </View>

          <View style={styles.templateList}>
            {routineTemplates.map(template => (
              <Pressable
                key={template.id}
                style={styles.templateCard}
                onPress={() => handleStartTemplate(template.id)}
              >
                <View style={[styles.templateIcon, { backgroundColor: template.color + '20' }]}>
                  <Ionicons name={template.icon as any} size={24} color={template.color} />
                </View>
                <View style={styles.templateContent}>
                  <Text style={styles.templateName}>{template.name}</Text>
                  <Text style={styles.templateInfo}>
                    {template.apps}
                    {template.duration && ` • ${template.duration}`}
                    {template.subtitle && `\n${template.subtitle}`}
                  </Text>
                </View>
                <View style={styles.playButton}>
                  <Ionicons name="play" size={20} color={Colors.success.DEFAULT} />
                </View>
              </Pressable>
            ))}
          </View>
        </View>

        {/* Quick Actions */}
        <View style={styles.quickActions}>
          <Pressable style={styles.quickActionCard}>
            <Ionicons name="grid" size={24} color={Colors.error.DEFAULT} />
            <Text style={styles.quickActionText}>QUICK CONFIG</Text>
          </Pressable>

          <Pressable style={styles.quickActionCard}>
            <Ionicons name="time" size={24} color={Colors.primary.DEFAULT} />
            <Text style={styles.quickActionText}>HISTORY</Text>
          </Pressable>
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
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  title: {
    fontSize: Typography.title1.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  mascotRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  mascotCircle: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.success.DEFAULT,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
    position: 'relative',
  },
  mascotEmoji: {
    fontSize: 28,
  },
  checkBadge: {
    position: 'absolute',
    top: -2,
    right: -2,
    width: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: Colors.success.DEFAULT,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: Colors.dark.background,
  },
  messageBubble: {
    flex: 1,
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.dark.border,
  },
  messageText: {
    fontSize: Typography.subhead.fontSize,
    color: Colors.dark.textPrimary,
    fontStyle: 'italic',
  },
  sessionCard: {
    marginBottom: Spacing.lg,
  },
  sessionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  sessionMode: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: Colors.dark.textSecondary,
    marginLeft: Spacing.sm,
    letterSpacing: 0.5,
    flex: 1,
  },
  strictBadge: {
    backgroundColor: Colors.success.DEFAULT,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: Radius.pill,
  },
  strictText: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: '#FFFFFF',
    letterSpacing: 0.5,
  },
  timerContainer: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  timerText: {
    fontSize: 48,
    fontWeight: '300',
    color: Colors.dark.textPrimary,
    letterSpacing: 4,
    fontVariant: ['tabular-nums'],
  },
  timerLabel: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    letterSpacing: 1,
    marginTop: Spacing.sm,
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
  addNewButton: {
    backgroundColor: Colors.success.DEFAULT + '20',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
  },
  addNewText: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: Colors.success.DEFAULT,
    letterSpacing: 0.5,
  },
  templateList: {
    gap: Spacing.md,
  },
  templateCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.dark.border,
  },
  templateIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  templateContent: {
    flex: 1,
  },
  templateName: {
    fontSize: Typography.headline.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  templateInfo: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    marginTop: 2,
    letterSpacing: 0.3,
  },
  playButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.success.DEFAULT + '20',
    alignItems: 'center',
    justifyContent: 'center',
  },
  quickActions: {
    flexDirection: 'row',
    gap: Spacing.md,
    marginBottom: Spacing.lg,
  },
  quickActionCard: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.lg,
    paddingVertical: Spacing.xl,
    borderWidth: 1,
    borderColor: Colors.dark.border,
  },
  quickActionText: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: Colors.dark.textSecondary,
    marginTop: Spacing.sm,
    letterSpacing: 0.5,
  },
  bottomSpacer: {
    height: 100,
  },
});
