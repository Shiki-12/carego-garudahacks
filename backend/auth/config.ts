import { secret } from "encore.dev/config";
// EmailJS configuration for sending OTPs via Email
export const EMAILJS_SERVICE_ID = secret("EMAILJS_SERVICE_ID");
export const EMAILJS_TEMPLATE_ID = secret("EMAILJS_TEMPLATE_ID");
export const EMAILJS_PUBLIC_KEY = secret("EMAILJS_PUBLIC_KEY");
export const EMAILJS_PRIVATE_KEY = secret("EMAILJS_PRIVATE_KEY");

// WAHA (WhatsApp HTTP API) configuration for sending OTPs via WhatsApp
export const WAHA_URL = secret("WAHA_URL");
export const WAHA_SESSION = secret("WAHA_SESSION");
