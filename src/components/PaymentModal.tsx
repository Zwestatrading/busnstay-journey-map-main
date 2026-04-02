import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import {
  CreditCard, Smartphone, Building2, Phone,
  CheckCircle2, Loader2, X, ArrowRight
} from 'lucide-react';
import {
  initiatePayment,
  getAvailablePaymentMethods,
  formatCurrency,
  type InitiatePaymentParams,
  type PaymentMethod,
} from '@/services/paymentService';
import { useToast } from '@/hooks/use-toast';

interface PaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  amount: number;
  description: string;
  bookingId?: string;
  orderId?: string;
  customerEmail: string;
  customerName: string;
  customerPhone?: string;
  onPaymentSuccess?: (txRef: string) => void;
  onPaymentError?: (error: string) => void;
}

const methodIcons: Record<string, React.ReactNode> = {
  mobile_money: <Smartphone className="h-5 w-5" />,
  card: <CreditCard className="h-5 w-5" />,
  bank_transfer: <Building2 className="h-5 w-5" />,
  ussd: <Phone className="h-5 w-5" />,
};

type Step = 'method' | 'details' | 'processing' | 'success';

export const PaymentModal = ({
  isOpen,
  onClose,
  amount,
  description,
  bookingId,
  orderId,
  customerEmail,
  customerName,
  customerPhone,
  onPaymentSuccess,
  onPaymentError,
}: PaymentModalProps) => {
  const { toast } = useToast();
  const [step, setStep] = useState<Step>('method');
  const [selectedMethod, setSelectedMethod] = useState<PaymentMethod>('mobile_money');
  const [cardNumber, setCardNumber] = useState('');
  const [cardExpiry, setCardExpiry] = useState('');
  const [cardCvv, setCardCvv] = useState('');
  const [phoneNumber, setPhoneNumber] = useState(customerPhone || '');
  const [processing, setProcessing] = useState(false);
  const [txRef, setTxRef] = useState('');

  const methods = getAvailablePaymentMethods();
  const platformFee = amount * 0.10;
  const totalAmount = amount + platformFee;

  const resetState = () => {
    setStep('method');
    setSelectedMethod('mobile_money');
    setCardNumber('');
    setCardExpiry('');
    setCardCvv('');
    setProcessing(false);
    setTxRef('');
  };

  const handleClose = () => {
    resetState();
    onClose();
  };

  const handleProceed = () => {
    if (selectedMethod === 'card') {
      setStep('details');
    } else {
      handlePayment();
    }
  };

  const handlePayment = async () => {
    setStep('processing');
    setProcessing(true);

    try {
      const params: InitiatePaymentParams = {
        amount: totalAmount,
        paymentMethod: selectedMethod,
        description,
        bookingId,
        orderId,
        customerEmail,
        customerName,
        customerPhone: phoneNumber || customerPhone,
        metadata: {
          original_amount: amount,
          platform_fee: platformFee,
        },
      };

      const result = await initiatePayment(params);

      if (result.success && result.paymentLink) {
        setTxRef(result.txRef || '');
        // Redirect to Flutterwave checkout
        window.open(result.paymentLink, '_blank');
        setStep('success');
        onPaymentSuccess?.(result.txRef || '');
      } else {
        throw new Error(result.error || 'Payment initiation failed');
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Payment failed';
      toast({ title: errorMsg, variant: 'destructive' });
      onPaymentError?.(errorMsg);
      setStep('method');
    } finally {
      setProcessing(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && handleClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>
            {step === 'method' && 'Choose Payment Method'}
            {step === 'details' && 'Card Details'}
            {step === 'processing' && 'Processing Payment'}
            {step === 'success' && 'Payment Initiated'}
          </DialogTitle>
          <DialogDescription>
            {step === 'method' && `Pay ${formatCurrency(totalAmount)} for ${description}`}
            {step === 'details' && 'Enter your card information securely'}
            {step === 'processing' && 'Please wait while we process your payment...'}
            {step === 'success' && 'Your payment has been initiated successfully'}
          </DialogDescription>
        </DialogHeader>

        <AnimatePresence mode="wait">
          {/* Step 1: Select Payment Method */}
          {step === 'method' && (
            <motion.div key="method" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <div className="space-y-4">
                {/* Amount Breakdown */}
                <Card className="bg-gray-50">
                  <CardContent className="pt-4 pb-4">
                    <div className="space-y-1 text-sm">
                      <div className="flex justify-between">
                        <span>Subtotal</span>
                        <span>{formatCurrency(amount)}</span>
                      </div>
                      <div className="flex justify-between text-gray-500">
                        <span>Platform Fee (10%)</span>
                        <span>{formatCurrency(platformFee)}</span>
                      </div>
                      <div className="flex justify-between font-bold text-base pt-1 border-t">
                        <span>Total</span>
                        <span>{formatCurrency(totalAmount)}</span>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <RadioGroup value={selectedMethod} onValueChange={(v) => setSelectedMethod(v as PaymentMethod)}>
                  {methods.map((method) => (
                    <div key={method.id} className="flex items-center space-x-3 p-3 border rounded-lg hover:bg-gray-50 cursor-pointer">
                      <RadioGroupItem value={method.id} id={method.id} />
                      <Label htmlFor={method.id} className="flex items-center space-x-3 cursor-pointer flex-1">
                        {methodIcons[method.id]}
                        <div>
                          <p className="font-medium">{method.name}</p>
                          <p className="text-xs text-gray-500">{method.description}</p>
                        </div>
                      </Label>
                    </div>
                  ))}
                </RadioGroup>

                {(selectedMethod === 'mobile_money' || selectedMethod === 'ussd') && (
                  <div>
                    <Label>Phone Number</Label>
                    <Input
                      value={phoneNumber}
                      onChange={(e) => setPhoneNumber(e.target.value)}
                      placeholder="+260 97 xxx xxxx"
                    />
                  </div>
                )}

                <Button onClick={handleProceed} className="w-full" size="lg">
                  Continue <ArrowRight className="h-4 w-4 ml-2" />
                </Button>
              </div>
            </motion.div>
          )}

          {/* Step 2: Card Details */}
          {step === 'details' && (
            <motion.div key="details" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
              <div className="space-y-4">
                <div>
                  <Label>Card Number</Label>
                  <Input
                    value={cardNumber}
                    onChange={(e) => setCardNumber(e.target.value.replace(/\D/g, '').substring(0, 16))}
                    placeholder="5531 8866 5725 2950"
                    maxLength={19}
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <Label>Expiry</Label>
                    <Input
                      value={cardExpiry}
                      onChange={(e) => setCardExpiry(e.target.value)}
                      placeholder="MM/YY"
                      maxLength={5}
                    />
                  </div>
                  <div>
                    <Label>CVV</Label>
                    <Input
                      value={cardCvv}
                      onChange={(e) => setCardCvv(e.target.value.replace(/\D/g, '').substring(0, 4))}
                      placeholder="564"
                      maxLength={4}
                      type="password"
                    />
                  </div>
                </div>
                <div className="flex space-x-2">
                  <Button variant="outline" onClick={() => setStep('method')} className="flex-1">
                    Back
                  </Button>
                  <Button onClick={handlePayment} className="flex-1" size="lg">
                    Pay {formatCurrency(totalAmount)}
                  </Button>
                </div>
              </div>
            </motion.div>
          )}

          {/* Step 3: Processing */}
          {step === 'processing' && (
            <motion.div key="processing" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <div className="flex flex-col items-center justify-center py-8 space-y-4">
                <Loader2 className="h-12 w-12 animate-spin text-primary" />
                <p className="text-gray-600">Processing your {formatCurrency(totalAmount)} payment...</p>
                <p className="text-xs text-gray-400">Please do not close this window</p>
              </div>
            </motion.div>
          )}

          {/* Step 4: Success */}
          {step === 'success' && (
            <motion.div key="success" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }}>
              <div className="flex flex-col items-center justify-center py-8 space-y-4">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: 'spring', delay: 0.2 }}
                >
                  <CheckCircle2 className="h-16 w-16 text-green-500" />
                </motion.div>
                <h3 className="text-xl font-bold text-green-700">Payment Initiated!</h3>
                <p className="text-gray-600 text-center text-sm">
                  Your payment of {formatCurrency(totalAmount)} has been initiated.
                  Complete the payment in the new window.
                </p>
                {txRef && (
                  <p className="text-xs text-gray-400 font-mono">Ref: {txRef}</p>
                )}
                <Button onClick={handleClose} className="w-full mt-4">Done</Button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </DialogContent>
    </Dialog>
  );
};

export default PaymentModal;
