# Shopify Level 2 Protected Customer Data Compliance Plan

## Overview

This plan covers everything needed to pass Shopify's Level 2 protected customer data review for App Store approval. It includes technical implementation, business preparation, and process steps.

---

## Gap Analysis: Current State vs Requirements

### What We Have
| Requirement | Status | Notes |
|-------------|--------|-------|
| HMAC webhook verification | ✅ Done | Using `secure_compare` correctly |
| API credentials encrypted | ✅ Done | ShopCredential uses Active Record Encryption |
| Multi-tenant architecture | ✅ Done | Shop model, Current.shop context |
| OAuth authentication | ✅ Done | Shopify OAuth flow working |

### What's Missing
| Requirement | Priority | Notes |
|-------------|----------|-------|
| **Compliance webhooks** | CRITICAL | customers/data_request, customers/redact, shop/redact |
| **PII encryption at rest** | CRITICAL | email, first_name in referrals + analytics_events |
| **Audit logging** | HIGH | Access logs for Level 2 |
| **Privacy policy** | CRITICAL | Required for App Store listing |
| **Incident response doc** | HIGH | Required for Level 2 |
| **Data protection attestation** | CRITICAL | Partner Dashboard submission |

---

## Part 1: Business & Process Preparation

### 1.1 Privacy Policy (Must Have Before Submission)

**Requirement**: Link to privacy policy in App Store listing

**Must Address**:
- What data we collect via Shopify APIs (customer name, email, order data)
- Why we collect it (referral tracking, reward generation)
- How long we keep it (until merchant uninstalls or customer requests deletion)
- Where data is stored (Railway, US-based servers)
- How merchants can contact us for privacy inquiries
- How customers can request data deletion (via merchant → Shopify → webhook)

**Action Items**:
1. Draft privacy policy document
2. Host at accessible URL (e.g., `/privacy` route or static page)
3. Add URL to Partner Dashboard app listing

### 1.2 Data Access Justification (Partner Dashboard)

When requesting Level 2 access, Shopify asks "why do you need this data?"

**Our Justification**:
| Field | Why We Need It |
|-------|----------------|
| `customer.email` | Unique identifier for referral tracking; links referrals across sessions |
| `customer.first_name` | Personalization ("John, refer a friend!"); used in referral codes (JOHN847) |
| `customer.id` | Link to Shopify customer for notes and discount assignment |

**Key Principle**: Request only minimum data needed. We do NOT need:
- Phone number ❌
- Address ❌ (except for guest checkout fallback to first name)
- Full order history ❌

### 1.3 Incident Response Plan (SECURITY.md)

**Required Content**:
1. Severity classification (P1-P4)
2. Roles and responsibilities
3. Escalation procedures
4. Evidence collection steps
5. Communication templates
6. Post-incident review process

### 1.4 Partner Dashboard Configuration

**Steps**:
1. Go to Apps → [Your App] → API access requests
2. Request "Protected customer data access"
3. Select data fields: email, first_name (Level 2)
4. Complete "Data protection details":
   - Confirm encrypted backups (Railway PostgreSQL ✅)
   - Confirm test/prod separation (separate Railway environments)
   - Confirm data loss prevention (audit logging + no bulk export)
   - Confirm limited staff access (session auth, no direct DB access)
   - Confirm strong passwords (enforce in admin)
   - Confirm access logging (audit_logs table)
   - Confirm incident response (SECURITY.md)
5. Submit for review

---

## Part 2: Technical Implementation

### 2.1 Mandatory Compliance Webhooks

**Routes** (`config/routes.rb`):
```ruby
post "webhooks/customers_data_request", to: "webhooks#customers_data_request"
post "webhooks/customers_redact", to: "webhooks#customers_redact"
post "webhooks/shop_redact", to: "webhooks#shop_redact"
```

**a) customers/data_request**
- Shopify sends when customer requests their data export
- We must respond 200 OK immediately
- Action: Log to audit_logs for manual fulfillment within 30 days
- Include: customer email, shop domain, orders_requested array

**b) customers/redact**
- Shopify sends when customer requests deletion
- Must delete/anonymize all PII for that customer
- Actions:
  - Find referrals by email within the shop
  - Anonymize: `email → "deleted-{id}@redacted"`, `first_name → "Deleted"`
  - Delete analytics_events by email within shop
  - Log deletion to audit_logs

**c) shop/redact**
- Sent 48 hours after merchant uninstalls app
- Must delete ALL data for that shop
- Actions:
  - Delete all referrals for shop_id
  - Delete all analytics_events for shop_id
  - Delete all referral_rewards for shop_id
  - Delete discount_configs for shop_id
  - Delete shared_discounts for shop_id
  - Delete shop_credential
  - Delete shop record
  - Log deletion to audit_logs

**Webhook Registration** (`it-works-app/shopify.app.toml`):
```toml
[webhooks]
api_version = "2025-10"

[[webhooks.subscriptions]]
topics = ["orders/create"]
uri = "https://referral-app-proto-production.up.railway.app/webhooks/orders"

[[webhooks.subscriptions]]
compliance_topics = ["customers/data_request", "customers/redact", "shop/redact"]
uri = "https://referral-app-proto-production.up.railway.app/webhooks"
```

Then run: `shopify app deploy --force`

### 2.2 PII Encryption at Rest

**Models to Update**:

```ruby
# app/models/referral.rb
encrypts :email, deterministic: true  # deterministic allows lookups
encrypts :first_name

# app/models/analytics_event.rb
encrypts :email, deterministic: true
```

