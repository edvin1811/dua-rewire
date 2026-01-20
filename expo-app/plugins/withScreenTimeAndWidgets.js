const { withPlugins, withXcodeProject, withInfoPlist, withAndroidManifest, withEntitlementsPlist } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

// iOS: Add Screen Time and Widget capabilities
function withiOSScreenTimeCapability(config) {
  return withEntitlementsPlist(config, (config) => {
    // Family Controls entitlement for Screen Time API
    config.modResults['com.apple.developer.family-controls'] = true;

    // App Groups for sharing data between app and widget
    config.modResults['com.apple.security.application-groups'] = [
      `group.${config.ios?.bundleIdentifier || 'com.unwire.focus'}`,
    ];

    return config;
  });
}

function withiOSInfoPlist(config) {
  return withInfoPlist(config, (config) => {
    // Required for Screen Time API
    config.modResults.NSFamilyControlsUsageDescription =
      'Unwire needs access to Screen Time to help you track and manage your app usage for better focus.';

    // Background modes for monitoring
    config.modResults.UIBackgroundModes = [
      ...(config.modResults.UIBackgroundModes || []),
      'processing',
      'fetch',
    ];

    return config;
  });
}

// Android: Add UsageStats permission
function withAndroidUsageStats(config) {
  return withAndroidManifest(config, (config) => {
    const mainApplication = config.modResults.manifest.application?.[0];

    // Add PACKAGE_USAGE_STATS permission
    if (!config.modResults.manifest['uses-permission']) {
      config.modResults.manifest['uses-permission'] = [];
    }

    const permissions = config.modResults.manifest['uses-permission'];

    // Add required permissions
    const requiredPermissions = [
      'android.permission.PACKAGE_USAGE_STATS',
      'android.permission.QUERY_ALL_PACKAGES',
      'android.permission.RECEIVE_BOOT_COMPLETED',
      'android.permission.FOREGROUND_SERVICE',
    ];

    requiredPermissions.forEach((permission) => {
      if (!permissions.find((p) => p.$?.['android:name'] === permission)) {
        permissions.push({
          $: { 'android:name': permission },
        });
      }
    });

    // Add widget receiver and service
    if (mainApplication) {
      if (!mainApplication.receiver) {
        mainApplication.receiver = [];
      }

      // Widget provider receiver
      mainApplication.receiver.push({
        $: {
          'android:name': '.widget.FocusWidgetProvider',
          'android:exported': 'true',
        },
        'intent-filter': [
          {
            action: [{ $: { 'android:name': 'android.appwidget.action.APPWIDGET_UPDATE' } }],
          },
        ],
        'meta-data': [
          {
            $: {
              'android:name': 'android.appwidget.provider',
              'android:resource': '@xml/focus_widget_info',
            },
          },
        ],
      });

      // Usage stats service
      if (!mainApplication.service) {
        mainApplication.service = [];
      }

      mainApplication.service.push({
        $: {
          'android:name': '.usagestats.UsageStatsService',
          'android:exported': 'false',
        },
      });
    }

    return config;
  });
}

module.exports = (config) => {
  return withPlugins(config, [
    withiOSScreenTimeCapability,
    withiOSInfoPlist,
    withAndroidUsageStats,
  ]);
};
