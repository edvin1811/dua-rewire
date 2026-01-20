import { Tabs } from 'expo-router';
import { View, Pressable, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, Radius } from '@/constants/theme';
import * as Haptics from 'expo-haptics';

type TabIconProps = {
  focused: boolean;
  color: string;
  size: number;
};

function TabBarIcon({ name, focused }: { name: keyof typeof Ionicons.glyphMap; focused: boolean }) {
  return (
    <View
      className={`items-center justify-center rounded-md px-4 py-2 ${
        focused ? 'bg-success/20' : ''
      }`}
    >
      <Ionicons
        name={name}
        size={24}
        color={focused ? Colors.success.DEFAULT : Colors.dark.textTertiary}
      />
    </View>
  );
}

function CustomTabBar({ state, descriptors, navigation }: any) {
  return (
    <View className="absolute bottom-0 left-0 right-0 px-md pb-sm">
      <View className="flex-row items-center justify-around bg-card rounded-xl py-sm border border-border">
        {state.routes.map((route: any, index: number) => {
          const { options } = descriptors[route.key];
          const isFocused = state.index === index;

          const onPress = () => {
            Haptics.selectionAsync();
            const event = navigation.emit({
              type: 'tabPress',
              target: route.key,
              canPreventDefault: true,
            });

            if (!isFocused && !event.defaultPrevented) {
              navigation.navigate(route.name);
            }
          };

          const iconName = getIconName(route.name, isFocused);

          return (
            <Pressable
              key={route.key}
              onPress={onPress}
              className="flex-1 items-center py-xs"
            >
              <View
                className={`items-center justify-center rounded-lg px-lg py-sm ${
                  isFocused ? 'bg-success/15' : ''
                }`}
              >
                <Ionicons
                  name={iconName}
                  size={24}
                  color={isFocused ? Colors.success.DEFAULT : Colors.dark.textTertiary}
                />
              </View>
              <Text
                className={`text-caption mt-xxs ${
                  isFocused ? 'text-success font-semibold' : 'text-text-tertiary'
                }`}
              >
                {getTabLabel(route.name)}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function getIconName(routeName: string, focused: boolean): keyof typeof Ionicons.glyphMap {
  switch (routeName) {
    case 'index':
      return focused ? 'home' : 'home-outline';
    case 'insights':
      return focused ? 'bar-chart' : 'bar-chart-outline';
    case 'focus':
      return focused ? 'shield-checkmark' : 'shield-checkmark-outline';
    case 'profile':
      return focused ? 'person' : 'person-outline';
    default:
      return 'help-circle-outline';
  }
}

function getTabLabel(routeName: string): string {
  switch (routeName) {
    case 'index':
      return 'Home';
    case 'insights':
      return 'Insights';
    case 'focus':
      return 'Focus';
    case 'profile':
      return 'Profile';
    default:
      return routeName;
  }
}

export default function TabsLayout() {
  return (
    <View className="flex-1 bg-background">
      <Tabs
        tabBar={(props) => <CustomTabBar {...props} />}
        screenOptions={{
          headerShown: false,
        }}
      >
        <Tabs.Screen name="index" />
        <Tabs.Screen name="insights" />
        <Tabs.Screen name="focus" />
        <Tabs.Screen name="profile" />
      </Tabs>
    </View>
  );
}
