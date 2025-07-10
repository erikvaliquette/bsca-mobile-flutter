# React Native to Flutter Migration Mapping

This document outlines how components, packages, and features from the React Native app will be implemented in Flutter.

## Component Mapping

| React Native Component | Flutter Equivalent | Notes |
|------------------------|-------------------|-------|
| `View` | `Container` or `Column`/`Row` | Basic layout components |
| `Text` | `Text` | Text display |
| `TextInput` | `TextField` | Text input fields |
| `ScrollView` | `SingleChildScrollView` | Scrollable container |
| `FlatList` | `ListView.builder` | Efficient list rendering |
| `Image` | `Image` | Image display |
| `TouchableOpacity` | `GestureDetector` with `InkWell` | Touch handling with feedback |
| `Modal` | `Dialog` or `BottomSheet` | Modal dialogs |
| `ActivityIndicator` | `CircularProgressIndicator` | Loading indicator |
| `SafeAreaView` | `SafeArea` | Safe area handling |
| `KeyboardAvoidingView` | `Scaffold` with resizeToAvoidBottomInset | Keyboard handling |

## Navigation Mapping

| React Native (React Navigation) | Flutter (go_router) | Notes |
|--------------------------------|---------------------|-------|
| `NavigationContainer` | `MaterialApp.router` with `GoRouter` | Root navigation container |
| `Stack Navigator` | `GoRoute` with `pageBuilder` | Stack-based navigation |
| `Tab Navigator` | `ShellRoute` with `BottomNavigationBar` | Tab-based navigation |
| `Drawer Navigator` | `ShellRoute` with `Drawer` | Drawer navigation |
| `navigation.navigate()` | `context.go()` | Navigate to a route |
| `navigation.push()` | `context.push()` | Push a route onto the stack |
| `navigation.goBack()` | `context.pop()` | Go back to previous route |
| `navigation.setParams()` | Pass parameters in route | Update route parameters |

## State Management Mapping

| React Native (Context API) | Flutter (Provider/Riverpod) | Notes |
|---------------------------|----------------------------|-------|
| `Context.Provider` | `ChangeNotifierProvider` | Provide state to widget tree |
| `useContext` | `Provider.of` or `Consumer` | Access provided state |
| `useState` | `StatefulWidget` with `setState` | Local component state |
| `useEffect` | `initState`/`didChangeDependencies`/`dispose` | Lifecycle methods |
| `useReducer` | `ChangeNotifier` with actions | Complex state logic |
| `UnreadContext` | Custom `MessagingProvider` | Messaging state management |

## API/Service Mapping

| React Native Implementation | Flutter Implementation | Notes |
|----------------------------|------------------------|-------|
| Supabase JS Client | Supabase Flutter | Database and authentication |
| Async Storage | Shared Preferences | Local storage |
| Expo SecureStore | Flutter Secure Storage | Secure storage |
| Expo Location | Geolocator | Location services |
| Expo ImagePicker | Image Picker | Image selection |
| React Native Chart Kit | FL Chart | Data visualization |
| React Native SVG | Flutter SVG | SVG rendering |
| Expo WebBrowser | url_launcher | Opening URLs |
| Expo Haptics | haptic_feedback | Haptic feedback |

## Feature-specific Mapping

### Messaging System
- Replace React Context with Provider for message state
- Implement Supabase real-time subscriptions for live updates
- Create custom widgets for message bubbles and read receipts
- Implement proper UUID handling to prevent parsing issues

### Authentication
- Use Supabase Flutter auth methods
- Create dedicated auth provider for state management
- Implement secure token storage

### Profile Management
- Create profile models and services
- Implement image upload functionality
- Build profile editing screens

### Travel Emissions Calculator
- Port calculation logic to Dart
- Implement charting with FL Chart
- Create location tracking service with Geolocator

### SDG Marketplace
- Create marketplace models and services
- Build UI components for marketplace items
- Implement filtering and search functionality
