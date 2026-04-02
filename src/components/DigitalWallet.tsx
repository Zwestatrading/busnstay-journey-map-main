import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CreditCard, Plus, Send, Eye, EyeOff, ArrowUp, ArrowDown, Wallet, TrendingUp, Clock, CheckCircle, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface Transaction {
  id: string;
  type: 'debit' | 'credit' | 'refund';
  description: string;
  amount: number;
  timestamp: Date;
  status: 'completed' | 'pending' | 'failed';
  relatedBooking?: string;
}

interface PaymentMethod {
  id: string;
  type: 'card' | 'mobile' | 'bank';
  name: string;
  lastDigits: string;
  isDefault: boolean;
  expiryDate?: string;
}

interface DigitalWalletProps {
  balance?: number;
  currency?: string;
  transactions?: Transaction[];
  paymentMethods?: PaymentMethod[];
  onAddFunds?: (amount: number, method: string) => void;
  onTransfer?: (recipient: string, amount: number) => void;
  onWithdraw?: (amount: number, method: string) => void;
}

const DigitalWallet = ({
  balance = 2850.50,
  currency = 'USD',
  transactions = [
    {
      id: '1',
      type: 'debit',
      description: 'Bus Booking - Lusaka to Livingstone',
      amount: 120.00,
      timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
      status: 'completed',
      relatedBooking: 'BN-2025-0012'
    },
    {
      id: '2',
      type: 'credit',
      description: 'Refund - Cancelled Booking',
      amount: 45.50,
      timestamp: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
      status: 'completed'
    },
    {
      id: '3',
      type: 'debit',
      description: 'Hotel Booking - Livingstone Suite',
      amount: 280.00,
      timestamp: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
      status: 'completed'
    },
    {
      id: '4',
      type: 'credit',
      description: 'Credit added via Mobile Money',
      amount: 500.00,
      timestamp: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      status: 'completed'
    },
    {
      id: '5',
      type: 'debit',
      description: 'Restaurant Booking - Taj Restaurant',
      amount: 65.00,
      timestamp: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
      status: 'completed'
    }
  ],
  paymentMethods = [
    {
      id: '1',
      type: 'card',
      name: 'Visa Card',
      lastDigits: '4242',
      isDefault: true,
      expiryDate: '12/26'
    },
    {
      id: '2',
      type: 'mobile',
      name: 'MTN Mobile Money',
      lastDigits: '0977123456',
      isDefault: false
    },
    {
      id: '3',
      type: 'bank',
      name: 'Zambia National Commercial Bank',
      lastDigits: '1234567890',
      isDefault: false
    }
  ],
  onAddFunds,
  onTransfer,
  onWithdraw
}: DigitalWalletProps) => {
  const [showBalance, setShowBalance] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview' | 'add' | 'transfer' | 'withdraw'>('overview');
  const [showAddFundsModal, setShowAddFundsModal] = useState(false);
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState('1');
  const [addAmount, setAddAmount] = useState('');
  const [showTransactionDetails, setShowTransactionDetails] = useState<string | null>(null);

  const getTransactionIcon = (type: string, status: string) => {
    if (type === 'credit' || type === 'refund') {
      return <ArrowDown className="w-5 h-5 text-green-400" />;
    }
    return <ArrowUp className="w-5 h-5 text-red-400" />;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'text-green-400';
      case 'pending': return 'text-yellow-400';
      case 'failed': return 'text-red-400';
      default: return 'text-gray-400';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return <CheckCircle className="w-4 h-4" />;
      case 'pending': return <Clock className="w-4 h-4" />;
      case 'failed': return <AlertCircle className="w-4 h-4" />;
      default: return null;
    }
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const formatTransactionDate = (timestamp: any): string => {
    try {
      const date = typeof timestamp === 'string' ? new Date(timestamp) : timestamp instanceof Date ? timestamp : new Date();
      return date.toLocaleDateString();
    } catch {
      return 'N/A';
    }
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const formatTransactionTime = (timestamp: any): string => {
    try {
      const date = typeof timestamp === 'string' ? new Date(timestamp) : timestamp instanceof Date ? timestamp : new Date();
      return date.toLocaleTimeString();
    } catch {
      return 'N/A';
    }
  };

  const totalSpentMonth = transactions
    .filter(t => {
      try {
        const transactionDate = typeof t.timestamp === 'string' ? new Date(t.timestamp) : t.timestamp instanceof Date ? t.timestamp : new Date();
        return t.type === 'debit' && transactionDate.getMonth() === new Date().getMonth();
      } catch {
        return false;
      }
    })
    .reduce((sum, t) => sum + t.amount, 0);

  const totalReceivedMonth = transactions
    .filter(t => {
      try {
        const transactionDate = typeof t.timestamp === 'string' ? new Date(t.timestamp) : t.timestamp instanceof Date ? t.timestamp : new Date();
        return (t.type === 'credit' || t.type === 'refund') && transactionDate.getMonth() === new Date().getMonth();
      } catch {
        return false;
      }
    })
    .reduce((sum, t) => sum + t.amount, 0);

  return (
    <div className="w-full space-y-8">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center mb-8"
      >
        <h1 className="text-4xl font-bold text-gradient mb-2">Digital Wallet</h1>
        <p className="text-gray-400">Manage your balance and make payments instantly</p>
      </motion.div>

      {/* Main Balance Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-gradient-to-br from-blue-600 to-indigo-700 rounded-2xl p-8 text-white border border-blue-400/20 relative overflow-hidden"
      >
        {/* Animated Background */}
        <motion.div
          animate={{ scale: [1, 1.1, 1], opacity: [0.2, 0.4, 0.2] }}
          transition={{ duration: 8, repeat: Infinity }}
          className="absolute top-0 right-0 w-72 h-72 rounded-full bg-white blur-3xl -z-0"
        />

        <div className="relative z-10">
          <div className="flex items-center justify-between mb-12">
            <div>
              <p className="text-blue-100 text-sm uppercase tracking-wider mb-2">Total Balance (Kwacha)</p>
              <div className="flex items-center gap-3">
                <h2 className="text-5xl font-bold">
                  {showBalance ? `K ${balance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : '••••••'}
                </h2>
                <button
                  onClick={() => setShowBalance(!showBalance)}
                  className="p-2 rounded-lg bg-white/10 hover:bg-white/20 transition"
                >
                  {showBalance ? (
                    <EyeOff className="w-6 h-6" />
                  ) : (
                    <Eye className="w-6 h-6" />
                  )}
                </button>
              </div>
            </div>
            <Wallet className="w-20 h-20 opacity-20" />
          </div>

          {/* Quick Action Buttons */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <Button
              onClick={() => setShowAddFundsModal(true)}
              className="bg-white text-blue-600 hover:bg-blue-50 border-0 font-semibold"
            >
              <Plus className="w-4 h-4 mr-2" />
              Add Funds
            </Button>
            <Button
              variant="ghost"
              className="border border-white/30 text-white hover:bg-white/10"
            >
              <Send className="w-4 h-4 mr-2" />
              Transfer
            </Button>
            <Button
              variant="ghost"
              className="border border-white/30 text-white hover:bg-white/10"
            >
              <ArrowUp className="w-4 h-4 mr-2" />
              Withdraw
            </Button>
          </div>

          {/* Wallet Card Design */}
          <div className="mt-8 pt-8 border-t border-white/20">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CreditCard className="w-6 h-6" />
                <span className="text-sm text-blue-100">Card ending in {paymentMethods.find(m => m.isDefault)?.lastDigits}</span>
              </div>
              <span className="text-sm text-blue-100">Default Payment Method</span>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {[
          { icon: ArrowUp, label: 'Spent This Month', value: `$${totalSpentMonth.toFixed(2)}`, color: 'from-red-600 to-red-700' },
          { icon: ArrowDown, label: 'Received This Month', value: `$${totalReceivedMonth.toFixed(2)}`, color: 'from-green-600 to-emerald-700' },
          { icon: TrendingUp, label: 'Monthly Avg Transaction', value: `$${(balance / 5).toFixed(2)}`, color: 'from-purple-600 to-indigo-700' }
        ].map((stat, i) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className={cn(
                'bg-gradient-to-br rounded-xl p-5 border border-white/10 backdrop-blur-sm',
                `${stat.color}`
              )}
            >
              <div className="flex items-center justify-between mb-3">
                <Icon className="w-6 h-6 text-white" />
              </div>
              <p className="text-gray-100 text-sm mb-1">{stat.label}</p>
              <p className="text-2xl font-bold text-white">{stat.value}</p>
            </motion.div>
          );
        })}
      </div>

      {/* Payment Methods */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm"
      >
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-white font-bold text-lg">Payment Methods</h3>
          <Button className="bg-blue-600 hover:bg-blue-700 text-white border-0 text-sm">
            <Plus className="w-4 h-4 mr-2" />
            Add Method
          </Button>
        </div>

        <div className="space-y-3">
          {paymentMethods.map((method, i) => (
            <motion.div
              key={method.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.1 }}
              className={cn(
                'p-4 rounded-lg border-2 transition-all cursor-pointer',
                method.isDefault
                  ? 'border-blue-500 bg-blue-900/20'
                  : 'border-white/10 bg-slate-800/30 hover:border-white/20'
              )}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={cn(
                    'w-12 h-12 rounded-lg flex items-center justify-center',
                    method.type === 'card' ? 'bg-blue-600' : method.type === 'mobile' ? 'bg-green-600' : 'bg-purple-600'
                  )}>
                    {method.type === 'card' && <CreditCard className="w-6 h-6 text-white" />}
                    {method.type === 'mobile' && <span className="text-white text-lg">📱</span>}
                    {method.type === 'bank' && <span className="text-white text-lg">🏦</span>}
                  </div>
                  <div>
                    <p className="text-white font-semibold">{method.name}</p>
                    <p className="text-gray-400 text-sm">•••• {method.lastDigits}</p>
                  </div>
                </div>
                <div className="text-right">
                  {method.isDefault && (
                    <span className="inline-block bg-blue-600 text-white text-xs px-3 py-1 rounded-full font-semibold">
                      Default
                    </span>
                  )}
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </motion.div>

      {/* Transaction History */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm"
      >
        <h3 className="text-white font-bold text-lg mb-6">Recent Transactions</h3>

        <div className="space-y-2">
          {transactions.map((transaction, i) => (
            <motion.button
              key={transaction.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              onClick={() => setShowTransactionDetails(
                showTransactionDetails === transaction.id ? null : transaction.id
              )}
              className="w-full p-4 rounded-lg border border-white/10 hover:bg-white/5 transition-all text-left"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4 flex-1 min-w-0">
                  <div className="w-12 h-12 rounded-lg bg-white/10 flex items-center justify-center flex-shrink-0">
                    {getTransactionIcon(transaction.type, transaction.status)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-white font-semibold text-sm truncate">{transaction.description}</p>
                    <p className="text-gray-400 text-xs">
                      {formatTransactionDate(transaction.timestamp)} at {formatTransactionTime(transaction.timestamp)}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-3 flex-shrink-0">
                  <div className="text-right">
                    <p className={cn(
                      'text-sm font-bold',
                      transaction.type === 'credit' || transaction.type === 'refund' ? 'text-green-400' : 'text-white'
                    )}>
                      {transaction.type === 'credit' || transaction.type === 'refund' ? '+' : '-'}${transaction.amount.toFixed(2)}
                    </p>
                    <div className={cn(
                      'flex items-center gap-1 text-xs',
                      getStatusColor(transaction.status)
                    )}>
                      {getStatusIcon(transaction.status)}
                      <span className="capitalize">{transaction.status}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Detailed View */}
              <AnimatePresence>
                {showTransactionDetails === transaction.id && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    className="mt-4 pt-4 border-t border-white/10"
                  >
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <p className="text-gray-400 mb-1">Transaction Type</p>
                        <p className="text-white font-semibold capitalize">{transaction.type}</p>
                      </div>
                      <div>
                        <p className="text-gray-400 mb-1">Status</p>
                        <p className={cn(
                          'font-semibold capitalize',
                          getStatusColor(transaction.status)
                        )}>
                          {transaction.status}
                        </p>
                      </div>
                      {transaction.relatedBooking && (
                        <>
                          <div>
                            <p className="text-gray-400 mb-1">Booking ID</p>
                            <p className="text-white font-semibold">{transaction.relatedBooking}</p>
                          </div>
                          <div>
                            <p className="text-gray-400 mb-1">Amount</p>
                            <p className="text-white font-semibold">${transaction.amount.toFixed(2)}</p>
                          </div>
                        </>
                      )}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.button>
          ))}
        </div>
      </motion.div>

      {/* Add Funds Modal */}
      <AnimatePresence>
        {showAddFundsModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50"
            onClick={() => setShowAddFundsModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-gradient-to-br from-slate-900 to-slate-950 border border-white/10 rounded-2xl p-8 max-w-md w-full mx-4 backdrop-blur-md"
            >
              <h2 className="text-2xl font-bold text-white mb-2">Add Funds</h2>
              <p className="text-gray-400 text-sm mb-6">Choose an amount and payment method</p>

              {/* Quick Amount Selection */}
              <div className="mb-6">
                <p className="text-gray-300 text-sm font-semibold mb-3">Quick Select</p>
                <div className="grid grid-cols-3 gap-3">
                  {['25', '50', '100'].map((amt) => (
                    <button
                      key={amt}
                      onClick={() => setAddAmount(amt)}
                      className={cn(
                        'py-3 rounded-lg font-bold transition-all',
                        addAmount === amt
                          ? 'bg-blue-600 text-white'
                          : 'bg-slate-800 text-gray-300 hover:bg-slate-700'
                      )}
                    >
                      ${amt}
                    </button>
                  ))}
                </div>
              </div>

              {/* Custom Amount */}
              <div className="mb-6">
                <label className="text-gray-300 text-sm font-semibold block mb-2">Custom Amount</label>
                <input
                  type="number"
                  value={addAmount}
                  onChange={(e) => setAddAmount(e.target.value)}
                  placeholder="Enter amount..."
                  className="input-premium w-full"
                />
              </div>

              {/* Payment Method Selection */}
              <div className="mb-6">
                <p className="text-gray-300 text-sm font-semibold mb-3">Payment Method</p>
                <div className="space-y-2">
                  {paymentMethods.map((method) => (
                    <label
                      key={method.id}
                      className={cn(
                        'flex items-center gap-3 p-3 rounded-lg border-2 cursor-pointer transition-all',
                        selectedPaymentMethod === method.id
                          ? 'border-blue-500 bg-blue-900/20'
                          : 'border-white/10 bg-slate-800/30 hover:border-white/20'
                      )}
                    >
                      <input
                        type="radio"
                        checked={selectedPaymentMethod === method.id}
                        onChange={() => setSelectedPaymentMethod(method.id)}
                        className="w-4 h-4 cursor-pointer"
                      />
                      <div className="flex-1">
                        <p className="text-white text-sm font-semibold">{method.name}</p>
                        <p className="text-gray-400 text-xs">•••• {method.lastDigits}</p>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex gap-3">
                <Button
                  onClick={() => {
                    onAddFunds?.(parseFloat(addAmount), selectedPaymentMethod);
                    setShowAddFundsModal(false);
                    setAddAmount('');
                  }}
                  disabled={!addAmount || parseFloat(addAmount) <= 0}
                  className="flex-1 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white border-0 disabled:opacity-50"
                >
                  <Plus className="w-4 h-4 mr-2" />
                  Add ${addAmount || '0'}
                </Button>
                <Button
                  onClick={() => setShowAddFundsModal(false)}
                  variant="ghost"
                  className="text-gray-300 hover:text-white"
                >
                  Cancel
                </Button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default DigitalWallet;
