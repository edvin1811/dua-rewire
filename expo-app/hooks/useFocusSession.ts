import { useState, useCallback, useEffect, useRef } from 'react';
import { screenTimeManager } from '@/modules';
import { useWidget } from './useWidget';

interface FocusSessionState {
  isActive: boolean;
  sessionName: string | null;
  startTime: number | null;
  durationMinutes: number;
  elapsedSeconds: number;
  remainingSeconds: number;
}

interface UseFocusSessionReturn extends FocusSessionState {
  /** Start a new focus session */
  startSession: (name: string, durationMinutes: number) => Promise<boolean>;
  /** Stop the current focus session */
  stopSession: () => void;
  /** Pause/resume timer (local only, doesn't affect native blocking) */
  togglePause: () => void;
  /** Is the timer paused */
  isPaused: boolean;
  /** Formatted time remaining (mm:ss) */
  formattedTimeRemaining: string;
  /** Progress percentage (0-1) */
  progress: number;
}

/**
 * Hook for managing focus sessions with timer
 * Integrates with iOS Screen Time API for app blocking
 */
export function useFocusSession(): UseFocusSessionReturn {
  const [state, setState] = useState<FocusSessionState>({
    isActive: false,
    sessionName: null,
    startTime: null,
    durationMinutes: 0,
    elapsedSeconds: 0,
    remainingSeconds: 0,
  });

  const [isPaused, setIsPaused] = useState(false);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const widget = useWidget();

  // Timer effect
  useEffect(() => {
    if (state.isActive && !isPaused) {
      timerRef.current = setInterval(() => {
        setState(prev => {
          const newElapsed = prev.elapsedSeconds + 1;
          const totalSeconds = prev.durationMinutes * 60;
          const remaining = Math.max(0, totalSeconds - newElapsed);

          // Session complete
          if (remaining <= 0) {
            stopSessionInternal();
            return {
              ...prev,
              elapsedSeconds: totalSeconds,
              remainingSeconds: 0,
            };
          }

          return {
            ...prev,
            elapsedSeconds: newElapsed,
            remainingSeconds: remaining,
          };
        });
      }, 1000);
    }

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [state.isActive, isPaused]);

  // Update widget when session status changes
  useEffect(() => {
    widget.setFocusing(state.isActive);

    if (state.isActive) {
      // Update focus minutes periodically
      const focusMinutes = Math.floor(state.elapsedSeconds / 60);
      widget.setFocusMinutes(focusMinutes);
    }
  }, [state.isActive, state.elapsedSeconds]);

  const stopSessionInternal = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }

    if (state.sessionName) {
      screenTimeManager.stopFocusSession(state.sessionName);
    }

    setState({
      isActive: false,
      sessionName: null,
      startTime: null,
      durationMinutes: 0,
      elapsedSeconds: 0,
      remainingSeconds: 0,
    });

    setIsPaused(false);
    widget.setFocusing(false);
  }, [state.sessionName]);

  const startSession = useCallback(async (name: string, durationMinutes: number): Promise<boolean> => {
    // Stop any existing session
    if (state.isActive) {
      stopSessionInternal();
    }

    const totalSeconds = durationMinutes * 60;

    // Try to start native focus session (iOS only)
    const nativeSuccess = await screenTimeManager.startFocusSession(name, durationMinutes);

    // Start local timer regardless of native success
    setState({
      isActive: true,
      sessionName: name,
      startTime: Date.now(),
      durationMinutes,
      elapsedSeconds: 0,
      remainingSeconds: totalSeconds,
    });

    setIsPaused(false);
    widget.setFocusing(true);

    return nativeSuccess;
  }, [state.isActive]);

  const stopSession = useCallback(() => {
    stopSessionInternal();
  }, [stopSessionInternal]);

  const togglePause = useCallback(() => {
    setIsPaused(prev => !prev);
  }, []);

  // Format remaining time as mm:ss
  const formattedTimeRemaining = (() => {
    const minutes = Math.floor(state.remainingSeconds / 60);
    const seconds = state.remainingSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  })();

  // Calculate progress (0-1)
  const progress = state.durationMinutes > 0
    ? state.elapsedSeconds / (state.durationMinutes * 60)
    : 0;

  return {
    ...state,
    startSession,
    stopSession,
    togglePause,
    isPaused,
    formattedTimeRemaining,
    progress,
  };
}
