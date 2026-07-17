import { EMAILJS_SERVICE_ID, EMAILJS_TEMPLATE_ID, EMAILJS_PUBLIC_KEY, EMAILJS_PRIVATE_KEY, WAHA_URL, WAHA_SESSION } from "./config";

export async function sendOtpEmail(email: string, otp: string) {
    const serviceId = EMAILJS_SERVICE_ID();
    const templateId = EMAILJS_TEMPLATE_ID();
    const publicKey = EMAILJS_PUBLIC_KEY();
    const privateKey = EMAILJS_PRIVATE_KEY();

    if (!serviceId || !templateId || !publicKey) {
        console.warn("[EmailJS] Missing EMAILJS secrets. Falling back to console.");
        console.log(`[Email] Send OTP ${otp} to ${email}`);
        return;
    }

    try {
        const response = await fetch("https://api.emailjs.com/api/v1.0/email/send", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                service_id: serviceId,
                template_id: templateId,
                user_id: publicKey,
                accessToken: privateKey,
                template_params: {
                    to_email: email,
                    otp_code: otp,
                }
            })
        });

        if (!response.ok) {
            const errText = await response.text();
            throw new Error(`EmailJS API error: ${response.status} ${errText}`);
        }

        console.log(`[EmailJS] OTP ${otp} sent successfully to ${email}`);
    } catch (error) {
        console.error("[EmailJS] Failed to send OTP email:", error);
        throw new Error("Gagal mengirim email OTP via EmailJS");
    }
}

export async function sendOtpWaha(phone: string, otp: string) {
    const url = WAHA_URL();
    const session = WAHA_SESSION() || "default";

    if (!url) {
        console.warn("[WAHA] WAHA_URL secret is not set. Falling back to console.");
        console.log(`[WhatsApp] Send OTP ${otp} to ${phone}`);
        return;
    }

    // Format phone number to WhatsApp standard (e.g., 0812... -> 62812...)
    let formattedPhone = phone.replace(/[^0-9]/g, '');
    if (formattedPhone.startsWith('0')) {
        formattedPhone = '62' + formattedPhone.substring(1);
    }

    try {
        // WAHA API: POST /api/sendText
        const response = await fetch(`${url}/api/sendText`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                chatId: `${formattedPhone}@c.us`,
                text: `Kode OTP CareGo Anda adalah: *${otp}*\n\nBerlaku selama 5 menit. Jangan bagikan kode ini.`,
                session: session
            }),
        });

        if (!response.ok) {
            const errText = await response.text();
            console.error(`[WAHA] API returned ${response.status}:`, errText);
            throw new Error(`WAHA API Error: ${response.statusText}`);
        }

        console.log(`[WAHA] OTP ${otp} sent successfully to ${phone}`);
    } catch (error) {
        console.error("[WAHA] Failed to send WhatsApp OTP:", error);
        throw new Error("Gagal mengirim WhatsApp OTP");
    }
}

export async function dispatchOtp(identifier: string, method: string, otp: string) {
    if (method === "email") {
        await sendOtpEmail(identifier, otp);
    } else if (method === "whatsapp") {
        await sendOtpWaha(identifier, otp);
    } else {
        // Fallback for unknown methods
        console.log(`[${method.toUpperCase()}] Send OTP ${otp} to ${identifier} (Console Fallback)`);
    }
}
