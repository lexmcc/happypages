# Security & Incident Response Plan

**Happy Pages Ltd**
Last updated: 2026-02-06

---

## 1. Scope

This document covers the Happy Pages referral platform:
- **Backend:** Rails application at app.happypages.co
- **Extension:** Shopify checkout UI extension
- **Data:** Customer PII (email, first name), merchant credentials, referral records

---

## 2. Severity Classification

| Level | Description | Examples | Response Time |
|-------|------------|----------|---------------|
| **P1 - Critical** | Active data breach or system compromise | Unauthorised access to PII, leaked credentials, database exposure | Immediate (within 1 hour) |
| **P2 - High** | Vulnerability with potential for data exposure | Authentication bypass, SQL injection, unencrypted PII discovered | Within 4 hours |
| **P3 - Medium** | Security weakness without active exploitation | Missing rate limiting, verbose error messages, outdated dependencies | Within 24 hours |
| **P4 - Low** | Minor security improvements | CSP header refinements, logging enhancements | Within 1 week |

---

## 3. Roles and Responsibilities

| Role | Responsibility |
|------|---------------|
| **Incident Lead** | Assesses severity, coordinates response, communicates with affected parties |
| **Technical Lead** | Investigates root cause, implements fixes, verifies remediation |
| **Communications** | Notifies affected merchants, Shopify, and regulators if required |

At current team size, all roles are held by the founding team.

---

## 4. Incident Response Procedure

### 4.1 Detection & Triage
1. Identify the incident source (monitoring alert, user report, Shopify notification)
2. Classify severity (P1-P4)
3. Document initial findings with timestamps

### 4.2 Containment
- **P1/P2:** Immediately revoke compromised credentials and rotate keys
- Disable affected endpoints or features if necessary
- Preserve logs and evidence before any system changes

### 4.3 Investigation
1. Review audit logs for unauthorised access patterns
2. Identify affected records (which shops, which customers)
3. Determine attack vector and timeline
4. Document all findings

### 4.4 Remediation
1. Deploy fixes to address the root cause
2. Rotate all potentially compromised secrets:
   - Rails master key
   - Active Record encryption keys
   - Shopify API credentials
   - Integration API keys (Klaviyo, Awtomic)
3. Re-encrypt affected data if encryption keys were compromised
4. Verify fix with testing

### 4.5 Notification
- **Affected merchants:** Notify within 24 hours of confirmed breach via email
- **Shopify:** Report via Partner Dashboard within 24 hours
- **ICO (UK regulator):** Report within 72 hours if personal data of UK residents is affected (GDPR/UK GDPR requirement)
- **Customers:** Merchants are responsible for notifying their own customers; we provide them with details of what was affected

### 4.6 Recovery
1. Confirm all systems are secure
2. Monitor for recurrence (increased logging for 30 days)
3. Update affected merchants on resolution

---

## 5. Evidence Collection

When an incident is detected, preserve the following before making changes:

- [ ] Railway deployment logs
- [ ] Application logs (stdout/stderr)
- [ ] Audit log records from database
- [ ] Database query logs (if available)
- [ ] Git commit history around time of incident
- [ ] Screenshots of any anomalous behaviour

Store evidence in a secure, access-controlled location separate from the production system.

---

## 6. Post-Incident Review

Within 5 business days of resolution:

1. **Timeline:** Reconstruct event chronology
2. **Root cause:** Identify underlying vulnerability
3. **Impact:** Number of merchants/customers affected, data exposed
4. **Response assessment:** What went well, what could improve
5. **Action items:** Preventive measures with owners and deadlines
6. **Documentation:** Update this plan if gaps were identified

---

## 7. Preventive Measures

### Currently Implemented
- HMAC signature verification on all webhooks
- Active Record Encryption for API credentials and PII
- Multi-tenant isolation (shop-scoped queries via Current.shop)
- Session-based authentication with 24-hour timeout
- HTTPS enforced on all endpoints

### Ongoing
- Keep Rails and dependencies updated
- Review Shopify security advisories
- Audit access logs periodically
- Test compliance webhooks quarterly

---

## 8. Contact

To report a security vulnerability: **support@happypages.co**

We aim to acknowledge reports within 24 hours and provide an initial assessment within 72 hours.
