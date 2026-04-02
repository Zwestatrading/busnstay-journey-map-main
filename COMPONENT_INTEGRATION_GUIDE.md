# COMPONENT INTEGRATION GUIDE

This guide shows how to integrate the 8 new components into your BusNStay app.

---

## 1. Wrap App with ErrorBoundary

**File:** `src/App.tsx`

The ErrorBoundary should wrap your entire app for error handling and offline support.

```tsx
import { ErrorBoundary } from "@/components/ErrorBoundary";

const App = () => (
  <ErrorBoundary>
    <QueryClientProvider client={queryClient}>
      <DarkModeProvider>
        <AuthProvider>
          {/* ... rest of your app ... */}
        </AuthProvider>
      </DarkModeProvider>
    </QueryClientProvider>
  </ErrorBoundary>
);

export default App;
```

---

## 2. Add Mobile Bottom Navigation

**File:** `src/pages/Index.tsx` (or main layout)

Replace header navigation with mobile-friendly bottom nav:

```tsx
import { MobileBottomNav } from "@/components/MobileNav";
import { HomeIcon, MapIcon, UserIcon, SettingsIcon } from "lucide-react";
import { useLocation } from "react-router-dom";

export default function Index() {
  const location = useLocation();

  const navItems = [
    { path: "/", label: "Home", icon: <HomeIcon size={24} /> },
    { path: "/journey", label: "Journey", icon: <MapIcon size={24} /> },
    { path: "/account", label: "Account", icon: <UserIcon size={24} />, badge: 0 },
    { path: "/profile", label: "Profile", icon: <SettingsIcon size={24} /> }
  ];

  return (
    <div className="pb-20"> {/* Add padding for mobile nav */}
      <h1>Welcome to BusNStay</h1>
      {/* Your content */}
      
      {/* Add mobile navigation at bottom */}
      <MobileBottomNav items={navItems} />
    </div>
  );
}
```

---

## 3. Use Advanced Forms in Login/Registration

**File:** `src/pages/Auth.tsx`

Replace basic inputs with FormField components:

```tsx
import { FormField, LoadingButton } from "@/components/FormFields";
import { useState } from "react";

export default function AuthPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [emailError, setEmailError] = useState("");
  const [loading, setLoading] = useState(false);

  const validateEmail = (val: string) => {
    if (!val.includes("@")) return "Invalid email";
    return null;
  };

  const validatePassword = (val: string) => {
    if (val.length < 6) return "Must be 6+ characters";
    return null;
  };

  const handleLogin = async () => {
    setLoading(true);
    try {
      // Your login logic
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4 max-w-sm mx-auto p-4">
      <FormField
        label="Email"
        type="email"
        value={email}
        onChange={setEmail}
        error={emailError}
        validate={validateEmail}
        placeholder="your@email.com"
        required
      />

      <FormField
        label="Password"
        type="password"
        value={password}
        onChange={setPassword}
        validate={validatePassword}
        placeholder="Enter your password"
        required
        showPasswordToggle
      />

      <LoadingButton 
        loading={loading}
        onClick={handleLogin}
        className="w-full"
      >
        Login
      </LoadingButton>
    </div>
  );
}
```

---

## 4. Add Analytics Dashboard with Charts

**File:** `src/pages/Dashboard.tsx`

Add data visualizations to your dashboard:

```tsx
import { AdvancedBarChart, AdvancedLineChart, StatsGrid } from "@/components/DataVisualization";
import { TrendingUpIcon, UsersIcon, DollarSignIcon } from "lucide-react";

export default function Dashboard() {
  // Sample data - replace with real data from your DB
  const dailyStats = [
    { name: "Jan", value: 400 },
    { name: "Feb", value: 600 },
    { name: "Mar", value: 800 },
    { name: "Apr", value: 950 }
  ];

  const stats = [
    { 
      label: "Total Revenue", 
      value: "$12,400", 
      change: 15, 
      trend: "up",
      icon: <DollarSignIcon size={20} /> 
    },
    { 
      label: "Active Users", 
      value: "2,345", 
      change: 8, 
      trend: "up",
      icon: <UsersIcon size={20} /> 
    },
    { 
      label: "Growth Rate", 
      value: "23%", 
      change: 5, 
      trend: "up",
      icon: <TrendingUpIcon size={20} /> 
    }
  ];

  return (
    <div className="space-y-6 p-4">
      <h1 className="text-3xl font-bold">Dashboard</h1>

      {/* Statistics Grid */}
      <StatsGrid stats={stats} columns={3} />

      {/* Bar Chart */}
      <AdvancedBarChart
        data={dailyStats}
        title="Monthly Revenue"
        height={300}
      />

      {/* Line Chart */}
      <AdvancedLineChart
        data={dailyStats}
        title="User Growth Trend"
        height={300}
      />
    </div>
  );
}
```

---

## 5. Add User Profile with Settings