**Migration Required**: None (Rails handles transparently)

**Data Migration**: Existing data needs re-encryption
```ruby
# Run in console after adding encrypts:
Referral.find_each do |r|
  r.update_columns(
    email: r.email,
    first_name: r.first_name
  )
end
```

### 2.3 Audit Logging

**Migration**:
```ruby
create_table :audit_logs do |t|
  t.references :shop, foreign_key: true
  t.string :action        # view, create, update, delete, export, data_request, redact
  t.string :resource_type # Referral, AnalyticsEvent, Shop
  t.bigint :resource_id
  t.string :actor         # webhook, admin, system, customer
  t.string :actor_ip
  t.string :actor_identifier  # email or user_id
  t.jsonb :details
  t.timestamps
end
```

**Log Points**:
- Referral page view (when PII displayed)
- Admin config access
- Webhook processing (order, compliance)
- Data exports
- Data deletions

### 2.4 Files to Create/Modify

**New Files**:
| File | Purpose |
|------|---------|
| `db/migrate/xxx_create_audit_logs.rb` | Audit log table |
| `app/models/audit_log.rb` | Audit log model |
| `SECURITY.md` | Incident response plan |
| `app/views/pages/privacy.html.erb` | Privacy policy page |

**Modified Files**:
| File | Changes |
|------|---------|
| `config/routes.rb` | Add 3 compliance webhook routes + /privacy |
| `app/controllers/webhooks_controller.rb` | Add 3 compliance methods |
| `app/models/referral.rb` | Add `encrypts` for email, first_name |
| `app/models/analytics_event.rb` | Add `encrypts` for email |
| `it-works-app/shopify.app.toml` | Add compliance webhook subscription |

---

## Part 3: Implementation Order

### Phase 0: Update Plan Document
0. Replace `referral-app/docs/plans/pii-compliance.md` with this comprehensive plan

### Phase 1: Documentation & Policy (Do First)
1. Write privacy policy
2. Write SECURITY.md incident response plan
3. Host privacy policy at `/privacy`

### Phase 2: Database & Encryption
4. Create audit_logs migration
5. Add `encrypts` to Referral and AnalyticsEvent models
6. Run migrations
7. Re-encrypt existing data (if any)

### Phase 3: Compliance Webhooks
8. Add routes for 3 compliance webhooks
9. Implement `customers_data_request` handler
10. Implement `customers_redact` handler
11. Implement `shop_redact` handler
12. Add audit logging to each

### Phase 4: Webhook Registration
13. Update `shopify.app.toml` with compliance_topics
14. Run `shopify app deploy --force`
15. Verify webhooks registered in Partner Dashboard

### Phase 5: Partner Dashboard Submission
16. Complete "Data protection details" attestation
17. Request Level 2 protected customer data access
18. Submit app for review

---

## Part 4: Verification Checklist

### Before Submission
- [ ] Privacy policy accessible at public URL
- [ ] SECURITY.md documents incident response
- [ ] Audit logs table created and logging works
- [ ] PII fields encrypted (test with `Referral.first.email_before_type_cast`)
- [ ] `customers/data_request` webhook returns 200, logs request
- [ ] `customers/redact` webhook anonymizes/deletes customer data
- [ ] `shop/redact` webhook deletes all shop data
- [ ] All webhooks verify HMAC signatures
- [ ] Compliance webhooks registered in shopify.app.toml

### Testing
1. **Test data_request**: Trigger via Partner Dashboard → verify logged
2. **Test customers_redact**: Create test referral → trigger webhook → verify anonymized
3. **Test shop_redact**: Create test shop data → trigger webhook → verify deleted
4. **Test encryption**: Check `email_before_type_cast` shows encrypted value

---

## Part 5: What Shopify Reviewers Look For

Based on documentation, high-scrutiny triggers:
- High merchant installs
- Large customer record volumes
- Extended data retention
- Multiple protected fields requested

**To Pass Smoothly**:
1. Only request minimum data needed (email + first_name, not phone/address)
2. Have clear, specific justifications for each field
3. Implement all 7 Level 2 requirements before submission
4. Test webhooks actually work (they verify this)
5. Privacy policy must be live and accessible
6. 30-day response commitment for data requests

**Common Rejection Reasons**:
- Compliance webhooks not implemented or broken
- Privacy policy missing or inaccessible
- Requesting more data than justified
- HMAC verification failing

---

## Critical Files Reference

```
referral-app/
├── app/
│   ├── controllers/
│   │   └── webhooks_controller.rb  # Add 3 compliance methods
│   ├── models/
│   │   ├── referral.rb             # Add encrypts
│   │   ├── analytics_event.rb      # Add encrypts
│   │   └── audit_log.rb            # NEW
│   └── views/
│       └── pages/
│           └── privacy.html.erb    # NEW
├── config/
│   └── routes.rb                   # Add webhook routes
├── db/
│   └── migrate/
│       └── xxx_create_audit_logs.rb # NEW
└── SECURITY.md                     # NEW

it-works-app/
└── shopify.app.toml                # Add compliance_topics
```

---

## Sources
- [Shopify Protected Customer Data Requirements](https://shopify.dev/docs/apps/launch/protected-customer-data)
- [Shopify Privacy Law Compliance](https://shopify.dev/docs/apps/build/compliance/privacy-law-compliance)
- [Shopify Privacy Requirements](https://shopify.dev/docs/apps/launch/privacy-requirements)
