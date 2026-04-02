import { ReactNode } from 'react';

// Form validation utilities
export interface ValidationRule {
  pattern?: RegExp;
  minLength?: number;
  maxLength?: number;
  required?: boolean;
  custom?: (value: any) => boolean;
  message: string;
}

export interface ValidationErrors {
  [key: string]: string | undefined;
}

export const validateEmail = (email: string): boolean => {
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email);
};

export const validatePhone = (phone: string): boolean => {
  const phonePattern = /^[\d\s+\-()]+$/;
  return phonePattern.test(phone) && phone.replace(/\D/g, '').length >= 10;
};

export const validatePassword = (password: string): {
  isValid: boolean;
  strength: 'weak' | 'medium' | 'strong';
  feedback: string[];
} => {
  const feedback: string[] = [];
  let strength: 'weak' | 'medium' | 'strong' = 'weak';

  if (password.length < 8) {
    feedback.push('At least 8 characters required');
  } else if (password.length < 12) {
    strength = 'medium';
  } else {
    strength = 'strong';
  }

  if (!/[A-Z]/.test(password)) {
    feedback.push('At least one uppercase letter required');
  }

  if (!/[a-z]/.test(password)) {
    feedback.push('At least one lowercase letter required');
  }

  if (!/\d/.test(password)) {
    feedback.push('At least one number required');
  }

  if (!/[!@#$%^&*]/.test(password)) {
    feedback.push('At least one special character (!@#$%^&*) required');
  }

  if (strength === 'strong' && feedback.length === 0) {
    strength = 'strong';
  }

  return {
    isValid: feedback.length === 0,
    strength,
    feedback,
  };
};

export const validateURL = (url: string): boolean => {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
};

export const validateField = (
  value: any,
  rules: ValidationRule[]
): string | undefined => {
  for (const rule of rules) {
    if (rule.required && (!value || (typeof value === 'string' && value.trim() === ''))) {
      return rule.message;
    }

    if (value && typeof value === 'string') {
      if (rule.minLength && value.length < rule.minLength) {
        return rule.message;
      }

      if (rule.maxLength && value.length > rule.maxLength) {
        return rule.message;
      }

      if (rule.pattern && !rule.pattern.test(value)) {
        return rule.message;
      }
    }

    if (rule.custom && !rule.custom(value)) {
      return rule.message;
    }
  }

  return undefined;
};

// Accessibility utilities
export const a11yAttrs = {
  // Screen reader only text
  srOnly: 'sr-only',
  
  // Common ARIA attributes
  ariaLabel: (label: string) => ({
    'aria-label': label,
  }),
  
  ariaDescribedBy: (id: string) => ({
    'aria-describedby': id,
  }),
  
  ariaRequired: (required: boolean) => ({
    'aria-required': required,
  }),

  ariaInvalid: (invalid: boolean) => ({
    'aria-invalid': invalid,
  }),

  ariaLive: (polite: 'polite' | 'assertive' = 'polite') => ({
    'aria-live': polite,
    'aria-atomic': true,
  }),

  ariaHidden: (hidden: boolean) => ({
    'aria-hidden': hidden,
  }),

  role: (role: string) => ({
    role,
  }),
};

// Loading state accessibility
export const handleLoadingState = (isLoading: boolean) => {
  if (isLoading) {
    document.body.setAttribute('aria-busy', 'true');
  } else {
    document.body.removeAttribute('aria-busy');
  }
};

// Focus management
export const manageFocus = (element: HTMLElement | null) => {
  if (element) {
    element.focus();
    // Emit focus event for testing
    element.dispatchEvent(new Event('focus', { bubbles: true }));
  }
};

// Keyboard navigation helpers
export const isEnterKey = (e: React.KeyboardEvent): boolean => {
  return e.key === 'Enter' || e.keyCode === 13;
};

export const isEscapeKey = (e: React.KeyboardEvent): boolean => {
  return e.key === 'Escape' || e.keyCode === 27;
};

export const isArrowKey = (e: React.KeyboardEvent): boolean => {
  return ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key);
};

export const isTabKey = (e: React.KeyboardEvent): boolean => {
  return e.key === 'Tab' || e.keyCode === 9;
};

// Announce to screen readers
export const announceToScreenReader = (message: string, priority: 'polite' | 'assertive' = 'polite') => {
  const announcement = document.createElement('div');
  announcement.setAttribute('aria-live', priority);
  announcement.setAttribute('aria-atomic', 'true');
  announcement.className = 'sr-only';
  announcement.textContent = message;
  document.body.appendChild(announcement);

  setTimeout(() => {
    document.body.removeChild(announcement);
  }, 1000);
};

// Skip link component for keyboard navigation
export const SkipLink = () => (
  <a
    href="#main-content"
    className="absolute top-0 left-0 -translate-y-full focus:translate-y-0 bg-blue-600 text-white px-4 py-2 text-sm font-medium transition-transform z-50"
  >
    Skip to main content
  </a>
);

// Form field with accessibility
export const AccessibleFormField = ({
  id,
  label,
  error,
  description,
  required,
  children,
}: {
  id: string;
  label: string;
  error?: string;
  description?: string;
  required?: boolean;
  children: ReactNode;
}) => (
  <div className="space-y-1.5">
    <label htmlFor={id} className="block text-sm font-medium text-slate-700 dark:text-slate-300">
      {label}
      {required && <span className="text-red-600 ml-1">*</span>}
    </label>
    {children}
    {description && !error && (
      <p id={`${id}-description`} className="text-xs text-slate-600 dark:text-slate-400">
        {description}
      </p>
    )}
    {error && (
      <p id={`${id}-error`} className="text-xs text-red-600 dark:text-red-400">
        {error}
      </p>
    )}
  </div>
);

// Color contrast checker (WCAG AA standard)
export const meetsContrastRequirement = (
  foreground: string,
  background: string,
  level: 'AA' | 'AAA' = 'AA'
): boolean => {
  const getLuminance = (color: string): number => {
    const rgb = parseInt(color.slice(1), 16);
    const r = (rgb >> 16) & 0xff;
    const g = (rgb >> 8) & 0xff;
    const b = (rgb >> 0) & 0xff;

    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance <= 0.03928
      ? luminance / 12.92
      : Math.pow((luminance + 0.055) / 1.055, 2.4);
  };

  const l1 = getLuminance(foreground);
  const l2 = getLuminance(background);
  const contrast = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);

  return level === 'AA' ? contrast >= 4.5 : contrast >= 7;
};
