import { useState, useEffect, useCallback } from 'react';
import { screenTimeManager, AppUsageData, AuthorizationStatus } from '@/modules';

interface ScreenTimeState {
  isAuthorized: boolean;
  authStatus: AuthorizationStatus;
  isLoading: boolean;
  error: string | null;
  todayUsage: AppUsageData[];
  totalScreenTime: {
    hours: number;
    minutes: number;
    totalMinutes: number;
  };
}

interface UseScreenTimeReturn extends ScreenTimeState {
  requestPermission: () => Promise<boolean>;
  refreshUsage: () => Promise<void>;
  isAvailable: boolean;
}

/**
 * Hook for accessing Screen Time / Usage Stats data
 * Cross-platform support for iOS Screen Time API and Android UsageStatsManager
 */
export function useScreenTime(): UseScreenTimeReturn {
  const [state, setState] = useState<ScreenTimeState>({
    isAuthorized: false,
    authStatus: 'notDetermined',
    isLoading: true,
    error: null,
    todayUsage: [],
    totalScreenTime: { hours: 0, minutes: 0, totalMinutes: 0 },
  });

  const isAvailable = screenTimeManager.isAvailable();

  // Check authorization status on mount
  useEffect(() => {
    checkAuthorization();
  }, []);

  // Fetch usage data when authorized
  useEffect(() => {
    if (state.isAuthorized) {
      fetchUsageData();
    }
  }, [state.isAuthorized]);

  const checkAuthorization = async () => {
    if (!isAvailable) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: 'Screen time module not available on this device',
      }));
      return;
    }

    try {
      const status = await screenTimeManager.checkAuthorizationStatus();
      setState(prev => ({
        ...prev,
        authStatus: status,
        isAuthorized: status === 'approved',
        isLoading: false,
      }));
    } catch (error) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : 'Failed to check authorization',
      }));
    }
  };

  const requestPermission = useCallback(async (): Promise<boolean> => {
    if (!isAvailable) return false;

    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const granted = await screenTimeManager.requestAuthorization();
      setState(prev => ({
        ...prev,
        isAuthorized: granted,
        authStatus: granted ? 'approved' : 'denied',
        isLoading: false,
      }));
      return granted;
    } catch (error) {
      setState(prev => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : 'Failed to request permission',
      }));
      return false;
    }
  }, [isAvailable]);

  const fetchUsageData = async () => {
    if (!isAvailable || !state.isAuthorized) return;

    try {
      const [usage, screenTime] = await Promise.all([
        screenTimeManager.getTodayUsage(),
        screenTimeManager.getTodayScreenTime(),
      ]);

      setState(prev => ({
        ...prev,
        todayUsage: usage,
        totalScreenTime: screenTime,
        error: null,
      }));
    } catch (error) {
      setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Failed to fetch usage data',
      }));
    }
  };

  const refreshUsage = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true }));
    await fetchUsageData();
    setState(prev => ({ ...prev, isLoading: false }));
  }, [state.isAuthorized]);

  return {
    ...state,
    requestPermission,
    refreshUsage,
    isAvailable,
  };
}
