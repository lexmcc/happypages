import '@shopify/ui-extensions/preact';
import {render} from "preact";
import {useState, useEffect} from "preact/hooks";

const REFERRAL_APP_URL = "https://app.happypages.co";

// Get shop domain for multi-tenant API calls
const getShopDomain = () => shopify.shop?.myshopifyDomain || '';

// Analytics tracking helper (fire-and-forget)
const trackEvent = (eventType, email, metadata = {}) => {
  const shopDomain = getShopDomain();
  fetch(`${REFERRAL_APP_URL}/api/analytics`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(shopDomain && { 'X-Shop-Domain': shopDomain })
    },
    body: JSON.stringify({
      event_type: eventType,
      source: 'checkout_extension',
      email,
      metadata
    })
  }).catch(() => {}); // Silent fail - analytics shouldn't break the extension
};

const DEFAULT_CONFIG = {
  banner_image: "https://images.pexels.com/photos/35259676/pexels-photo-35259676.jpeg",
  heading: "{firstName}, Refer A Friend",
  subtitle: "Give 50% And Get 50% Off",
  button_text: "Share Now",
  shop_slug: null,
  referral_base_url: REFERRAL_APP_URL
};

const DEFAULT_DISCOUNTS = {
  referred: { type: 'percentage', value: '50' },
  referrer: { type: 'percentage', value: '50' }
};

// Format discount value (e.g., "50%" or "£10")
const formatDiscount = (type, value) => {
  return type === 'percentage' ? `${value}%` : `£${value}`;
};

export default async () => {
  render(<Extension />, document.body)
};

function Extension() {
  const [config, setConfig] = useState(DEFAULT_CONFIG);
  const [discounts, setDiscounts] = useState(DEFAULT_DISCOUNTS);
  const [shopSlug, setShopSlug] = useState(null);
  const [referralBaseUrl, setReferralBaseUrl] = useState(REFERRAL_APP_URL);
  const [referralCode, setReferralCode] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Try customer account first (logged-in users)
  const customer = shopify.buyerIdentity.customer.value;
  // Fall back to shipping address (works for guest checkout too)
  const shippingAddress = shopify.shippingAddress.value;
  // Get email from buyer identity
  const buyerEmail = shopify.buyerIdentity.email?.value;

  const firstName = customer?.firstName || shippingAddress?.firstName || '';
  const email = buyerEmail || customer?.email || '';

  // Fetch config on mount and track extension load
  useEffect(() => {
    const shopDomain = getShopDomain();
    fetch(`${REFERRAL_APP_URL}/api/config`, {
      headers: shopDomain ? { 'X-Shop-Domain': shopDomain } : {}
    })
      .then(r => r.json())
      .then(data => {
        if (data.extension) {
          setConfig(data.extension);
        }
        if (data.discounts) {
          setDiscounts(data.discounts);
        }
        if (data.shop_slug) {
          setShopSlug(data.shop_slug);
        }
        if (data.referral_base_url) {
          setReferralBaseUrl(data.referral_base_url);
        }
        // Track extension load after config fetch completes
        trackEvent('extension_load', email);
      })
      .catch(() => {
        // Track even on error (extension still shows with defaults)
        trackEvent('extension_load', email);
      })
      .finally(() => {
        setIsLoading(false);
      });
  }, []);

  // Auto-create referral on page load (non-blocking)
  useEffect(() => {
    if (firstName && email) {
      const shopDomain = getShopDomain();
      fetch(`${REFERRAL_APP_URL}/api/referrals`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(shopDomain && { 'X-Shop-Domain': shopDomain })
        },
        body: JSON.stringify({ first_name: firstName, email })
      })
        .then(r => r.json())
        .then(data => {
          if (data.referral_code) {
            setReferralCode(data.referral_code);
          }
        })
        .catch(() => {}); // Silent fail - user can still click button with fallback URL
    }
  }, [firstName, email]);

  // Show grey skeleton placeholder while loading - MUST be before accessing config
  if (isLoading) {
    return (
      <s-box background="subdued" border="base" borderRadius="base" padding="none">
        <s-box background="subdued" inlineSize="fill" blockSize="200" />
        <s-box padding="base">
          <s-stack gap="small">
            <s-box background="subdued" inlineSize="200" blockSize="24" />
            <s-box background="subdued" inlineSize="fill" blockSize="16" />
            <s-box background="subdued" inlineSize="fill" blockSize="40" borderRadius="base" />
          </s-stack>
        </s-box>
      </s-box>
    );
  }

  // Replace all variables in text (replaceAll for multiple occurrences)
  const replaceVariables = (text) => {
    return text
      .replaceAll('{firstName}', firstName || 'Friend')
      .replaceAll('{discount}', formatDiscount(discounts.referred.type, discounts.referred.value))
      .replaceAll('{reward}', formatDiscount(discounts.referrer.type, discounts.referrer.value));
  };

  const heading = replaceVariables(config.heading || '{firstName}, Refer A Friend');
  const subtitle = replaceVariables(config.subtitle || 'Give 50% And Get 50% Off');
  const buttonText = replaceVariables(config.button_text || 'Share Now');

  // Build referral URL — prefer code-based (no PII), fall back to email params
  const referralParams = referralCode
    ? `code=${encodeURIComponent(referralCode)}`
    : `firstName=${encodeURIComponent(firstName)}&email=${encodeURIComponent(email)}`;
  const referralUrl = shopSlug
    ? `${referralBaseUrl}/${shopSlug}/refer?${referralParams}`
    : `${referralBaseUrl}/refer?${referralParams}`;

  // Track share button click before navigation
  const handleShareClick = () => {
    trackEvent('share_click', email);
  };

  return (
    <s-box background="base" border="base" borderRadius="base" padding="none">
      <s-image
        src={config.banner_image}
        inlineSize="fill"
        aspectRatio="1.5"
        objectFit="cover"
      />
      <s-box padding="base">
        <s-stack gap="small">
          <s-heading>{heading}</s-heading>
          <s-text color="subdued">{subtitle}</s-text>
          <s-button
            href={referralUrl}
            variant="primary"
            inlineSize="fill"
            onClick={handleShareClick}
          >
            {buttonText}
          </s-button>
        </s-stack>
      </s-box>
    </s-box>
  );
}
