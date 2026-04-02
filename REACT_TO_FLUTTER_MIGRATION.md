# BusNStay: React ↔ Flutter Code Comparison Guide

This guide shows how React code translates to Flutter code for common patterns.

---

## 1. Components & Widgets

### React Component
```typescript
// src/components/JourneyCard.tsx
import React from 'react';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface JourneyCardProps {
  journey: Journey;
  onSelect: (journey: Journey) => void;
}

export const JourneyCard: React.FC<JourneyCardProps> = ({
  journey,
  onSelect,
}) => {
  return (
    <div className="p-4 border rounded-lg hover:shadow-md transition-shadow">
      <div className="flex justify-between items-start">
        <div>
          <h3 className="font-bold text-lg">{journey.from}</h3>
          <p className="text-sm text-gray-600">{journey.departure}</p>
        </div>
        <Badge variant={journey.status === 'active' ? 'default' : 'secondary'}>
          {journey.status}
        </Badge>
      </div>
      <p className="mt-2 font-semibold">${journey.fare}</p>
      <button
        onClick={() => onSelect(journey)}
        className="mt-4 w-full bg-blue-600 text-white py-2 rounded"
      >
        Book Now
      </button>
    </div>
  );
};
```

### Flutter Widget (Equivalent)
```dart
// lib/widgets/journey_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config/theme.dart';
import '../models/journey.dart';

class JourneyCard extends StatelessWidget {
  final Journey journey;
  final VoidCallback onSelect;

  const JourneyCard({
    required this.journey,
    required this.onSelect,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.departurePoint,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      journey.departureTime.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Chip(
                  label: Text(journey.status),
                  backgroundColor: journey.status == 'active'
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'ZMW ${journey.fare.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Key Differences

| React | Flutter |
|-------|---------|
| `props` destructuring | Constructor parameters with `required` |
| `className` (Tailwind) | `style` parameters + `Theme.of()` |
| `onClick` | `onPressed` |
| Inline conditional: `{condition ? a : b}` | `condition ? a : b` or ternary |
| `<div>, <p>, <span>` | `Column`, `Row`, `Text`, `Container` |
| Component imports | Widget class definition |

---

## 2. State Management

### React (Context API)
```typescript
// src/contexts/AuthContext.tsx
import React, { createContext, useState } from 'react';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextType | undefined>(
  undefined
);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const login = async (email: string, password: string) => {
    setIsLoading(true);
    try {
      const response = await apiClient.post('/api/auth/login', {
        email,
        password,
      });
      setUser(response.data.user);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthContext.Provider value={{ user, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = React.useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};

// Usage in component
export const LoginForm = () => {
  const { login, isLoading } = useAuth();
  // ... form JSX
};
```

### Flutter (Riverpod)
```dart
// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

final authServiceProvider = Provider((ref) => AuthService());

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

final loginProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({String email, String password})>((ref, params) async {
  final authService = ref.watch(authServiceProvider);
  return authService.login(
    email: params.email,
    password: params.password,
  );
});

// Usage in widget
class LoginForm extends ConsumerWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginAsyncValue = ref.watch(loginProvider);

    return loginAsyncValue.when(
      data: (result) => Text('Logged in'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Key Differences

| React | Flutter |
|-------|---------|
| `useState` | `FutureProvider` / `StateNotifier` |
| `useContext` | `ref.watch()` |
| Context Provider wraps tree | ProviderScope wraps app |
| Manual re-render management | Automatic with `.when()` |
| Error/loading handled manually | Built-in `.when()` pattern |

---

## 3. API Calls

### React
```typescript
// src/services/JourneyService.ts
import { supabase } from '@/lib/supabase';

export const searchJourneys = async (
  from: string,
  to: string,
  date: Date
): Promise<Journey[]> => {
  const { data, error } = await supabase
    .from('journeys')
    .select()
    .eq('departure_point', from)
    .eq('destination_point', to)
    .gte('departure_time', date.toISOString());

  if (error) throw new Error(error.message);
  return data || [];
};

// Usage in component with React Query
import { useQuery } from '@tanstack/react-query';

export const JourneySearch = () => {
  const { data: journeys, isLoading, error } = useQuery({
    queryKey: ['journeys', from, to, date],
    queryFn: () => searchJourneys(from, to, date),
  });

  if (isLoading) return <Skeleton />;
  if (error) return <Error message={error.message} />;

  return journeys?.map((j) => <JourneyCard key={j.id} journey={j} />);
};
```

### Flutter
```dart
// lib/services/journey_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journey.dart';

class JourneyService {
  final SupabaseClient _supabase;

  JourneyService(this._supabase);

  Future<List<Journey>> searchJourneys({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    try {
      final response = await _supabase
          .from('journeys')
          .select()
          .eq('departure_point', from)
          .eq('destination_point', to)
          .gte('departure_time', date.toIso8601String());

      return (response as List)
          .map((e) => Journey.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search journeys: $e');
    }
  }
}

// Usage in widget with Riverpod
final journeySearchProvider = FutureProvider.family<
    List<Journey>,
    ({String from, String to, DateTime date})>((ref, params) async {
  final journeyService = ref.watch(journeyServiceProvider);
  return journeyService.searchJourneys(
    from: params.from,
    to: params.to,
    date: params.date,
  );
});

class JourneySearch extends ConsumerWidget {
  const JourneySearch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsyncValue = ref.watch(
      journeySearchProvider((
        from: 'Lusaka',
        to: 'Kitwe',
        date: DateTime.now(),
      )),
    );

    return journeyAsyncValue.when(
      data: (journeys) => ListView.builder(
        itemCount: journeys.length,
        itemBuilder: (context, index) =>
            JourneyCard(journey: journeys[index], onSelect: () {}),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

---

## 4. Forms & Validation

### React
```typescript
// src/pages/auth/RegisterScreen.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';

const registerSchema = z
  .object({
    email: z.string().email('Invalid email'),
    password: z.string().min(8, 'Min 8 characters'),
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

type RegisterFormData = z.infer<typeof registerSchema>;

export const RegisterScreen = () => {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
  });

  const onSubmit = async (data: RegisterFormData) => {
    // Handle registration
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} placeholder="Email" />
      {errors.email && <span>{errors.email.message}</span>}

      <input
        {...register('password')}
        type="password"
        placeholder="Password"
      />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit">Register</button>
    </form>
  );
};
```

### Flutter
```dart
// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Email is required';
    if (!value!.contains('@')) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) return 'Password is required';
    if (value!.length < 8) return 'Min 8 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) return 'Confirm password is required';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle registration
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(hintText: 'Email'),
            validator: _validateEmail,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(hintText: 'Password'),
            obscureText: true,
            validator: _validatePassword,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(hintText: 'Confirm Password'),
            obscureText: true,
            validator: _validateConfirmPassword,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleSubmit,
            child: Text('Register'),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Routing

### React
```typescript
// src/App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { LoginPage } from '@/pages/LoginPage';
import { DashboardPage } from '@/pages/DashboardPage';
import ProtectedRoute from '@/components/ProtectedRoute';

export const App = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  );
};

// Navigation
import { useNavigate } from 'react-router-dom';

const MyComponent = () => {
  const navigate = useNavigate();
  return (
    <button onClick={() => navigate('/dashboard')}>Go to Dashboard</button>
  );
};
```

### Flutter
```dart
// lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const BusNStayApp());
}

class BusNStayApp extends StatelessWidget {
  const BusNStayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusNStay',
      theme: ThemeData.light(),
      home: const HomePage(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

// Navigation
class MyComponent extends StatelessWidget {
  const MyComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/dashboard');
        // Or: Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardScreen()))
      },
      child: Text('Go to Dashboard'),
    );
  }
}
```

---

## 6. Lists & Iteration

### React
```typescript
// Rendering lists
{journeys.map((journey) => (
  <JourneyCard key={journey.id} journey={journey} />
))}

// Conditional rendering
{isLoading ? (
  <Skeleton />
) : error ? (
  <ErrorComponent error={error} />
) : (
  <JourneyList journeys={journeys} />
)}

// Array operations
const filtered = journeys.filter((j) => j.price < 100);
const mapped = journeys.map((j) => ({...j, discounted: true}));
const sorted = journeys.sort((a, b) => a.price - b.price);
```

### Flutter
```dart
// Rendering lists
ListView.builder(
  itemCount: journeys.length,
  itemBuilder: (context, index) => JourneyCard(
    journey: journeys[index],
  ),
)

// Conditional rendering
if (isLoading) {
  return SkeletonLoader();
} else if (hasError) {
  return ErrorComponent(error: error);
} else {
  return JourneyList(journeys: journeys);
}

// Using ternary for simpler cases
isLoading ? const CircularProgressIndicator() : JourneyList(journeys)

// Array operations
final filtered = journeys.where((j) => j.fare < 100).toList();
final mapped = journeys.map((j) => {...j, discounted: true}).toList();
final sorted = journeys..sort((a, b) => a.fare.compareTo(b.fare));
```

---

## 7. HTTP Requests

### React with Axios
```typescript
// src/lib/apiClient.ts
import axios from 'axios';

const apiClient = axios.create({
  baseURL: 'https://ksepddxhvfkjfvnaervh.supabase.co',
  timeout: 10000,
});

// Add interceptor for auth token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const getJourneys = async () => {
  const response = await apiClient.get('/rest/v1/journeys');
  return response.data;
};
```

### Flutter with Dio
```dart
// lib/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late Dio _dio;
  late SharedPreferences _prefs;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://ksepddxhvfkjfvnaervh.supabase.co',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Add interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        _prefs = await SharedPreferences.getInstance();
        final token = _prefs.getString('authToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<List<Journey>> getJourneys() async {
    final response = await _dio.get('/rest/v1/journeys');
    return (response.data as List)
        .map((e) => Journey.fromJson(e))
        .toList();
  }
}
```

---

## Summary

| Concept | React | Flutter |
|---------|-------|---------|
| **Components** | Function/Class Components | Stateless/StatefulWidget |
| **Props** | Function parameters | Constructor parameters |
| **Styling** | CSS/Tailwind | Theme/Style properties |
| **State** | useState/Context | StateNotifier/Riverpod |
| **Lists** | .map() | ListView.builder() |
| **Conditionals** | Ternary/&&/\|\| | if-else/.when() |
| **Forms** | react-hook-form | Form + TextFormField |
| **HTTP** | Axios/React Query | Dio/Riverpod |
| **Routing** | React Router | Navigator/Routes |
| **Navigation** | useNavigate() | Navigator.push() |

**Remember**: Flutter uses explicit widget tree instead of HTML/JSX. Instead of thinking in DOM elements, think in widgets that compose vertically and horizontally.