**File:** `src/pages/ProfileEnhanced.tsx` (or create new)

Implement the full profile system:

```tsx
import { 
  ProfileHeader, 
  PreferencesPanel, 
  SecurityPanel 
} from "@/components/UserProfile";
import { useState } from "react";
import { useAuth } from "@/contexts/AuthProvider";

export default function ProfilePage() {
  const { user } = useAuth();
  const [preferences, setPreferences] = useState({
    emailNotifications: true,
    smsNotifications: false,
    pushNotifications: true,
    publicProfile: true,
    allowMessages: true,
    shareLocation: false,
    theme: "dark",
    language: "en"
  });

  const profile = {
    name: user?.user_metadata?.full_name || "User",
    email: user?.email,
    phone: user?.user_metadata?.phone || "+1234567890",
    role: "Customer",
    avatar: user?.user_metadata?.avatar_url
  };

  const handleSavePreferences = async (newPrefs: any) => {
    setPreferences(newPrefs);
    // Save to database
  };

  const handleChangePassword = () => {
    // Show password change modal
  };

  const handleEnable2FA = () => {
    // Show 2FA setup modal
  };

  const handleLogoutAll = async () => {
    // Logout all sessions
  };

  return (
    <div className="max-w-2xl mx-auto p-4 space-y-6">
      <ProfileHeader 
        profile={profile}
        onEditClick={() => console.log("Edit profile")}
      />

      <div className="border-t pt-6">
        <h2 className="text-xl font-bold mb-4">Preferences</h2>
        <PreferencesPanel
          preferences={preferences}
          onSave={handleSavePreferences}
        />
      </div>

      <div className="border-t pt-6">
        <h2 className="text-xl font-bold mb-4">Security</h2>
        <SecurityPanel
          on2FAEnabled={user?.user_metadata?.twoFactorEnabled}
          onChangePassword={handleChangePassword}
          onEnable2FA={handleEnable2FA}
          onLogoutAll={handleLogoutAll}
        />
      </div>
    </div>
  );
}
```

---

## 6. Add Admin Data Table

**File:** `src/pages/AdminDashboard.tsx`

Implement the admin data table with search/sort/filter:

```tsx
import { AdminDataTable, BatchActions } from "@/components/AdminTools";
import { useState } from "react";
import { supabase } from "@/lib/supabase";

export default function AdminDashboard() {
  const [users, setUsers] = useState([]);
  const [selectedIds, setSelectedIds] = useState([]);

  // Load users from database
  React.useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    const { data } = await supabase
      .from("users")
      .select("*")
      .limit(100);
    
    setUsers(data || []);
  };

  const columns = [
    { key: "id", label: "ID", width: "80px" },
    { key: "email", label: "Email" },
    { key: "full_name", label: "Name" },
    { key: "role", label: "Role", width: "100px" },
    { 
      key: "created_at", 
      label: "Joined", 
      render: (date: string) => new Date(date).toLocaleDateString()
    }
  ];

  const handleDelete = async (id: string) => {
    await supabase.from("users").delete().eq("id", id);
    loadUsers();
  };

  const handleBatchDelete = async (ids: string[]) => {
    await supabase.from("users").delete().in("id", ids);
    loadUsers();
    setSelectedIds([]);
  };

  return (
    <div className="p-4 space-y-4">
      <h1 className="text-3xl font-bold">Users</h1>

      <AdminDataTable
        data={users}
        columns={columns}
        searchable
        sortable
        selectable
        onSelectChange={setSelectedIds}
        onDelete={handleDelete}
      />

      {selectedIds.length > 0 && (
        <BatchActions
          selectedIds={selectedIds}
          actions={[
            {
              label: "Delete",
              color: "danger",
              onClick: () => handleBatchDelete(selectedIds)
            }
          ]}
        />
      )}
    </div>
  );
}
```

---

## 7. Use Accessibility Hooks Throughout

Add to any page/component:

```tsx
import { 
  useScreenReaderAnnouncement,
  useKeyboardNavigation,
  useFocusTrap,
  usePrefersReducedMotion
} from "@/hooks/useAccessibility";

export default function MyComponent() {
  const { announce } = useScreenReaderAnnouncement();
  const listRef = useRef(null);

  // Announce when content loads
  React.useEffect(() => {
    announce("Content loaded successfully", "polite");
  }, [announce]);

  // Trap focus in modal
  useFocusTrap(listRef);

  // Handle keyboard navigation
  const { handleNavigate } = useKeyboardNavigation({
    onUpArrow: () => console.log("Previous"),
    onDownArrow: () => console.log("Next"),
  });

  // Respect motion preferences
  const prefersReduced = usePrefersReducedMotion();

  return (
    <div ref={listRef} role="list" onKeyDown={handleNavigate}>
      {/* Your list items */}
    </div>
  );
}
```

---

## 8. Use Animation Variants

Add smooth animations to your components:

