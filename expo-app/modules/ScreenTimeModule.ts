import { NativeModules, Platform, NativeEventEmitter } from 'react-native';

// Type definitions for Screen Time API
export interface AppUsageData {
  bundleIdentifier: string;
  appName: string;
  usageTimeMs: number;
  usageTimeMinutes: number;
  category?: string;
  lastUsed?: number;
}

export interface UsageSummary {
  totalScreenTimeMs: number;
  totalScreenTimeMinutes: number;
  totalScreenTimeHours: number;
  pickups?: number;
  notifications?: number;
  apps: AppUsageData[];
}

export interface FocusSession {
  name: string;
  durationMinutes: number;
  startTime: number;
  endTime?: number;
  blockedApps: string[];
}

export type AuthorizationStatus = 'notDetermined' | 'denied' | 'approved' | 'unknown';

// iOS Screen Time Module interface
interface ScreenTimeModuleInterface {
  // Authorization
  requestAuthorization(): Promise<boolean>;
  checkAuthorizationStatus(): Promise<AuthorizationStatus>;

  // App picker
  presentAppPicker(): void;

  // Focus sessions
  startFocusSession(name: string, durationMinutes: number): Promise<boolean>;
  stopFocusSession(name: string): void;
  stopAllMonitoring(): void;

  // Usage data
  getUsageSummary(): Promise<UsageSummary | null>;
}

// Android Usage Stats Module interface
interface UsageStatsModuleInterface {
  // Permission
  hasPermission(): Promise<boolean>;
  requestPermission(): Promise<boolean>;

  // Usage data
  getTodayUsage(): Promise<AppUsageData[]>;
  getUsageForRange(startTimeMs: number, endTimeMs: number): Promise<AppUsageData[]>;
  getTodayScreenTime(): Promise<{ totalTimeMs: number; totalTimeMinutes: number; totalTimeHours: number }>;
  getTodayLaunchCount(): Promise<Record<string, number>>;
  getWeeklyUsage(): Promise<Array<{ date: string; usageTimeMs: number; usageTimeMinutes: number; usageTimeHours: number }>>;
}

// Get native modules
const ScreenTimeNativeModule = NativeModules.ScreenTimeModule as ScreenTimeModuleInterface | undefined;
const UsageStatsNativeModule = NativeModules.UsageStatsModule as UsageStatsModuleInterface | undefined;

// Event emitter for iOS notifications
const screenTimeEventEmitter = ScreenTimeNativeModule
  ? new NativeEventEmitter(NativeModules.ScreenTimeModule)
  : null;

/**
 * Cross-platform Screen Time / Usage Stats API
 */
class ScreenTimeManager {
  private listeners: Map<string, any> = new Map();

  /**
   * Check if the module is available on the current platform
   */
  isAvailable(): boolean {
    if (Platform.OS === 'ios') {
      return ScreenTimeNativeModule !== undefined;
    } else if (Platform.OS === 'android') {
      return UsageStatsNativeModule !== undefined;
    }
    return false;
  }

  /**
   * Request authorization/permission for screen time access
   */
  async requestAuthorization(): Promise<boolean> {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      return ScreenTimeNativeModule.requestAuthorization();
    } else if (Platform.OS === 'android' && UsageStatsNativeModule) {
      return UsageStatsNativeModule.requestPermission();
    }
    console.warn('Screen time module not available');
    return false;
  }

  /**
   * Check current authorization/permission status
   */
  async checkAuthorizationStatus(): Promise<AuthorizationStatus> {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      return ScreenTimeNativeModule.checkAuthorizationStatus();
    } else if (Platform.OS === 'android' && UsageStatsNativeModule) {
      const hasPermission = await UsageStatsNativeModule.hasPermission();
      return hasPermission ? 'approved' : 'denied';
    }
    return 'unknown';
  }

  /**
   * Get today's app usage data
   */
  async getTodayUsage(): Promise<AppUsageData[]> {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      const summary = await ScreenTimeNativeModule.getUsageSummary();
      return summary?.apps || [];
    } else if (Platform.OS === 'android' && UsageStatsNativeModule) {
      return UsageStatsNativeModule.getTodayUsage();
    }
    return [];
  }

  /**
   * Get today's total screen time
   */
  async getTodayScreenTime(): Promise<{ hours: number; minutes: number; totalMinutes: number }> {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      const summary = await ScreenTimeNativeModule.getUsageSummary();
      const totalMinutes = summary?.totalScreenTimeMinutes || 0;
      return {
        hours: Math.floor(totalMinutes / 60),
        minutes: Math.round(totalMinutes % 60),
        totalMinutes,
      };
    } else if (Platform.OS === 'android' && UsageStatsNativeModule) {
      const result = await UsageStatsNativeModule.getTodayScreenTime();
      return {
        hours: result.totalTimeHours,
        minutes: Math.round(result.totalTimeMinutes % 60),
        totalMinutes: result.totalTimeMinutes,
      };
    }
    return { hours: 0, minutes: 0, totalMinutes: 0 };
  }

  /**
   * Get weekly usage summary (Android only for now)
   */
  async getWeeklyUsage(): Promise<Array<{ date: string; hours: number; minutes: number }>> {
    if (Platform.OS === 'android' && UsageStatsNativeModule) {
      const data = await UsageStatsNativeModule.getWeeklyUsage();
      return data.map(day => ({
        date: day.date,
        hours: day.usageTimeHours,
        minutes: day.usageTimeMinutes,
      }));
    }
    // iOS would use DeviceActivityReport which requires SwiftUI
    return [];
  }

  /**
   * Start a focus session (iOS only with Screen Time API)
   */
  async startFocusSession(name: string, durationMinutes: number): Promise<boolean> {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      return ScreenTimeNativeModule.startFocusSession(name, durationMinutes);
    }
    // Android would use a different approach (accessibility service or device admin)
    console.warn('Focus sessions require iOS Screen Time API');
    return false;
  }

  /**
   * Stop a focus session (iOS only)
   */
  stopFocusSession(name: string): void {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      ScreenTimeNativeModule.stopFocusSession(name);
    }
  }

  /**
   * Stop all monitoring (iOS only)
   */
  stopAllMonitoring(): void {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      ScreenTimeNativeModule.stopAllMonitoring();
    }
  }

  /**
   * Present the app picker (iOS only - for selecting apps to block)
   */
  presentAppPicker(): void {
    if (Platform.OS === 'ios' && ScreenTimeNativeModule) {
      ScreenTimeNativeModule.presentAppPicker();
    }
  }

  /**
   * Add listener for focus session events (iOS only)
   */
  addListener(
    event: 'focusSessionStarted' | 'focusSessionEnded' | 'thresholdReached',
    callback: (data: any) => void
  ): () => void {
    if (screenTimeEventEmitter) {
      const eventName = event === 'focusSessionStarted'
        ? 'FocusSessionStarted'
        : event === 'focusSessionEnded'
        ? 'FocusSessionEnded'
        : 'ThresholdReached';

      const subscription = screenTimeEventEmitter.addListener(eventName, callback);
      this.listeners.set(event, subscription);

      return () => {
        subscription.remove();
        this.listeners.delete(event);
      };
    }
    return () => {};
  }

  /**
   * Remove all listeners
   */
  removeAllListeners(): void {
    this.listeners.forEach((subscription) => {
      subscription.remove();
    });
    this.listeners.clear();
  }
}

// Export singleton instance
export const screenTimeManager = new ScreenTimeManager();

// Export types
export type { ScreenTimeModuleInterface, UsageStatsModuleInterface };
