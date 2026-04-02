import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle, Phone, MessageCircle, MapPin, User, X, Send } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface EmergencyContact {
  name: string;
  role: string;
  phone: string;
  type: 'police' | 'medical' | 'support' | 'personal';
}

interface EmergencySOSProps {
  userPhone?: string;
  userLocation?: string;
  emergencyContacts?: EmergencyContact[];
  onEmergencyAlert?: (type: string, message: string) => void;
}

const EmergencySOS = ({
  userPhone = '+1-555-0100',
  userLocation = 'Lusaka, Zambia',
  emergencyContacts = [
    { name: 'BusNStay Support', role: '24/7 Support Team', phone: '+260-970-123456', type: 'support' },
    { name: 'Zambia Police', role: 'Emergency', phone: '991', type: 'police' },
    { name: 'Emergency Medical', role: 'Ambulance', phone: '112', type: 'medical' }
  ],
  onEmergencyAlert
}: EmergencySOSProps) => {
  const [showModal, setShowModal] = useState(false);
  const [showChat, setShowChat] = useState(false);
  const [chatMessage, setChatMessage] = useState('');
  const [messages, setMessages] = useState<{ type: 'user' | 'support'; text: string }[]>([
    {
      type: 'support',
      text: 'Hello! How can we assist you today? Our support team is here 24/7.'
    }
  ]);

  const handleEmergencyPress = () => {
    setShowModal(true);
    onEmergencyAlert?.('sos-button', 'Emergency alert button pressed');
  };

  const handleSOS = (type: string) => {
    onEmergencyAlert?.(type, `Emergency alert: ${type}`);
    setShowModal(false);
  };

  const handleSendMessage = () => {
    if (chatMessage.trim()) {
      setMessages([
        ...messages,
        { type: 'user', text: chatMessage }
      ]);
      setChatMessage('');
      
      setTimeout(() => {
        setMessages(prev => [
          ...prev,
          { 
            type: 'support', 
            text: 'Thank you for reaching out. Our team will assist you shortly. Please stay safe.' 
          }
        ]);
      }, 1000);
    }
  };

  const getTypeColor = (type: string) => {
    switch(type) {
      case 'police': return 'from-red-600 to-red-700';
      case 'medical': return 'from-pink-600 to-pink-700';
      case 'support': return 'from-blue-600 to-blue-700';
      case 'personal': return 'from-purple-600 to-purple-700';
      default: return 'from-gray-600 to-gray-700';
    }
  };

  const getTypeIcon = (type: string) => {
    switch(type) {
      case 'police': return '🚨';
      case 'medical': return '🚑';
      case 'support': return '💬';
      case 'personal': return '👤';
      default: return '📞';
    }
  };

  return (
    <div className="fixed bottom-6 right-6 z-40 flex flex-col gap-4 items-end">
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        className="flex flex-col gap-3 items-end"
      >
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={() => setShowChat(!showChat)}
          className="w-14 h-14 rounded-full bg-gradient-to-br from-green-500 to-emerald-600 text-white shadow-lg flex items-center justify-center hover:shadow-xl transition-shadow"
        >
          <MessageCircle className="w-6 h-6" />
        </motion.button>

        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={handleEmergencyPress}
          className="w-16 h-16 rounded-full bg-gradient-to-br from-red-500 to-red-700 text-white shadow-2xl flex items-center justify-center hover:shadow-2xl transition-shadow animate-pulse"
        >
          <AlertTriangle className="w-7 h-7" />
        </motion.button>
      </motion.div>

      <AnimatePresence>
        {showChat && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            className="absolute bottom-24 right-0 w-80 h-96 bg-gradient-to-br from-slate-900 to-slate-950 border border-white/10 rounded-xl shadow-2xl flex flex-col overflow-hidden backdrop-blur-md"
          >
            <div className="bg-gradient-to-r from-green-600/20 to-emerald-600/20 border-b border-white/10 p-4 flex items-center justify-between">
              <div>
                <p className="text-white font-semibold">Live Support</p>
                <p className="text-xs text-green-400">● Online</p>
              </div>
              <button
                onClick={() => setShowChat(false)}
                className="text-gray-400 hover:text-white transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-3">
              {messages.map((msg, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={cn(
                    'max-w-xs px-3 py-2 rounded-lg',
                    msg.type === 'user'
                      ? 'ml-auto bg-blue-600 text-white rounded-br-none'
                      : 'bg-slate-800 text-gray-200 rounded-bl-none'
                  )}
                >
                  {msg.text}
                </motion.div>
              ))}
            </div>

            <div className="border-t border-white/10 p-3 flex gap-2">
              <input
                type="text"
                value={chatMessage}
                onChange={(e) => setChatMessage(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
                placeholder="Type message..."
                className="flex-1 bg-slate-800/50 border border-white/10 rounded-lg px-3 py-2 text-white text-sm placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500/50"
              />
              <button
                onClick={handleSendMessage}
                className="bg-green-600 hover:bg-green-700 text-white p-2 rounded-lg transition"
              >
                <Send className="w-4 h-4" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
            onClick={() => setShowModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-gradient-to-br from-slate-900 to-slate-950 border border-red-700/50 rounded-2xl p-6 max-w-md w-full mx-4 shadow-2xl"
            >
              <div className="text-center mb-6">
                <div className="w-16 h-16 rounded-full bg-red-900/30 border-2 border-red-500 mx-auto flex items-center justify-center mb-4">
                  <AlertTriangle className="w-8 h-8 text-red-500" />
                </div>
                <h2 className="text-2xl font-bold text-white mb-2">Emergency Assistance</h2>
                <p className="text-gray-300 text-sm">Choose how you'd like to get help</p>
              </div>

              <div className="bg-slate-800/50 border border-white/10 rounded-lg p-4 mb-4 space-y-2 text-sm">
                <div className="flex items-center gap-2 text-gray-300">
                  <MapPin className="w-4 h-4 text-red-400" />
                  <span>Location: {userLocation}</span>
                </div>
                <div className="flex items-center gap-2 text-gray-300">
                  <Phone className="w-4 h-4 text-blue-400" />
                  <span>Phone: {userPhone}</span>
                </div>
              </div>

              <div className="space-y-3 mb-6">
                {emergencyContacts.map((contact, i) => (
                  <motion.button
                    key={i}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => handleSOS(contact.type)}
                    className={cn(
                      'w-full bg-gradient-to-r rounded-lg p-3 text-left transition-all',
                      `${getTypeColor(contact.type)}`,
                      'hover:shadow-lg'
                    )}
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-2xl">{getTypeIcon(contact.type)}</span>
                      <div className="flex-1 min-w-0">
                        <p className="text-white font-semibold text-sm">{contact.name}</p>
                        <p className="text-white/80 text-xs">{contact.role}</p>
                      </div>
                      <Phone className="w-5 h-5 text-white flex-shrink-0" />
                    </div>
                  </motion.button>
                ))}
              </div>

              <Button
                onClick={() => setShowModal(false)}
                variant="ghost"
                className="w-full text-gray-300 hover:text-white"
              >
                Close
              </Button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default EmergencySOS;
