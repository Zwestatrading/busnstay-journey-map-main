import { useState } from 'react';
import { motion } from 'framer-motion';
import { Calendar, Users, MapPin, CreditCard, Shield, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface SeatMap {
  row: number;
  col: number;
  available: boolean;
  price: number;
}

interface BookingOption {
  id: string;
  name: string;
  passengers: number;
  departureTime: string;
  arrivalTime: string;
  price: number;
  discount?: number;
  amenities: string[];
}

interface AdvancedBookingProps {
  from: string;
  to: string;
  date: string;
  passengers: number;
  bookingOptions?: BookingOption[];
  onBook?: (booking: any) => void;
}

const AdvancedBooking = ({
  from,
  to,
  date,
  passengers = 1,
  bookingOptions = [
    {
      id: '1',
      name: 'Express Service',
      passengers: 1,
      departureTime: '09:00 AM',
      arrivalTime: '05:00 PM',
      price: 45,
      amenities: ['WiFi', 'Air Conditioning', 'Refreshments']
    },
    {
      id: '2',
      name: 'Premium Comfort',
      passengers: 1,
      departureTime: '02:00 PM',
      arrivalTime: '10:00 PM',
      price: 65,
      discount: 10,
      amenities: ['WiFi', 'Premium Meals', 'Extra Legroom', 'USB Charger']
    },
    {
      id: '3',
      name: 'Night Service',
      passengers: 1,
      departureTime: '08:00 PM',
      arrivalTime: '06:00 AM+1',
      price: 35,
      amenities: ['WiFi', 'Sleeping Seat', 'Blanket']
    }
  ],
  onBook
}: AdvancedBookingProps) => {
  const [selectedOption, setSelectedOption] = useState<BookingOption | null>(bookingOptions[0]);
  const [selectedSeats, setSelectedSeats] = useState<number[]>([]);
  const [step, setStep] = useState<'options' | 'seats' | 'payment'>('options');
  const [paymentMethod, setPaymentMethod] = useState('card');

  const seatMatrix: SeatMap[] = Array.from({ length: 40 }, (_, i) => ({
    row: Math.floor(i / 4),
    col: i % 4,
    available: Math.random() > 0.3,
    price: selectedOption?.price || 0
  }));

  const handleSeatSelect = (index: number) => {
    if (seatMatrix[index].available && selectedSeats.length < passengers) {
      setSelectedSeats([...selectedSeats, index]);
    } else if (selectedSeats.includes(index)) {
      setSelectedSeats(selectedSeats.filter(s => s !== index));
    }
  };

  const totalPrice = (selectedOption?.price || 0) * (selectedOption?.passengers || 1);
  const discount = selectedOption?.discount ? (totalPrice * selectedOption.discount) / 100 : 0;
  const finalPrice = totalPrice - discount;

  return (
    <div className="w-full max-w-4xl mx-auto">
      <div className="mb-8">
        <div className="flex justify-between mb-4">
          {['Select Service', 'Choose Seats', 'Payment'].map((label, i) => (
            <div
              key={i}
              className={cn(
                'flex-1 text-center',
                i < ['options', 'seats', 'payment'].indexOf(step) && 'opacity-100',
                i === ['options', 'seats', 'payment'].indexOf(step) && 'opacity-100',
                i > ['options', 'seats', 'payment'].indexOf(step) && 'opacity-50'
              )}
            >
              <div className={cn(
                'w-8 h-8 rounded-full mx-auto mb-2 flex items-center justify-center font-bold',
                i <= ['options', 'seats', 'payment'].indexOf(step)
                  ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white'
                  : 'bg-slate-700 text-gray-400'
              )}>
                {i + 1}
              </div>
              <p className="text-xs text-gray-400">{label}</p>
            </div>
          ))}
        </div>
        <div className="h-1 bg-slate-700 rounded-full overflow-hidden">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${((['options', 'seats', 'payment'].indexOf(step) + 1) / 3) * 100}%` }}
            className="h-full bg-gradient-to-r from-blue-600 to-indigo-600"
          />
        </div>
      </div>

      <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-4 mb-6 backdrop-blur-sm">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 text-center">
          <div>
            <p className="text-gray-400 text-xs mb-1">From</p>
            <p className="text-white font-bold">{from}</p>
          </div>
          <div className="flex items-center justify-center">
            <div className="text-gray-600">➜</div>
          </div>
          <div>
            <p className="text-gray-400 text-xs mb-1">To</p>
            <p className="text-white font-bold">{to}</p>
          </div>
          <div>
            <p className="text-gray-400 text-xs mb-1">Date</p>
            <p className="text-white font-bold text-sm">{new Date(date).toLocaleDateString()}</p>
          </div>
          <div>
            <p className="text-gray-400 text-xs mb-1">Passengers</p>
            <p className="text-white font-bold">{passengers}</p>
          </div>
        </div>
      </div>

      {step === 'options' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-4"
        >
          {bookingOptions.map((option, i) => (
            <motion.button
              key={option.id}
              whileHover={{ scale: 1.01 }}
              onClick={() => {
                setSelectedOption(option);
                setSelectedSeats([]);
              }}
              className={cn(
                'w-full text-left p-5 rounded-xl border-2 transition-all',
                selectedOption?.id === option.id
                  ? 'border-blue-500 bg-blue-900/20'
                  : 'border-white/10 bg-slate-800/30 hover:border-white/20'
              )}
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h4 className="text-white font-bold text-lg">{option.name}</h4>
                  <p className="text-gray-400 text-sm">{option.departureTime} → {option.arrivalTime}</p>
                </div>
                <div className="text-right">
                  <div className="flex items-end gap-2">
                    {option.discount && (
                      <span className="text-red-400 line-through text-sm">${option.price}</span>
                    )}
                    <span className="text-2xl font-bold text-white">${option.price}</span>
                  </div>
                  {option.discount && (
                    <span className="text-xs text-green-400 font-semibold">-{option.discount}% OFF</span>
                  )}
                </div>
              </div>
              <div className="flex flex-wrap gap-2">
                {option.amenities.map((amenity) => (
                  <span key={amenity} className="text-xs bg-white/10 text-gray-300 px-2 py-1 rounded">
                    {amenity}
                  </span>
                ))}
              </div>
            </motion.button>
          ))}

          <Button
            onClick={() => setStep('seats')}
            className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white border-0 h-12 text-base"
          >
            Continue to Seat Selection
          </Button>
        </motion.div>
      )}

      {step === 'seats' && selectedOption && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-6"
        >
          <div>
            <h3 className="text-white font-bold mb-4">Select Your Seats</h3>
            <div className="bg-slate-800/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm">
              <div className="flex justify-center gap-8 mb-6">
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 bg-green-600 rounded" />
                  <span className="text-xs text-gray-400">Available</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 bg-blue-600 rounded" />
                  <span className="text-xs text-gray-400">Selected</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 bg-gray-600 rounded" />
                  <span className="text-xs text-gray-400">Booked</span>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-3 mb-6 max-w-sm mx-auto">
                {seatMatrix.map((seat, i) => (
                  <motion.button
                    key={i}
                    whileHover={seat.available ? { scale: 1.1 } : {}}
                    onClick={() => handleSeatSelect(i)}
                    disabled={!seat.available && !selectedSeats.includes(i)}
                    className={cn(
                      'w-full aspect-square rounded-lg font-bold text-xs relative overflow-hidden group',
                      selectedSeats.includes(i)
                        ? 'bg-gradient-to-br from-blue-500 to-indigo-600 text-white'
                        : seat.available
                        ? 'bg-green-600 text-white hover:bg-green-700'
                        : 'bg-gray-600 text-gray-400 cursor-not-allowed opacity-50'
                    )}
                  >
                    {String.fromCharCode(65 + seat.row)}{seat.col + 1}
                  </motion.button>
                ))}
              </div>

              {selectedSeats.length > 0 && (
                <div className="bg-blue-900/20 border border-blue-700/30 rounded-lg p-3 text-center">
                  <p className="text-blue-300 text-sm font-semibold">
                    Selected: {selectedSeats.map((s) => {
                      const seat = seatMatrix[s];
                      return `${String.fromCharCode(65 + seat.row)}${seat.col + 1}`;
                    }).join(', ')}
                  </p>
                </div>
              )}
            </div>
          </div>

          <div className="flex gap-3">
            <Button
              onClick={() => setStep('options')}
              variant="ghost"
              className="flex-1 text-gray-300 hover:text-white"
            >
              Back
            </Button>
            <Button
              onClick={() => setStep('payment')}
              disabled={selectedSeats.length !== passengers}
              className="flex-1 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white border-0 disabled:opacity-50"
            >
              Continue to Payment
            </Button>
          </div>
        </motion.div>
      )}

      {step === 'payment' && selectedOption && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-6"
        >
          <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm space-y-3">
            <h3 className="text-white font-bold">Booking Summary</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between text-gray-300">
                <span>{selectedOption.name}</span>
                <span className="text-white">${totalPrice}</span>
              </div>
              <div className="flex justify-between text-gray-300">
                <span>Seats: {passengers}</span>
                <span className="text-white">×${selectedOption.price}</span>
              </div>
              {discount > 0 && (
                <div className="flex justify-between text-green-400">
                  <span>Discount ({selectedOption.discount}%)</span>
                  <span>-${discount.toFixed(2)}</span>
                </div>
              )}
            </div>
            <div className="border-t border-white/10 pt-3 flex justify-between text-lg font-bold">
              <span className="text-white">Total</span>
              <span className="text-green-400">${finalPrice.toFixed(2)}</span>
            </div>
          </div>

          <div className="space-y-3">
            <h3 className="text-white font-bold">Payment Method</h3>
            {[
              { id: 'card', name: 'Credit/Debit Card', icon: '🏧' },
              { id: 'mobile', name: 'Mobile Money', icon: '📱' },
              { id: 'wallet', name: 'Digital Wallet', icon: '💳' }
            ].map((method) => (
              <label
                key={method.id}
                className={cn(
                  'flex items-center gap-3 p-4 rounded-lg border-2 cursor-pointer transition-all',
                  paymentMethod === method.id
                    ? 'border-blue-500 bg-blue-900/20'
                    : 'border-white/10 bg-slate-800/30 hover:border-white/20'
                )}
              >
                <input
                  type="radio"
                  checked={paymentMethod === method.id}
                  onChange={() => setPaymentMethod(method.id)}
                  className="w-4 h-4 cursor-pointer"
                />
                <span className="text-xl">{method.icon}</span>
                <span className="text-white font-semibold flex-1">{method.name}</span>
                <Shield className="w-5 h-5 text-green-400" />
              </label>
            ))}
          </div>

          <div className="bg-green-900/20 border border-green-700/30 rounded-lg p-4 flex gap-3">
            <Shield className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-green-300">All payments are encrypted and secure. Your information is protected.</p>
          </div>

          <div className="flex gap-3">
            <Button
              onClick={() => setStep('seats')}
              variant="ghost"
              className="flex-1 text-gray-300 hover:text-white"
            >
              Back
            </Button>
            <Button
              onClick={onBook}
              className="flex-1 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white border-0 h-12 text-base"
            >
              <CreditCard className="w-4 h-4 mr-2" />
              Complete Booking - ${finalPrice.toFixed(2)}
            </Button>
          </div>
        </motion.div>
      )}
    </div>
  );
};

export default AdvancedBooking;
