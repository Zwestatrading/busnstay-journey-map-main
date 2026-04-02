import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { MessageSquare, X, Send, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';

interface TextCallCentreProps {
  stationName?: string;
  stationId?: string;
  onClose?: () => void;
}

const TextCallCentre = ({ stationName = 'Station', stationId, onClose }: TextCallCentreProps) => {
  const { toast } = useToast();
  const [isOpen, setIsOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [formData, setFormData] = useState({
    restaurantName: '',
    foodItems: '',
    specialRequests: '',
    preferredContact: 'whatsapp',
  });

  const handleClose = () => {
    setIsOpen(false);
    setSubmitted(false);
    setFormData({
      restaurantName: '',
      foodItems: '',
      specialRequests: '',
      preferredContact: 'whatsapp',
    });
    onClose?.();
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.restaurantName || !formData.foodItems) {
      toast({
        title: 'Missing Information',
        description: 'Please provide restaurant name and food items.',
        variant: 'destructive',
      });
      return;
    }

    setIsSubmitting(true);
    
    // Simulate API call
    setTimeout(() => {
      setIsSubmitting(false);
      setSubmitted(true);
      toast({
        title: 'Request Sent',
        description: 'A BusNStay call centre agent will contact you shortly via WhatsApp.',
      });
      
      // Auto-close after 3 seconds
      setTimeout(() => handleClose(), 3000);
    }, 1500);
  };

  return (
    <>
      {/* Trigger Button */}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={() => setIsOpen(true)}
        className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium transition-colors"
      >
        <MessageSquare className="w-4 h-4" />
        Text Call Centre
      </motion.button>

      {/* Modal Dialog */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-md"
            >
              <Card className="border-primary/50">
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-blue-100 rounded-lg">
                        <MessageSquare className="w-5 h-5 text-blue-600" />
                      </div>
                      <div>
                        <CardTitle>Request Restaurant</CardTitle>
                        <CardDescription>Message our call centre agent</CardDescription>
                      </div>
                    </div>
                    <button
                      onClick={handleClose}
                      className="p-1 hover:bg-muted rounded-lg transition"
                    >
                      <X className="w-5 h-5" />
                    </button>
                  </div>
                </CardHeader>

                <CardContent>
                  {submitted ? (
                    <motion.div
                      initial={{ opacity: 0, scale: 0.9 }}
                      animate={{ opacity: 1, scale: 1 }}
                      className="text-center py-8 space-y-4"
                    >
                      <motion.div
                        animate={{ scale: [1, 1.1, 1] }}
                        transition={{ duration: 2, repeat: Infinity }}
                        className="flex justify-center"
                      >
                        <CheckCircle className="w-12 h-12 text-green-500" />
                      </motion.div>
                      <div>
                        <h3 className="font-semibold text-lg mb-1">Request Sent!</h3>
                        <p className="text-sm text-muted-foreground">
                          A call centre agent will contact you via WhatsApp within 5 minutes.
                        </p>
                      </div>
                      <div className="pt-4 space-y-2 text-sm text-muted-foreground">
                        <p>📍 <strong>{stationName}</strong></p>
                        <p>🍽️ {formData.restaurantName}</p>
                        <p>🍴 {formData.foodItems}</p>
                      </div>
                    </motion.div>
                  ) : (
                    <form onSubmit={handleSubmit} className="space-y-4">
                      <div>
                        <label className="text-sm font-medium mb-1.5 block">Restaurant Name</label>
                        <Input
                          placeholder="e.g., Nando's, Chanticleer"
                          value={formData.restaurantName}
                          onChange={(e) => setFormData({ ...formData, restaurantName: e.target.value })}
                          disabled={isSubmitting}
                        />
                      </div>

                      <div>
                        <label className="text-sm font-medium mb-1.5 block">Food Items You Want</label>
                        <Textarea
                          placeholder="e.g., Half chicken with peri-peri sauce, chips, coleslaw"
                          value={formData.foodItems}
                          onChange={(e) => setFormData({ ...formData, foodItems: e.target.value })}
                          disabled={isSubmitting}
                          rows={3}
                        />
                      </div>

                      <div>
                        <label className="text-sm font-medium mb-1.5 block">Special Requests (Optional)</label>
                        <Textarea
                          placeholder="e.g., Extra hot sauce, no onions, gluten-free options"
                          value={formData.specialRequests}
                          onChange={(e) => setFormData({ ...formData, specialRequests: e.target.value })}
                          disabled={isSubmitting}
                          rows={2}
                        />
                      </div>

                      <div className="pt-2 space-y-2">
                        <p className="text-xs text-muted-foreground">📌 Station: <strong>{stationName}</strong></p>
                        <p className="text-xs text-muted-foreground">💬 We'll contact you via WhatsApp</p>
                      </div>

                      <div className="flex gap-2 pt-4">
                        <Button
                          type="button"
                          variant="outline"
                          onClick={handleClose}
                          disabled={isSubmitting}
                          className="flex-1"
                        >
                          Cancel
                        </Button>
                        <Button
                          type="submit"
                          disabled={isSubmitting}
                          className="flex-1 gap-2"
                        >
                          {isSubmitting ? (
                            <>
                              <Loader2 className="w-4 h-4 animate-spin" />
                              Sending...
                            </>
                          ) : (
                            <>
                              <Send className="w-4 h-4" />
                              Send Request
                            </>
                          )}
                        </Button>
                      </div>
                    </form>
                  )}
                </CardContent>
              </Card>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};

export default TextCallCentre;
