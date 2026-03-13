# Referrals: Onboarding Insights

Captured from Alex & Ben call, 2026-03-11.

## Atomic Integration Setup

The Atomic auto-apply feature (reward applied to next subscription box) is effectively off until the merchant enters their Atomic API key in the app setup config. No explicit on/off toggle needed — absence of API key = off. When ready, merchant adds the key and rewards start auto-applying.

Ben's preference: launch with Atomic off, get everything looking good with Marion (presentation, images, text, referral program messaging), then flick it on.

## "Add to Subscription" Button

Ben initially suggested a button on the account referral page: "Add this to my subscription now". However, when Atomic is connected, rewards auto-apply to the next available order — so this button isn't needed. The UX insight is that merchants may expect a manual trigger; worth making the auto-apply behaviour clear in the referral page copy or onboarding docs.

## Reward Notification Flow

Without Klaviyo integration, the only way a user knows they have a reward is by visiting their referral screen. This is insufficient for most merchants. The expected onboarding flow once Klaviyo is integrated:

1. Friend uses referral code at checkout
2. Reward is generated for the referrer
3. Klaviyo event fires
4. Email sent: "Here's your reward code, we've added it to your subscription"
5. Reward visible in account referral page

## Customer Care Workflow

Ben's CS team currently uses Gorgias. For referral queries ("my friend used my code but I didn't get a reward"), the stopgap workflow is:

1. Check Shopify customer timeline for referral code notes
2. Check discounts section for code usage
3. Ask customer when their friend signed up, cross-reference

Longer term, referral data should be accessible from Gorgias or a dedicated view without needing to dig through Shopify admin.
