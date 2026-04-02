import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.busnstay.app',
  appName: 'BusNStay',
  webDir: 'dist',
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '#1a2744',
      showSpinner: false,
      logoWidth: 200,
      logoHeight: 200,
      splashFullScreen: true,
    },
    Geolocation: {
      permissions: ['location'],
    },
  },
  // Use local dist folder for mobile app
  // server: {
  //   url: 'https://busnstay-journey-map-main.vercel.app',
  //   cleartext: false,
  // },
};

export default config;
