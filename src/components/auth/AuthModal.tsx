 import { useState } from 'react';
 import { supabase } from '@/integrations/supabase/client';
 import { Button } from '@/components/ui/button';
 import { Input } from '@/components/ui/input';
 import { Label } from '@/components/ui/label';
 import {
   Dialog,
   DialogContent,
   DialogDescription,
   DialogHeader,
   DialogTitle,
 } from '@/components/ui/dialog';
 import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
 import { useToast } from '@/hooks/use-toast';
 import { Mail, Lock, User } from 'lucide-react';
 
 interface AuthModalProps {
   isOpen: boolean;
   onClose: () => void;
   onSuccess?: () => void;
 }
 
 export const AuthModal = ({ isOpen, onClose, onSuccess }: AuthModalProps) => {
   const { toast } = useToast();
   const [isLoading, setIsLoading] = useState(false);
   const [email, setEmail] = useState('');
   const [password, setPassword] = useState('');
   const [name, setName] = useState('');
 
   const handleSignIn = async (e: React.FormEvent) => {
     e.preventDefault();
     setIsLoading(true);
 
     try {
       const { error } = await supabase.auth.signInWithPassword({
         email,
         password,
       });
 
       if (error) throw error;
 
       toast({
         title: 'Welcome back! 👋',
         description: 'Successfully signed in',
       });
 
       onSuccess?.();
       onClose();
     } catch (error) {
       toast({
         title: 'Sign in failed',
         description: error instanceof Error ? error.message : 'Please try again',
         variant: 'destructive',
       });
     } finally {
       setIsLoading(false);
     }
   };
 
   const handleSignUp = async (e: React.FormEvent) => {
     e.preventDefault();
     setIsLoading(true);
 
     try {
       const { error } = await supabase.auth.signUp({
         email,
         password,
         options: {
           data: { full_name: name },
           emailRedirectTo: window.location.origin,
         },
       });
 
       if (error) throw error;
 
       toast({
         title: 'Account created! 🎉',
         description: 'Please check your email to verify your account',
       });
 
       onClose();
     } catch (error) {
       toast({
         title: 'Sign up failed',
         description: error instanceof Error ? error.message : 'Please try again',
         variant: 'destructive',
       });
     } finally {
       setIsLoading(false);
     }
   };
 
   return (
     <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
       <DialogContent className="sm:max-w-md">
         <DialogHeader>
           <DialogTitle className="font-display text-center text-xl">
             Welcome to BusNStay
           </DialogTitle>
           <DialogDescription className="text-center">
             Sign in to place orders and track your journey
           </DialogDescription>
         </DialogHeader>
 
         <Tabs defaultValue="signin" className="w-full">
           <TabsList className="grid w-full grid-cols-2">
             <TabsTrigger value="signin">Sign In</TabsTrigger>
             <TabsTrigger value="signup">Sign Up</TabsTrigger>
           </TabsList>
 
           <TabsContent value="signin" className="space-y-4 pt-4">
             <form onSubmit={handleSignIn} className="space-y-4">
               <div className="space-y-2">
                 <Label htmlFor="signin-email">Email</Label>
                 <div className="relative">
                   <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                   <Input
                     id="signin-email"
                     type="email"
                     placeholder="you@example.com"
                     value={email}
                     onChange={(e) => setEmail(e.target.value)}
                     className="pl-10"
                     required
                   />
                 </div>
               </div>
 
               <div className="space-y-2">
                 <Label htmlFor="signin-password">Password</Label>
                 <div className="relative">
                   <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                   <Input
                     id="signin-password"
                     type="password"
                     placeholder="••••••••"
                     value={password}
                     onChange={(e) => setPassword(e.target.value)}
                     className="pl-10"
                     required
                   />
                 </div>
               </div>
 
               <Button type="submit" className="w-full" disabled={isLoading}>
                 {isLoading ? 'Signing in...' : 'Sign In'}
               </Button>
             </form>
           </TabsContent>
 
           <TabsContent value="signup" className="space-y-4 pt-4">
             <form onSubmit={handleSignUp} className="space-y-4">
               <div className="space-y-2">
                 <Label htmlFor="signup-name">Full Name</Label>
                 <div className="relative">
                   <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                   <Input
                     id="signup-name"
                     type="text"
                     placeholder="John Doe"
                     value={name}
                     onChange={(e) => setName(e.target.value)}
                     className="pl-10"
                     required
                   />
                 </div>
               </div>
 
               <div className="space-y-2">
                 <Label htmlFor="signup-email">Email</Label>
                 <div className="relative">
                   <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                   <Input
                     id="signup-email"
                     type="email"
                     placeholder="you@example.com"
                     value={email}
                     onChange={(e) => setEmail(e.target.value)}
                     className="pl-10"
                     required
                   />
                 </div>
               </div>
 
               <div className="space-y-2">
                 <Label htmlFor="signup-password">Password</Label>
                 <div className="relative">
                   <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                   <Input
                     id="signup-password"
                     type="password"
                     placeholder="At least 6 characters"
                     value={password}
                     onChange={(e) => setPassword(e.target.value)}
                     className="pl-10"
                     minLength={6}
                     required
                   />
                 </div>
               </div>
 
               <Button type="submit" className="w-full" disabled={isLoading}>
                 {isLoading ? 'Creating account...' : 'Create Account'}
               </Button>
             </form>
           </TabsContent>
         </Tabs>
       </DialogContent>
     </Dialog>
   );
 };
 
 export default AuthModal;