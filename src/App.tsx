import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import AuthProvider from "@/contexts/AuthProvider";
import { DarkModeProvider } from "@/contexts/DarkModeContext";
import { ToastProvider } from "@/contexts/ToastContext";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import SharedJourney from "./pages/SharedJourney";
import AuthPage from "./pages/Auth";
import Dashboard from "./pages/Dashboard";
import AccountDashboard from "./pages/AccountDashboard";
import RestaurantDashboard from "./pages/RestaurantDashboard";
import RiderDashboard from "./pages/RiderDashboard";
import TaxiDashboard from "./pages/TaxiDashboard";
import HotelDashboard from "./pages/HotelDashboard";
import AdminDashboard from "./pages/AdminDashboard";
import Verification from "./pages/Verification";
import VerificationStatus from "./pages/VerificationStatus";
import DeliveryTracker from "./pages/DeliveryTracker";
import PWAInstallPrompt from "./components/PWAInstallPrompt";
import MobileHeader from "./components/MobileHeader";
import OrderHistory from "./pages/OrderHistory";
import Favorites from "./pages/Favorites";
import SavedAddresses from "./pages/SavedAddresses";
import ProfileEnhanced from "./pages/ProfileEnhanced";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <DarkModeProvider>
      <AuthProvider>
        <ToastProvider>
          <TooltipProvider>
            <div className="overflow-x-hidden">
              <Toaster />
              <Sonner />
              <PWAInstallPrompt />
              <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
                <MobileHeader />
                <Routes>
                <Route path="/" element={<Index />} />
                <Route path="/auth" element={<AuthPage />} />
                <Route path="/dashboard" element={<Dashboard />} />
                <Route path="/account" element={<AccountDashboard />} />
                <Route path="/profile" element={<ProfileEnhanced />} />
                <Route path="/order-history" element={<OrderHistory />} />
                <Route path="/favorites" element={<Favorites />} />
                <Route path="/addresses" element={<SavedAddresses />} />
                <Route path="/restaurant" element={<RestaurantDashboard />} />
                <Route path="/rider" element={<RiderDashboard />} />
                <Route path="/rider/delivery/:jobId" element={<DeliveryTracker />} />
                <Route path="/taxi" element={<TaxiDashboard />} />
                <Route path="/hotel" element={<HotelDashboard />} />
                <Route path="/admin" element={<AdminDashboard />} />
                <Route path="/verification" element={<Verification />} />
                <Route path="/verification-status" element={<VerificationStatus />} />
                <Route path="/share/:shareCode" element={<SharedJourney />} />
                {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
        </div>
      </TooltipProvider>
        </ToastProvider>
      </AuthProvider>
    </DarkModeProvider>
  </QueryClientProvider>
);

export default App;