```tsx
import { motion } from "framer-motion";
import { 
  pageVariants,
  containerVariants,
  cardVariants,
  Skeleton 
} from "@/utils/animationVariants";

export default function Page() {
  const [loaded, setLoaded] = useState(false);

  return (
    <motion.div
      variants={pageVariants}
      initial="hidden"
      animate="visible"
      exit="exit"
    >
      <h1 className="mb-6">My Page</h1>

      {!loaded ? (
        /* Show skeleton loaders while loading */
        <>
          <Skeleton width="100%" height="20px" count={3} />
        </>
      ) : (
        /* Animate in content when loaded */
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          {items.map((item) => (
            <motion.div
              key={item.id}
              variants={cardVariants}
              className="card"
            >
              {item.name}
            </motion.div>
          ))}
        </motion.div>
      )}
    </motion.div>
  );
}
```

---

## Component Import Path Reference

```tsx
// Forms
import { FormField, FormGroup, LoadingButton } from "@/components/FormFields";

// Mobile Navigation
import { MobileBottomNav, useMobileGestures } from "@/components/MobileNav";

// Charts & Data
import { 
  AdvancedBarChart,
  AdvancedLineChart,
  AdvancedPieChart,
  StatsGrid,
  ChartContainer
} from "@/components/DataVisualization";

// Profile & Settings
import { 
  ProfileHeader,
  SettingToggle,
  PreferencesPanel,
  SecurityPanel
} from "@/components/UserProfile";

// Admin Tools
import { AdminDataTable, BatchActions } from "@/components/AdminTools";

// Error Handling
import { 
  ErrorBoundary,
  OfflineFallback,
  useNetworkStatus,
  useRetry
} from "@/components/ErrorBoundary";

// Accessibility
import {
  useScreenReaderAnnouncement,
  useKeyboardNavigation,
  useFocusTrap,
  usePrefersReducedMotion,
  useLazyImage,
  usePerformanceMetrics
} from "@/hooks/useAccessibility";

// Animations
import {
  pageVariants,
  containerVariants,
  cardVariants,
  modalVariants,
  badgeVariants,
  rotationVariants,
  pulseVariants,
  slideVariants,
  bounceVariants,
  skeletonVariants,
  Skeleton
} from "@/utils/animationVariants";
```

---

## Migration Checklist

- [ ] Wrap App component with `ErrorBoundary`
- [ ] Add `MobileBottomNav` to main layout
- [ ] Replace form inputs with `FormField` component
- [ ] Add `StatsGrid` and charts to dashboard
- [ ] Integrate `ProfileHeader`, `PreferencesPanel`, `SecurityPanel` into profile page
- [ ] Add `AdminDataTable` to admin dashboard
- [ ] Use accessibility hooks in list/modal components
- [ ] Apply animation variants to page transitions
- [ ] Test on mobile device
- [ ] Build APK with `npm run build && npx cap sync android && npx cap build android`

---

## Type Definitions

All components are fully typed with TypeScript. Key types:

```tsx
// FormField
interface FormFieldProps {
  label: string;
  name: string;
  type?: "text" | "email" | "password" | "number" | ...;
  value: string;
  onChange: (value: string) => void;
  error?: string;
  validate?: (value: string) => string | null;
  required?: boolean;
  icon?: React.ReactNode;
  description?: string;
}

// AdminDataTable
interface AdminDataTableProps {
  data: Record<string, any>[];
  columns: {
    key: string;
    label: string;
    render?: (value: any) => ReactNode;
    width?: string;
  }[];
  searchable?: boolean;
  sortable?: boolean;
  selectable?: boolean;
  onSelectChange?: (ids: string[]) => void;
  onDelete?: (id: string) => void;
}

// StatsGrid
interface StatItem {
  label: string;
  value: string | number;
  change?: number;
  trend?: "up" | "down";
  icon?: React.ReactNode;
}
```

---

## Testing Integration

After integrating components, test:

1. **Forms:** Try validation, password toggle, loading state
2. **Mobile Nav:** Swipe left/right, long-press tabs
3. **Charts:** Hover tooltips, responsive resize
4. **Animations:** Check smooth transitions on page load
5. **Accessibility:** Tab through form, use screen reader
6. **Error Boundary:** Trigger error, check fallback UI
7. **Offline:** Disable network, check offline fallback
8. **Admin Table:** Search, sort, select, export rows

---

## Performance Tips

- Lazy load components that aren't immediately visible
- Use React.memo() for chart components
- Debounce search input (300ms)
- Virtualize long lists with react-virtual
- Use production build for performance testing

---

## Need Help?

Check these files for detailed information:
- `APK_BUILD_GUIDE.md` - Build instructions
- `COMPLETE_ITERATIONS_SUMMARY.md` - Feature overview
- `src/components/FormFields.tsx` - Form component source
- `src/components/DataVisualization.tsx` - Chart component source

---

**All components are ready to use! Following this guide will fully integrate the 8 new feature iterations into your app.** ✨

