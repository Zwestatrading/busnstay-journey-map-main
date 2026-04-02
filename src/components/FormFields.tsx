/**
 * Advanced Form Components with Real-Time Validation
 * Production-ready form inputs with error handling and feedback
 */

import { useState, useCallback, ReactNode } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AlertCircle, CheckCircle2, Eye, EyeOff, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface FormFieldProps {
  label: string;
  name: string;
  type?: string;
  placeholder?: string;
  value: string;
  onChange: (value: string) => void;
  error?: string;
  hint?: string;
  required?: boolean;
  disabled?: boolean;
  icon?: ReactNode;
  maxLength?: number;
  pattern?: string;
  validate?: (value: string) => string | null;
}

export const FormField = ({
  label,
  name,
  type = 'text',
  placeholder,
  value,
  onChange,
  error,
  hint,
  required = false,
  disabled = false,
  icon,
  maxLength,
  pattern,
  validate,
}: FormFieldProps) => {
  const [isFocused, setIsFocused] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const newValue = e.target.value;
      onChange(newValue);
      
      if (validate) {
        const validationResult = validate(newValue);
        setValidationError(validationResult);
      }
    },
    [onChange, validate]
  );

  const isValid = !error && !validationError && value.length > 0;
  const hasError = !!error || !!validationError;
  const displayError = error || validationError;
  const displayType = type === 'password' && showPassword ? 'text' : type;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="space-y-2"
    >
      {/* Label */}
      <label htmlFor={name} className="block text-sm font-medium text-white">
        {label}
        {required && <span className="text-rose-400 ml-1">*</span>}
      </label>

      {/* Input Container */}
      <div className="relative">
        <div
          className={cn(
            'relative flex items-center rounded-lg transition-all duration-300',
            'bg-slate-900/50 border border-white/10',
            'focus-within:ring-2 focus-within:ring-blue-500/40 focus-within:border-blue-500/50',
            isFocused && 'ring-2 ring-blue-500/40 border-blue-500/50',
            hasError && 'border-rose-500/50 focus-within:ring-rose-500/40 focus-within:border-rose-500/50',
            isValid && 'border-emerald-500/50',
            disabled && 'opacity-50 cursor-not-allowed'
          )}
        >
          {icon && (
            <div className="pl-3 text-gray-400 pointer-events-none">
              {icon}
            </div>
          )}

          <input
            id={name}
            name={name}
            type={displayType}
            value={value}
            onChange={handleChange}
            placeholder={placeholder}
            disabled={disabled}
            maxLength={maxLength}
            pattern={pattern}
            onFocus={() => setIsFocused(true)}
            onBlur={() => setIsFocused(false)}
            className={cn(
              'flex-1 bg-transparent px-3 py-3 text-white placeholder-gray-500',
              'focus:outline-none',
              icon && 'pl-0'
            )}
          />

          {/* Status Icons */}
          <AnimatePresence>
            {isValid && (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                exit={{ scale: 0 }}
                className="pr-3 text-emerald-400"
              >
                <CheckCircle2 className="w-5 h-5" />
              </motion.div>
            )}
            {hasError && (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                exit={{ scale: 0 }}
                className="pr-3 text-rose-400"
              >
                <AlertCircle className="w-5 h-5" />
              </motion.div>
            )}
            {type === 'password' && value.length > 0 && (
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="pr-3 text-gray-400 hover:text-white transition"
                tabIndex={-1}
              >
                {showPassword ? (
                  <EyeOff className="w-5 h-5" />
                ) : (
                  <Eye className="w-5 h-5" />
                )}
              </button>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Character Count */}
      {maxLength && (
        <div className="text-xs text-gray-500">
          {value.length} / {maxLength}
        </div>
      )}

      {/* Error Message */}
      <AnimatePresence>
        {displayError && (
          <motion.div
            initial={{ opacity: 0, y: -5 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -5 }}
            className="flex items-center gap-2 text-xs text-rose-400"
          >
            <AlertCircle className="w-4 h-4 flex-shrink-0" />
            {displayError}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Hint Text */}
      {hint && !displayError && (
        <p className="text-xs text-gray-400">{hint}</p>
      )}
    </motion.div>
  );
};

export interface FormGroupProps {
  children: ReactNode;
  className?: string;
  onSubmit?: (e: React.FormEvent) => void;
}

export const FormGroup = ({ children, className, onSubmit }: FormGroupProps) => {
  return (
    <form
      onSubmit={onSubmit}
      className={cn('space-y-6', className)}
    >
      {children}
    </form>
  );
};

export interface LoadingButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  loading?: boolean;
  loadingText?: string;
  children: ReactNode;
}

export const LoadingButton = ({
  loading = false,
  loadingText = 'Loading...',
  children,
  disabled,
  className,
  ...props
}: LoadingButtonProps) => {
  return (
    <motion.button
      whileHover={!loading && !disabled ? { scale: 1.02 } : undefined}
      whileTap={!loading && !disabled ? { scale: 0.98 } : undefined}
      disabled={loading || disabled}
      className={cn(
        'relative px-6 py-3 rounded-lg font-semibold transition-all duration-300',
        'bg-gradient-to-r from-blue-600 to-indigo-600 text-white',
        'hover:from-blue-700 hover:to-indigo-700 shadow-lg shadow-blue-500/30',
        'disabled:opacity-50 disabled:cursor-not-allowed',
        'flex items-center justify-center gap-2',
        className
      )}
      {...props}
    >
      {loading && <Loader2 className="w-4 h-4 animate-spin" />}
      <span>{loading ? loadingText : children}</span>
    </motion.button>
  );
};
