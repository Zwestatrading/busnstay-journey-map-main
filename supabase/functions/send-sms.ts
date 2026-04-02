/**
 * Supabase Edge Function: Send SMS Notification
 * Sends SMS notifications to restaurants and riders via Africa's Talking
 * Called when orders are placed or status changes
 */

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

interface SMSPayload {
  recipients: string[]; // Phone numbers with country code: +260765...
  message: string;
  notification_type: "ORDER_RECEIVED" | "ORDER_READY" | "RIDER_ASSIGNED" | "STATUS_UPDATE";
}

async function sendSMS(request: Request): Promise<Response> {
  try {
    // Verify authorization
    const authHeader = request.headers.get("Authorization");
    const expectedToken = Deno.env.get("SMS_WEBHOOK_SECRET");

    if (!authHeader || authHeader !== `Bearer ${expectedToken}`) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const payload: SMSPayload = await request.json();
    const { recipients, message, notification_type } = payload;

    if (!recipients || recipients.length === 0) {
      return new Response(JSON.stringify({ error: "No recipients provided" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!message) {
      return new Response(JSON.stringify({ error: "Message is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const africasTalkingApiKey = Deno.env.get("AFRICA_TALKING_API_KEY");
    const africasTalkingUsername = Deno.env.get("AFRICA_TALKING_USERNAME");

    if (!africasTalkingApiKey || !africasTalkingUsername) {
      console.error("Africa's Talking credentials not configured");
      return new Response(
        JSON.stringify({ error: "SMS service not configured" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // Africa's Talking API: Send SMS
    const smsResponse = await fetch("https://api.sandbox.africastalking.com/version1/messaging", {
      method: "POST",
      headers: {
        "ApiKey": africasTalkingApiKey,
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
      },
      body: new URLSearchParams({
        username: africasTalkingUsername,
        message: message,
        recipients: recipients.join(","),
      }).toString(),
    });

    if (!smsResponse.ok) {
      const errorData = await smsResponse.text();
      console.error("Africa's Talking API error:", errorData);
      throw new Error(`SMS API error: ${smsResponse.status}`);
    }

    const result = await smsResponse.json();

    // Log SMS delivery attempt
    console.log(`SMS sent to ${recipients.length} recipients for ${notification_type}`, {
      recipients,
      message_length: message.length,
      response: result,
    });

    // Return success with delivery tracking
    return new Response(
      JSON.stringify({
        success: true,
        recipients_count: recipients.length,
        notification_type,
        message_id: result.SMSMessageData?.Message || "pending",
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error sending SMS:", error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Failed to send SMS",
        success: false,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
}

serve(sendSMS);
