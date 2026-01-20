import { NativeModules, Platform } from 'react-native';

// Widget data interface
export interface WidgetData {
  focusMinutes: number;
  streakDays: number;
  blockedApps: number;
  isFocusing: boolean;
  dailyGoalMinutes: number;
}

// iOS Widget Module interface
interface iOSWidgetModuleInterface {
  updateWidgetData(data: WidgetData): void;
  reloadAllTimelines(): void;
  reloadTimeline(kind: string): void;
}

// Android Widget Module interface
interface AndroidWidgetModuleInterface {
  updateWidgetData(
    focusMinutes: number,
    streakDays: number,
    blockedApps: number,
    isFocusing: boolean,
    dailyGoalMinutes: number
  ): void;
  requestWidgetUpdate(): void;
}

// Get native modules
const iOSWidgetNativeModule = NativeModules.WidgetModule as iOSWidgetModuleInterface | undefined;
const AndroidWidgetNativeModule = NativeModules.WidgetModule as AndroidWidgetModuleInterface | undefined;

/**
 * Cross-platform Widget Manager
 * Updates home screen widgets with focus statistics
 */
class WidgetManager {
  private currentData: WidgetData = {
    focusMinutes: 0,
    streakDays: 0,
    blockedApps: 0,
    isFocusing: false,
    dailyGoalMinutes: 180,
  };

  /**
   * Check if widgets are supported on this platform
   */
  isAvailable(): boolean {
    if (Platform.OS === 'ios') {
      return iOSWidgetNativeModule !== undefined;
    } else if (Platform.OS === 'android') {
      return AndroidWidgetNativeModule !== undefined;
    }
    return false;
  }

  /**
   * Update widget data
   * Call this whenever focus stats change
   */
  updateWidgetData(data: Partial<WidgetData>): void {
    // Merge with current data
    this.currentData = {
      ...this.currentData,
      ...data,
    };

    if (Platform.OS === 'ios' && iOSWidgetNativeModule) {
      iOSWidgetNativeModule.updateWidgetData(this.currentData);
    } else if (Platform.OS === 'android' && AndroidWidgetNativeModule) {
      AndroidWidgetNativeModule.updateWidgetData(
        this.currentData.focusMinutes,
        this.currentData.streakDays,
        this.currentData.blockedApps,
        this.currentData.isFocusing,
        this.currentData.dailyGoalMinutes
      );
    }
  }

  /**
   * Update focus minutes
   */
  setFocusMinutes(minutes: number): void {
    this.updateWidgetData({ focusMinutes: minutes });
  }

  /**
   * Update streak days
   */
  setStreakDays(days: number): void {
    this.updateWidgetData({ streakDays: days });
  }

  /**
   * Update blocked apps count
   */
  setBlockedApps(count: number): void {
    this.updateWidgetData({ blockedApps: count });
  }

  /**
   * Update focus session status
   */
  setFocusSessionActive(isActive: boolean): void {
    this.updateWidgetData({ isFocusing: isActive });
  }

  /**
   * Update daily goal
   */
  setDailyGoal(minutes: number): void {
    this.updateWidgetData({ dailyGoalMinutes: minutes });
  }

  /**
   * Force refresh all widgets (iOS only)
   */
  reloadAllWidgets(): void {
    if (Platform.OS === 'ios' && iOSWidgetNativeModule) {
      iOSWidgetNativeModule.reloadAllTimelines();
    } else if (Platform.OS === 'android' && AndroidWidgetNativeModule) {
      AndroidWidgetNativeModule.requestWidgetUpdate();
    }
  }

  /**
   * Get current widget data
   */
  getCurrentData(): WidgetData {
    return { ...this.currentData };
  }
}

// Export singleton instance
export const widgetManager = new WidgetManager();

// Export types
export type { iOSWidgetModuleInterface, AndroidWidgetModuleInterface };
