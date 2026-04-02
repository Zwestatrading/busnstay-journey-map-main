/**
 * Demo Mode - Bypass Supabase for testing
 * Creates mock user data in localStorage
 */

export interface DemoUser {
  id: string;
  email: string;
  role: string;
}

export interface DemoProfile {
  user_id: string;
  full_name: string;
  role: string;
  email: string;
  assigned_station_id?: string;
  is_approved?: boolean;
  total_trips?: number;
  phone?: string;
}

const DEMO_MODE_KEY = 'busnstay_demo_mode';
const DEMO_USER_KEY = 'busnstay_demo_user';
const DEMO_PROFILE_KEY = 'busnstay_demo_profile';

// Custom event for demo mode changes
const DEMO_MODE_CHANGED = 'busnstay_demo_mode_changed';

export const demoAuthService = {
  // Enable demo mode
  enableDemoMode: (email: string, role: string = 'passenger', fullName: string = 'Demo User') => {
    const demoUserId = `demo_${Math.random().toString(36).substr(2, 9)}`;
    
    const user: DemoUser = {
      id: demoUserId,
      email,
      role
    };
    
    // Generate a demo station ID for riders
    const demoStationId = role === 'rider' ? 'station_lusaka_main_' + demoUserId.slice(5) : undefined;
    
    const profile: DemoProfile = {
      user_id: demoUserId,
      full_name: fullName,
      role,
      email,
      assigned_station_id: demoStationId,
      is_approved: true,
      total_trips: role === 'rider' ? Math.floor(Math.random() * 150) : 0,
      phone: '+260970000123'
    };

    localStorage.setItem(DEMO_MODE_KEY, 'true');
    localStorage.setItem(DEMO_USER_KEY, JSON.stringify(user));
    localStorage.setItem(DEMO_PROFILE_KEY, JSON.stringify(profile));

    // Dispatch event to notify listeners immediately
    window.dispatchEvent(new CustomEvent(DEMO_MODE_CHANGED, { detail: { enabled: true } }));

    return { user, profile };
  },

  // Disable demo mode
  disableDemoMode: () => {
    localStorage.removeItem(DEMO_MODE_KEY);
    localStorage.removeItem(DEMO_USER_KEY);
    localStorage.removeItem(DEMO_PROFILE_KEY);
    
    // Dispatch event to notify listeners immediately
    window.dispatchEvent(new CustomEvent(DEMO_MODE_CHANGED, { detail: { enabled: false } }));
  },

  // Subscribe to demo mode changes
  onDemoModeChange: (callback: (isDemoMode: boolean) => void) => {
    const handler = (event: Event) => {
      const customEvent = event as CustomEvent;
      callback(customEvent.detail.enabled);
    };
    window.addEventListener(DEMO_MODE_CHANGED, handler);
    return () => window.removeEventListener(DEMO_MODE_CHANGED, handler);
  },

  // Check if demo mode is active
  isDemoMode: (): boolean => {
    return localStorage.getItem(DEMO_MODE_KEY) === 'true';
  },

  // Get demo user
  getDemoUser: (): DemoUser | null => {
    const data = localStorage.getItem(DEMO_USER_KEY);
    return data ? JSON.parse(data) : null;
  },

  // Get demo profile
  getDemoProfile: (): DemoProfile | null => {
    const data = localStorage.getItem(DEMO_PROFILE_KEY);
    return data ? JSON.parse(data) : null;
  },

  // Create test loyalty data
  createTestLoyaltyData: () => {
    const user = demoAuthService.getDemoUser();
    if (!user) return null;

    return {
      user_id: user.id,
      current_points: 2450,
      total_points_earned: 5230,
      total_points_redeemed: 2780,
      tier: 'silver',
      referral_code: `REF_${user.id.toUpperCase().slice(0, 8)}`,
      referral_count: 3,
      created_at: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000).toISOString(),
      updated_at: new Date().toISOString(),
      last_activity: new Date().toISOString()
    };
  },

  // Create test wallet data
  createTestWalletData: () => {
    const user = demoAuthService.getDemoUser();
    if (!user) return null;

    return {
      id: `wallet_${user.id}`,
      user_id: user.id,
      balance: '2850.50',
      currency: 'ZMW',
      wallet_status: 'active',
      created_at: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000).toISOString(),
      updated_at: new Date().toISOString(),
      last_activity: new Date().toISOString(),
      metadata: {}
    };
  },

  // Create test transactions
  createTestTransactions: () => {
    const user = demoAuthService.getDemoUser();
    const wallet = demoAuthService.createTestWalletData();
    if (!user || !wallet) return [];

    const now = Date.now();
    return [
      {
        id: 'txn_001',
        wallet_id: wallet.id,
        type: 'debit',
        amount: '120.00',
        description: 'Bus Booking - Lusaka to Livingstone',
        status: 'completed',
        related_booking_id: 'BN-2025-0012',
        transaction_reference: 'TXN_001',
        failure_reason: null,
        created_at: new Date(now - 2 * 24 * 60 * 60 * 1000).toISOString(),
        completed_at: new Date(now - 2 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      },
      {
        id: 'txn_002',
        wallet_id: wallet.id,
        type: 'credit',
        amount: '45.50',
        description: 'Refund - Cancelled Booking',
        status: 'completed',
        related_booking_id: null,
        transaction_reference: 'TXN_002',
        failure_reason: null,
        created_at: new Date(now - 3 * 24 * 60 * 60 * 1000).toISOString(),
        completed_at: new Date(now - 3 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      },
      {
        id: 'txn_003',
        wallet_id: wallet.id,
        type: 'debit',
        amount: '280.00',
        description: 'Hotel Booking - Livingstone Suite',
        status: 'completed',
        related_booking_id: null,
        transaction_reference: 'TXN_003',
        failure_reason: null,
        created_at: new Date(now - 5 * 24 * 60 * 60 * 1000).toISOString(),
        completed_at: new Date(now - 5 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      },
      {
        id: 'txn_004',
        wallet_id: wallet.id,
        type: 'credit',
        amount: '500.00',
        description: 'Credit added via Mobile Money',
        status: 'completed',
        related_booking_id: null,
        transaction_reference: 'TXN_004',
        failure_reason: null,
        created_at: new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString(),
        completed_at: new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      },
      {
        id: 'txn_005',
        wallet_id: wallet.id,
        type: 'debit',
        amount: '65.00',
        description: 'Restaurant Booking - Taj Restaurant',
        status: 'completed',
        related_booking_id: null,
        transaction_reference: 'TXN_005',
        failure_reason: null,
        created_at: new Date(now - 10 * 24 * 60 * 60 * 1000).toISOString(),
        completed_at: new Date(now - 10 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      }
    ];
  },

  // Create test loyalty transactions
  createTestLoyaltyTransactions: () => {
    const user = demoAuthService.getDemoUser();
    if (!user) return [];

    const now = Date.now();
    return [
      {
        id: 'loy_001',
        user_id: user.id,
        type: 'earning',
        points: 240,
        description: 'Earned from booking BN-2025-0012',
        related_booking_id: 'BN-2025-0012',
        related_referral_code: null,
        expires_at: null,
        created_at: new Date(now - 2 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      },
      {
        id: 'loy_002',
        user_id: user.id,
        type: 'redemption',
        points: -1000,
        description: 'Redeemed: Free Ride voucher',
        related_booking_id: null,
        related_referral_code: null,
        expires_at: null,
        created_at: new Date(now - 5 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: { reward_id: 'free-ride-50' }
      },
      {
        id: 'loy_003',
        user_id: user.id,
        type: 'referral',
        points: 500,
        description: 'Referral bonus from friend signup',
        related_booking_id: null,
        related_referral_code: 'REF_FRIEND123',
        expires_at: null,
        created_at: new Date(now - 8 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      },
      {
        id: 'loy_004',
        user_id: user.id,
        type: 'earning',
        points: 180,
        description: 'Earned from booking BN-2025-0011',
        related_booking_id: 'BN-2025-0011',
        related_referral_code: null,
        expires_at: null,
        created_at: new Date(now - 12 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      },
      {
        id: 'loy_005',
        user_id: user.id,
        type: 'bonus',
        points: 200,
        description: 'Birthday bonus',
        related_booking_id: null,
        related_referral_code: null,
        expires_at: null,
        created_at: new Date(now - 30 * 24 * 60 * 60 * 1000).toISOString(),
        metadata: {}
      }
    ];
  }
};

export default demoAuthService;
