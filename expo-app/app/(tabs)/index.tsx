import React from 'react';
import {
  View,
  Text,
  ScrollView,
  Image,
  StyleSheet,
  SafeAreaView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { DuoButton, Card } from '@/components';
import { ProgressRing } from '@/components/ProgressRing';
import { StreakBadge } from '@/components/StreakBadge';
import { Colors, Spacing, Radius, Typography } from '@/constants/theme';

export default function HomeScreen() {
  const dailyGoal = 75; // percentage
  const focusTime = '3h 15m';
  const activeBlocks = 4;
  const streakDays = 12;

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.userInfo}>
            <View style={styles.avatar}>
              <Image
                source={{ uri: 'https://api.dicebear.com/7.x/avataaars/png?seed=Alex' }}
                style={styles.avatarImage}
              />
              <View style={styles.onlineIndicator} />
            </View>
            <View>
              <Text style={styles.greeting}>Hi, Alex!</Text>
              <Text style={styles.subGreeting}>Ready to focus?</Text>
            </View>
          </View>
          <StreakBadge count={streakDays} variant="pill" />
        </View>

        {/* Main Progress Card */}
        <View style={styles.progressSection}>
          {/* Productive Badge */}
          <View style={styles.productiveBadge}>
            <View style={styles.productiveDot} />
            <Text style={styles.productiveText}>PRODUCTIVE!</Text>
          </View>

          {/* Progress Ring with Mascot */}
          <View style={styles.progressRingContainer}>
            <ProgressRing
              progress={dailyGoal}
              size={220}
              strokeWidth={14}
              color={Colors.success.DEFAULT}
            >
              <View style={styles.mascotContainer}>
                <View style={styles.mascotBox}>
                  <Text style={styles.mascotEmoji}>🦉</Text>
                </View>
                <Text style={styles.dailyGoalLabel}>DAILY GOAL</Text>
                <Text style={styles.dailyGoalValue}>{dailyGoal}%</Text>
              </View>
            </ProgressRing>
          </View>

          {/* Stats Cards */}
          <View style={styles.statsRow}>
            <Card style={styles.statCard}>
              <View style={[styles.statIcon, { backgroundColor: Colors.primary.DEFAULT + '20' }]}>
                <Ionicons name="timer-outline" size={24} color={Colors.primary.DEFAULT} />
              </View>
              <Text style={styles.statLabel}>FOCUS TIME</Text>
              <Text style={styles.statValue}>{focusTime}</Text>
            </Card>

            <Card style={styles.statCard}>
              <View style={[styles.statIcon, { backgroundColor: Colors.purple.DEFAULT + '20' }]}>
                <Ionicons name="layers-outline" size={24} color={Colors.purple.DEFAULT} />
              </View>
              <Text style={styles.statLabel}>ACTIVE BLOCKS</Text>
              <Text style={styles.statValue}>{activeBlocks}</Text>
            </Card>
          </View>
        </View>

        {/* Start Focus Button */}
        <View style={styles.buttonContainer}>
          <DuoButton
            title="START FOCUS MODE"
            icon="play"
            onPress={() => {}}
            variant="success"
          />
        </View>

        {/* Tip Card */}
        <Card style={styles.tipCard} withBorder>
          <View style={styles.tipContent}>
            <Text style={styles.tipIcon}>💡</Text>
            <Text style={styles.tipText}>
              Tip: Short breaks can boost your focus by up to 40%.
            </Text>
          </View>
        </Card>

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
    marginBottom: Spacing.xl,
  },
  userInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    position: 'relative',
    marginRight: Spacing.md,
  },
  avatarImage: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: Colors.dark.surface,
  },
  onlineIndicator: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: Colors.success.DEFAULT,
    borderWidth: 2,
    borderColor: Colors.dark.background,
  },
  greeting: {
    fontSize: Typography.title2.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  subGreeting: {
    fontSize: Typography.subhead.fontSize,
    color: Colors.dark.textSecondary,
    marginTop: 2,
  },
  progressSection: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  productiveBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.success.DEFAULT + '20',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    marginBottom: Spacing.md,
  },
  productiveDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.success.DEFAULT,
    marginRight: Spacing.sm,
  },
  productiveText: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: Colors.success.DEFAULT,
    letterSpacing: 1,
  },
  progressRingContainer: {
    marginVertical: Spacing.lg,
  },
  mascotContainer: {
    alignItems: 'center',
  },
  mascotBox: {
    width: 100,
    height: 100,
    backgroundColor: Colors.dark.surface,
    borderRadius: Radius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.sm,
  },
  mascotEmoji: {
    fontSize: 48,
  },
  dailyGoalLabel: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    letterSpacing: 1,
  },
  dailyGoalValue: {
    fontSize: 32,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
    marginTop: 4,
  },
  statsRow: {
    flexDirection: 'row',
    gap: Spacing.md,
    width: '100%',
    marginTop: Spacing.md,
  },
  statCard: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: Spacing.lg,
  },
  statIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.sm,
  },
  statLabel: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    letterSpacing: 0.5,
    marginBottom: Spacing.xs,
  },
  statValue: {
    fontSize: Typography.title2.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  buttonContainer: {
    marginVertical: Spacing.lg,
  },
  tipCard: {
    marginBottom: Spacing.lg,
  },
  tipContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  tipIcon: {
    fontSize: 20,
    marginRight: Spacing.md,
  },
  tipText: {
    flex: 1,
    fontSize: Typography.subhead.fontSize,
    color: Colors.dark.textSecondary,
    lineHeight: 22,
  },
  bottomSpacer: {
    height: 100,
  },
});
