import React from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  Image,
  StyleSheet,
  SafeAreaView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { Card } from '@/components';
import { StreakBadge } from '@/components/StreakBadge';
import { Colors, Spacing, Radius, Typography } from '@/constants/theme';

const badges = [
  { id: '1', name: 'Night Owl', emoji: '🦉', unlocked: true },
  { id: '2', name: 'On Fire', emoji: '🔥', unlocked: true },
  { id: '3', name: 'Laser Focus', emoji: '🎯', unlocked: true },
  { id: '4', name: 'Speedy', emoji: '⚡', unlocked: true },
  { id: '5', name: 'Loved It', emoji: '❤️', unlocked: true },
  { id: '6', name: 'Zen Master', emoji: '🔒', unlocked: false },
];

const menuItems = [
  { id: '1', title: 'Notifications', icon: 'notifications', color: Colors.primary.DEFAULT },
  { id: '2', title: 'Privacy', icon: 'lock-closed', color: Colors.warning.DEFAULT },
  { id: '3', title: 'Help & Support', icon: 'help-circle', color: Colors.purple.DEFAULT },
];

export default function ProfileScreen() {
  const userName = 'Alex Johnson';
  const userHandle = '@alexj_focus';
  const level = 12;
  const currentXP = 1200;
  const maxXP = 2500;
  const streakDays = 14;
  const xpProgress = currentXP / maxXP;

  const handleMenuPress = (id: string) => {
    Haptics.selectionAsync();
    // Navigate to respective screen
  };

  const handleLogout = () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    // Handle logout
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
          <Text style={styles.title}>Profile</Text>
          <Pressable style={styles.settingsButton}>
            <Ionicons name="settings-outline" size={24} color={Colors.dark.textPrimary} />
          </Pressable>
        </View>

        {/* Profile Section */}
        <View style={styles.profileSection}>
          <View style={styles.avatarContainer}>
            <Image
              source={{ uri: 'https://api.dicebear.com/7.x/avataaars/png?seed=Alex' }}
              style={styles.avatar}
            />
            <View style={styles.editBadge}>
              <Ionicons name="pencil" size={12} color="#FFFFFF" />
            </View>
          </View>
          <Text style={styles.userName}>{userName}</Text>
          <Text style={styles.userHandle}>{userHandle}</Text>
        </View>

        {/* Level & Streak Card */}
        <Card style={styles.levelCard} withBorder>
          <View style={styles.levelRow}>
            {/* Streak Section */}
            <View style={styles.streakSection}>
              <View style={styles.streakIcon}>
                <Ionicons name="flame" size={24} color={Colors.warning.DEFAULT} />
              </View>
              <Text style={styles.streakCount}>{streakDays}</Text>
              <Text style={styles.streakLabel}>DAY STREAK</Text>
            </View>

            {/* Divider */}
            <View style={styles.divider} />

            {/* Level Section */}
            <View style={styles.levelSection}>
              <View style={styles.levelHeader}>
                <Text style={styles.levelLabel}>LEVEL {level}</Text>
                <Text style={styles.xpText}>{currentXP} / {maxXP} XP</Text>
              </View>

              {/* XP Progress Bar */}
              <View style={styles.xpBarContainer}>
                <View style={[styles.xpBar, { width: `${xpProgress * 100}%` }]} />
              </View>

              <Text style={styles.rankLabel}>PRODUCTIVITY MASTER</Text>
            </View>
          </View>
        </Card>

        {/* Recent Badges */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Recent Badges</Text>
            <Pressable>
              <Text style={styles.viewAllText}>VIEW ALL</Text>
            </Pressable>
          </View>

          <View style={styles.badgesGrid}>
            {badges.map(badge => (
              <View
                key={badge.id}
                style={[
                  styles.badgeItem,
                  !badge.unlocked && styles.badgeLocked,
                ]}
              >
                <View style={[
                  styles.badgeCircle,
                  !badge.unlocked && styles.badgeCircleLocked,
                ]}>
                  <Text style={styles.badgeEmoji}>
                    {badge.unlocked ? badge.emoji : '🔒'}
                  </Text>
                </View>
                <Text style={[
                  styles.badgeName,
                  !badge.unlocked && styles.badgeNameLocked,
                ]}>
                  {badge.name}
                </Text>
              </View>
            ))}
          </View>
        </View>

        {/* General Settings */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>General</Text>

          <View style={styles.menuList}>
            {menuItems.map(item => (
              <Pressable
                key={item.id}
                style={styles.menuItem}
                onPress={() => handleMenuPress(item.id)}
              >
                <View style={[styles.menuIcon, { backgroundColor: item.color + '20' }]}>
                  <Ionicons name={item.icon as any} size={20} color={item.color} />
                </View>
                <Text style={styles.menuTitle}>{item.title}</Text>
                <Ionicons name="chevron-forward" size={20} color={Colors.dark.textTertiary} />
              </Pressable>
            ))}

            {/* Logout Button */}
            <Pressable
              style={[styles.menuItem, styles.logoutItem]}
              onPress={handleLogout}
            >
              <View style={[styles.menuIcon, { backgroundColor: Colors.error.DEFAULT + '20' }]}>
                <Ionicons name="log-out-outline" size={20} color={Colors.error.DEFAULT} />
              </View>
              <Text style={[styles.menuTitle, styles.logoutText]}>Log Out</Text>
            </Pressable>
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
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  title: {
    fontSize: Typography.title1.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  settingsButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  profileSection: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: Spacing.md,
  },
  avatar: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: Colors.dark.surface,
    borderWidth: 3,
    borderColor: Colors.dark.border,
  },
  editBadge: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: Colors.success.DEFAULT,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: Colors.dark.background,
  },
  userName: {
    fontSize: Typography.title2.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  userHandle: {
    fontSize: Typography.subhead.fontSize,
    color: Colors.dark.textSecondary,
    marginTop: 4,
  },
  levelCard: {
    marginBottom: Spacing.lg,
  },
  levelRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  streakSection: {
    alignItems: 'center',
    paddingRight: Spacing.lg,
  },
  streakIcon: {
    marginBottom: Spacing.xs,
  },
  streakCount: {
    fontSize: Typography.title2.fontSize,
    fontWeight: '700',
    color: Colors.dark.textPrimary,
  },
  streakLabel: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    letterSpacing: 0.5,
  },
  divider: {
    width: 1,
    height: '100%',
    backgroundColor: Colors.dark.border,
    marginHorizontal: Spacing.md,
  },
  levelSection: {
    flex: 1,
    paddingLeft: Spacing.md,
  },
  levelHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: Spacing.sm,
  },
  levelLabel: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: Colors.success.DEFAULT,
    letterSpacing: 0.5,
  },
  xpText: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
  },
  xpBarContainer: {
    height: 8,
    backgroundColor: Colors.dark.border,
    borderRadius: 4,
    marginBottom: Spacing.sm,
    overflow: 'hidden',
  },
  xpBar: {
    height: '100%',
    backgroundColor: Colors.success.DEFAULT,
    borderRadius: 4,
  },
  rankLabel: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textSecondary,
    letterSpacing: 0.5,
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
  viewAllText: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '700',
    color: Colors.primary.DEFAULT,
    letterSpacing: 0.5,
  },
  badgesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.md,
  },
  badgeItem: {
    width: '30%',
    alignItems: 'center',
  },
  badgeLocked: {
    opacity: 0.5,
  },
  badgeCircle: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.dark.card,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: Colors.dark.border,
    marginBottom: Spacing.sm,
  },
  badgeCircleLocked: {
    backgroundColor: Colors.dark.surface,
    borderColor: Colors.dark.border,
  },
  badgeEmoji: {
    fontSize: 24,
  },
  badgeName: {
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.dark.textPrimary,
    textAlign: 'center',
  },
  badgeNameLocked: {
    color: Colors.dark.textTertiary,
  },
  menuList: {
    gap: Spacing.sm,
    marginTop: Spacing.sm,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.dark.card,
    borderRadius: Radius.lg,
    padding: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.dark.border,
  },
  menuIcon: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  menuTitle: {
    flex: 1,
    fontSize: Typography.body.fontSize,
    fontWeight: '600',
    color: Colors.dark.textPrimary,
  },
  logoutItem: {
    backgroundColor: Colors.error.DEFAULT + '15',
    borderColor: Colors.error.DEFAULT + '30',
  },
  logoutText: {
    color: Colors.error.DEFAULT,
  },
  bottomSpacer: {
    height: 100,
  },
});
