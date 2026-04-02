 import { useState } from 'react';
 import { Share2, Copy, Check, X } from 'lucide-react';
 import { Button } from '@/components/ui/button';
 import {
   Dialog,
   DialogContent,
   DialogDescription,
   DialogHeader,
   DialogTitle,
   DialogTrigger,
 } from '@/components/ui/dialog';
 import { Input } from '@/components/ui/input';
 import { Switch } from '@/components/ui/switch';
 import { Label } from '@/components/ui/label';
 import { useShareJourney } from '@/hooks/useShareJourney';
 import { useToast } from '@/hooks/use-toast';
 
 interface ShareJourneyButtonProps {
   journeyPassengerId: string | null;
 }
 
 export const ShareJourneyButton = ({ journeyPassengerId }: ShareJourneyButtonProps) => {
   const { createShareLink, isLoading } = useShareJourney();
   const { toast } = useToast();
   const [isOpen, setIsOpen] = useState(false);
   const [shareUrl, setShareUrl] = useState<string | null>(null);
   const [copied, setCopied] = useState(false);
   const [permissions, setPermissions] = useState({
     view_location: true,
     view_eta: true,
     view_stops: true,
     view_orders: false,
   });
 
   const handleCreateLink = async () => {
     if (!journeyPassengerId) {
       toast({
         title: 'Not on a journey',
         description: 'You need to be on an active journey to share',
         variant: 'destructive',
       });
       return;
     }
 
     const result = await createShareLink({
       journey_passenger_id: journeyPassengerId,
       permissions,
       expires_in_hours: 24,
     });
 
     if (result) {
       // Build shareable URL using window location
       const baseUrl = window.location.origin;
       setShareUrl(`${baseUrl}/share/${result.share_code}`);
     }
   };
 
   const handleCopy = async () => {
     if (shareUrl) {
       await navigator.clipboard.writeText(shareUrl);
       setCopied(true);
       setTimeout(() => setCopied(false), 2000);
       toast({
         title: 'Link Copied!',
         description: 'Share this link with friends or family',
       });
     }
   };
 
   const handleOpenChange = (open: boolean) => {
     setIsOpen(open);
     if (!open) {
       setShareUrl(null);
       setCopied(false);
     }
   };
 
   return (
     <Dialog open={isOpen} onOpenChange={handleOpenChange}>
       <DialogTrigger asChild>
         <Button
           variant="secondary"
           size="icon"
           className="rounded-full shadow-lg bg-card/95 backdrop-blur-sm"
           title="Share journey"
         >
           <Share2 className="w-5 h-5" />
         </Button>
       </DialogTrigger>
       <DialogContent className="sm:max-w-md">
         <DialogHeader>
           <DialogTitle className="font-display">Share Your Journey</DialogTitle>
           <DialogDescription>
             Create a secure link for friends or family to track your journey in real-time.
           </DialogDescription>
         </DialogHeader>
 
         {!shareUrl ? (
           <div className="space-y-4 pt-4">
             <div className="space-y-3">
               <h4 className="font-medium text-sm">What can they see?</h4>
               
               <div className="flex items-center justify-between">
                 <Label htmlFor="location" className="text-sm text-muted-foreground">
                   Live location
                 </Label>
                 <Switch
                   id="location"
                   checked={permissions.view_location}
                   onCheckedChange={(checked) => setPermissions(p => ({ ...p, view_location: checked }))}
                 />
               </div>
               
               <div className="flex items-center justify-between">
                 <Label htmlFor="eta" className="text-sm text-muted-foreground">
                   Estimated arrival times
                 </Label>
                 <Switch
                   id="eta"
                   checked={permissions.view_eta}
                   onCheckedChange={(checked) => setPermissions(p => ({ ...p, view_eta: checked }))}
                 />
               </div>
               
               <div className="flex items-center justify-between">
                 <Label htmlFor="stops" className="text-sm text-muted-foreground">
                   Journey stops
                 </Label>
                 <Switch
                   id="stops"
                   checked={permissions.view_stops}
                   onCheckedChange={(checked) => setPermissions(p => ({ ...p, view_stops: checked }))}
                 />
               </div>
               
               <div className="flex items-center justify-between">
                 <Label htmlFor="orders" className="text-sm text-muted-foreground">
                   My orders
                 </Label>
                 <Switch
                   id="orders"
                   checked={permissions.view_orders}
                   onCheckedChange={(checked) => setPermissions(p => ({ ...p, view_orders: checked }))}
                 />
               </div>
             </div>
 
             <Button 
               onClick={handleCreateLink} 
               disabled={isLoading}
               className="w-full"
             >
               {isLoading ? 'Creating...' : 'Create Share Link'}
             </Button>
           </div>
         ) : (
           <div className="space-y-4 pt-4">
             <div className="flex items-center gap-2">
               <Input
                 value={shareUrl}
                 readOnly
                 className="flex-1 font-mono text-xs"
               />
               <Button
                 variant="outline"
                 size="icon"
                 onClick={handleCopy}
               >
                 {copied ? (
                   <Check className="w-4 h-4 text-journey-completed" />
                 ) : (
                   <Copy className="w-4 h-4" />
                 )}
               </Button>
             </div>
             
             <p className="text-xs text-muted-foreground text-center">
               Link expires in 24 hours
             </p>
 
             <Button
               variant="outline"
               onClick={() => setShareUrl(null)}
               className="w-full"
             >
               Create Another Link
             </Button>
           </div>
         )}
       </DialogContent>
     </Dialog>
   );
 };
 
 export default ShareJourneyButton;