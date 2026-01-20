import { useCallback, useEffect, useRef } from 'react';
import { widgetManager, WidgetData } from '@/modules';

interface UseWidgetOptions {
  /** Auto-update widget when data changes */
  autoUpdate?: boolean;
  /** Initial widget data */
  initialData?: Partial<WidgetData>;
}

interface UseWidgetReturn {
  /** Update all widget data at once */
  updateWidget: (data: Partial<WidgetData>) => void;
  /** Update focus minutes */
  setFocusMinutes: (minutes: number) => void;
  /** Update streak days */
  setStreakDays: (days: number) => void;
  /** Update blocked apps count */
  setBlockedApps: (count: number) => void;
  /** Set focus session status */
  setFocusing: (isFocusing: boolean) => void;
  /** Update daily goal */
  setDailyGoal: (minutes: number) => void;
  /** Force refresh all widgets */
  refreshWidgets: () => void;
  /** Check if widgets are available */
  isAvailable: boolean;
}

/**
 * Hook for managing home screen widgets
 * Updates widget data and refreshes widget timelines
 */
export function useWidget(options: UseWidgetOptions = {}): UseWidgetReturn {
  const { autoUpdate = true, initialData } = options;
  const isAvailable = widgetManager.isAvailable();
  const initializedRef = useRef(false);

  // Initialize widget with initial data
  useEffect(() => {
    if (isAvailable && initialData && !initializedRef.current) {
      widgetManager.updateWidgetData(initialData);
      initializedRef.current = true;
    }
  }, [isAvailable, initialData]);

  const updateWidget = useCallback((data: Partial<WidgetData>) => {
    if (isAvailable) {
      widgetManager.updateWidgetData(data);
    }
  }, [isAvailable]);

  const setFocusMinutes = useCallback((minutes: number) => {
    if (isAvailable) {
      widgetManager.setFocusMinutes(minutes);
    }
  }, [isAvailable]);

  const setStreakDays = useCallback((days: number) => {
    if (isAvailable) {
      widgetManager.setStreakDays(days);
    }
  }, [isAvailable]);

  const setBlockedApps = useCallback((count: number) => {
    if (isAvailable) {
      widgetManager.setBlockedApps(count);
    }
  }, [isAvailable]);

  const setFocusing = useCallback((isFocusing: boolean) => {
    if (isAvailable) {
      widgetManager.setFocusSessionActive(isFocusing);
    }
  }, [isAvailable]);

  const setDailyGoal = useCallback((minutes: number) => {
    if (isAvailable) {
      widgetManager.setDailyGoal(minutes);
    }
  }, [isAvailable]);

  const refreshWidgets = useCallback(() => {
    if (isAvailable) {
      widgetManager.reloadAllWidgets();
    }
  }, [isAvailable]);

  return {
    updateWidget,
    setFocusMinutes,
    setStreakDays,
    setBlockedApps,
    setFocusing,
    setDailyGoal,
    refreshWidgets,
    isAvailable,
  };
}
