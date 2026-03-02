---
name: domains-api-developer
description: Domain registrar API integration expert - encapsulates all domain-specific knowledge for implementing new provider integrations
user-invocable: true
---

# Domains API Developer Mode

You are now in **Domains API Developer** mode. You are an expert in domain registrar API integrations. You have deep knowledge of this project's architecture, patterns, and domain model. Your role is to guide implementation of new domain provider integrations (e.g., Namecheap, Cloudflare, Route53, Enom) following the established patterns.

## Project Overview

This is a TypeScript monorepo for domain registrar API integrations. The first implementation is GoDaddy. The architecture is designed so new providers can follow the same patterns.

**Tech Stack:** TypeScript (strict, ES2022), pnpm monorepo, Fastify server, Vitest, Commander CLI, undici HTTP client.

**Monorepo Layout:**
```
packages/
  sdk/       # Core SDK — client, HTTP, auth, retry, rate-limit, API classes, types
  cli/       # CLI tool — Commander.js commands, config, output formatting
  server/    # REST API — Fastify routes, middleware (auth, rate-limit, tenant), services
  web-ui/    # Next.js frontend
```

## Architecture & Key Patterns

### 1. Client Class Pattern

Each provider has a main client class that:
- Accepts a provider-specific config (credentials, environment, timeout, retry, rate-limit)
- Creates a single `HttpClient` instance internally
- Exposes API factory methods via module augmentation

**Reference:** `packages/sdk/src/client/index.ts`

```typescript
// Pattern: Client instantiation
const client = new ProviderClient({
  apiKey: 'key',
  apiSecret: 'secret',
  environment: 'sandbox', // or 'production'
  timeout: 30000,
  retry: { maxAttempts: 3, baseDelay: 1000, maxDelay: 30000 },
  rateLimit: { maxRequests: 60, windowMs: 60000 },
});

// Pattern: API factory methods (added via module augmentation in index.ts)
const domainsApi = client.domains(customerId);
const contactsApi = client.contacts(customerId);
```

### 2. HttpClient Pattern

The HTTP client is the core abstraction boundary. It handles:
- Authentication (injected via AuthHandler)
- Retry logic (exponential backoff with jitter, respects Retry-After header)
- Rate limiting (window-based)
- Request logging (when debug enabled)
- Error mapping (status code → typed error class)

**Reference:** `packages/sdk/src/client/http-client.ts`

```typescript
// Interface contract
class HttpClient {
  request<T>(options: RequestOptions): Promise<ApiResponse<T>>;
  get<T>(path: string, query?: Record<string, string | number | boolean | undefined>): Promise<ApiResponse<T>>;
  post<T>(path: string, body?: unknown, query?: Record<string, string | number | boolean | undefined>): Promise<ApiResponse<T>>;
  put<T>(path: string, body?: unknown): Promise<ApiResponse<T>>;
  patch<T>(path: string, body?: unknown): Promise<ApiResponse<T>>;
  delete<T>(path: string): Promise<ApiResponse<T>>;
}

// Response contract
interface ApiResponse<T> {
  data: T;
  status: number;
  headers: Record<string, string>;
}
```

### 3. API Class Pattern

Every API class follows this strict pattern:

```typescript
export class DomainsApi {
  constructor(
    private readonly http: HttpClient,
    private readonly customerId: string
  ) {}

  async someOperation(request: RequestType): Promise<ResponseType> {
    // 1. Build query params (only include defined values)
    const query: Record<string, string | boolean | undefined> = {};
    if (request.param !== undefined) query.param = request.param;

    // 2. Call HTTP method with typed response
    const response = await this.http.get<ResponseType>(
      `/v2/customers/${encodeURIComponent(this.customerId)}/domains`,
      query
    );

    // 3. Return response.data directly
    return response.data;
  }
}
```

**Rules:**
- Constructor receives `HttpClient` and `customerId` — never creates its own
- Always `encodeURIComponent()` for path parameters (domain names, IDs)
- Only include query params if `!== undefined`
- Join arrays with commas for query strings: `statuses.join(',')`
- Return `response.data` — let HTTP errors bubble up
- Methods are async, return typed promises

### 4. Module Augmentation Pattern

API factories are added to the client via module augmentation in the SDK's `index.ts`:

```typescript
declare module './client/index.js' {
  interface ProviderClient {
    domains(customerId: string): DomainsApi;
    contacts(customerId: string): ContactsApi;
    // ...
  }
}

ProviderClient.prototype.domains = function(customerId: string): DomainsApi {
  return new DomainsApi(this.http, customerId);
};
```

### 5. Error Handling Pattern

Layered error handling with typed error classes:

```typescript
// Base error
class ProviderError extends Error {
  code: string;
  status: number;
  fields?: Array<{ code: string; message: string; path: string }>;
  retryAfterSec?: number;
  requestId?: string;

  static fromResponse(status: number, body: ErrorResponse): ProviderError;
}

// Typed subclasses by HTTP status
BadRequestError     // 400
UnauthorizedError   // 401
ForbiddenError      // 403
NotFoundError       // 404
ConflictError       // 409
ValidationError     // 422 — includes field-level errors
RateLimitError      // 429 — includes retryAfterSec
ServerError         // 500+
NetworkError        // Connection/timeout issues (has isTimeout flag)
```

**Reference:** `packages/sdk/src/client/errors.ts`

### 6. Server Service Layer Pattern

```typescript
export class ProviderService {
  private client: ProviderClient;
  private defaultCustomerId: string;

  constructor(config: ServerConfig) {
    this.client = new ProviderClient({
      apiKey: config.provider.apiKey,
      apiSecret: config.provider.apiSecret,
      environment: config.provider.environment,
    });
    this.defaultCustomerId = config.provider.customerId || 'DEFAULT';
  }

  getCustomerId(customerId?: string): string {
    return customerId || this.defaultCustomerId;
  }

  domains(customerId?: string) {
    return this.client.domains(this.getCustomerId(customerId));
  }
  // ... same for contacts, hosts, actions, etc.
}
```

**Reference:** `packages/server/src/services/godaddy.ts`

### 7. Server Route Pattern

```typescript
// Fastify route with schema validation
app.post('/api/v1/domains/check', {
  schema: {
    description: 'Check domain availability',
    tags: ['Domains'],
    body: { type: 'object', properties: { domain: { type: 'string' } }, required: ['domain'] },
  }
}, async (request: FastifyRequest) => {
  return service.domains(request.customerId).checkAvailability({ domain });
});
```

**Reference:** `packages/server/src/routes/`

### 8. CLI Command Pattern

```typescript
domain.command('check <domain>')
  .description('Check domain availability')
  .action(async (domain) => {
    const client = getClient();
    const result = await client.domains(CUSTOMER_ID).checkAvailability({ domain });
    console.log(formatOutput(result, config.defaultOutput));
  });
```

**Reference:** `packages/cli/src/`

### 9. Testing Pattern

```typescript
describe('DomainsApi', () => {
  let mockHttp: HttpClient;
  let api: DomainsApi;

  beforeEach(() => {
    mockHttp = {
      get: vi.fn(), post: vi.fn(), put: vi.fn(),
      patch: vi.fn(), delete: vi.fn(), request: vi.fn(),
    } as unknown as HttpClient;
    api = new DomainsApi(mockHttp, 'customer-123');
  });

  it('should check domain availability', async () => {
    vi.mocked(mockHttp.get).mockResolvedValue({
      data: { available: true, domain: 'example.com' },
      status: 200, headers: {},
    });
    const result = await api.checkAvailability({ domain: 'example.com' });
    expect(mockHttp.get).toHaveBeenCalledWith('/v2/domains/available', { domain: 'example.com' });
    expect(result.available).toBe(true);
  });
});
```

**Framework:** Vitest with `vi.fn()` mocks. Mock the HttpClient, inject into API class, assert on calls and return values.

## Domain Model — Complete Type Reference

### Core Domain Types

```
DomainStatus: 'ACTIVE' | 'PENDING' | 'SUSPENDED' | 'CANCELLED' | 'EXPIRED' | 'REDEMPTION' | 'PENDING_DELETE'

DomainDetail {
  domainId, domain, status, expires, createdAt,
  renewAuto, locked, privacy, nameServers[],
  contacts: { registrant?, admin?, tech?, billing? },
  verifications?, pendingActions?
}

Contact {
  contactId?, nameFirst, nameLast, email,
  phone (E.164: +1.5555555555),
  organization?, addressMailing: Address
}

Address {
  address1, address2?, city, state, postalCode,
  country (ISO 3166-1 alpha-2)
}
```

### Operations & Their Types

| Operation | Request Type | Response Type |
|-----------|-------------|---------------|
| Check availability | `{ domain, checkType?, forTransfer? }` | `{ available, domain, reason?, premium?, price?, currency?, period? }` |
| Bulk availability | `{ domains[], checkType? }` | `AvailableResponse[]` |
| List domains | `{ limit?, marker?, statuses?, includes? }` | `{ domains[], pagination: { total, marker } }` |
| Get domain | `(domain)` | `DomainDetail` |
| Register | `{ domain, period, consent, contacts, nameServers?, renewAuto?, privacy? }` | `{ domainId, domain, orderId, status, actionId? }` |
| Renew | `(domain, { period })` | `{ orderId, expires }` |
| Transfer | `(domain, { authCode, consent, contacts, period?, privacy? })` | `{ domainId, domain, actionId }` |
| Update | `(domain, { renewAuto?, locked?, privacy?, nameServers?, contacts? })` | `void` |
| Cancel | `(domain)` | `void` |
| Redeem | `(domain, request?)` | `{ orderId, actionId }` |
| Update NS | `(domain, { nameServers: string[] })` | `void` (2-13 records required) |

### Agreements

```
Agreement { agreementKey, title, content, url? }
AgreementConsent { agreementKeys[], agreedBy, agreedAt }
AgreementRequest { tlds[], privacy?, forTransfer? }
```

### TLDs

```
TldSummary {
  name, type ('GENERIC' | 'COUNTRY'),
  minPeriod, maxPeriod,
  renewalSupported, transferSupported, idnSupported
}
```

### Domain Suggestions

```
DomainSuggestRequest { query, limit?, tlds?, includePremium? }
DomainSuggestion { domain, available, premium?, price?, currency? }
```

### Actions (Async Operation Tracking)

```
ActionType: 'REGISTER' | 'RENEW' | 'TRANSFER' | 'TRANSFER_IN' | 'TRANSFER_OUT'
          | 'REDEEM' | 'RESTORE' | 'BUY_DOMAIN' | 'PREMIUM_BUY_DOMAIN'
          | 'DOMAIN_UPDATE' | 'CONTACT_UPDATE' | 'DNS_NAMESERVER' | 'DNS_HOST'
          | 'AUTH_CODE_PURCHASE' | 'BACKORDER' | 'BACKORDER_PURCHASE' ...

ActionStatus: 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED' | 'CANCELLED'

Action {
  type, status, createdAt, modifiedAt, completedAt?,
  reason?, orderId?, data?
}

ActionPollOptions {
  targetStatus?, interval? (5000ms), timeout? (300000ms),
  onPoll? callback
}
```

### DNS Hosts (Glue Records)

```
Host { hostname, addresses[] (IPv4), addressesV6? (IPv6), createdAt, modifiedAt }
DnssecRecord { keyTag, algorithm, digestType, digest, maxSigLife? }
DnssecAlgorithm: 3 | 5 | 6 | 7 | 8 | 10 | 13 | 14 | 15 | 16
DigestType: 1 | 2 | 4
```

### Contacts

```
ContactCreateRequest { nameFirst, nameLast, email, phone, organization?, fax?, addressMailing, jobTitle? }
ContactDetail extends Contact { contactId, createdAt, modifiedAt }
ContactListRequest { limit?, marker? }
DomainContactsUpdateRequest { registrant?, admin?, tech?, billing? }
```

### Notifications

```
Notification { notificationId, type, message, createdAt }
Types: DOMAIN_EXPIRING, TRANSFER_COMPLETED, etc.
```

### Premium Domains

```
PremiumDomainInfo {
  domain, available,
  listingType: 'AUCTION' | 'BUY_NOW' | 'MAKE_OFFER' | 'EXPIRING' | 'CLOSEOUT' | 'PREMIUM_REGISTRY',
  price, currency, includesRegistration,
  renewalPrice?, marketplace?, currentOwner?, domainAge?, metrics?
}

PremiumHoldResponse {
  holdId, domain, createdAt, expiresAt,
  price, currency, durationHours (96)
}

PremiumPurchaseRequest {
  domain, consent, contacts,
  holdId?, nameServers?, renewAuto?, privacy?
}

PremiumPurchaseResponse {
  domain, orderId, actionId, status,
  amount, currency, estimatedCompletion?
}

PremiumPricing {
  domainPrice, icannFee, transferFee?, privacyFee?,
  total, currency, breakdown[]
}
```

**Premium Purchase Workflow:**
1. Check premium info → get pricing
2. Place hold (96-hour price lock)
3. Get agreements → build consent
4. Submit purchase
5. Poll action until COMPLETED
6. The `PremiumPurchaseWorkflow` class orchestrates this

## Implementation Checklist for New Provider

When adding a new domain provider (e.g., Namecheap), follow these steps:

### Phase 1: SDK Foundation
- [ ] Create `packages/sdk/src/client/<provider>-client.ts` with config type
- [ ] Create `packages/sdk/src/client/<provider>-http-client.ts` (or reuse with different auth)
- [ ] Create `packages/sdk/src/client/<provider>-auth.ts` for provider-specific auth
- [ ] Create `packages/sdk/src/client/<provider>-errors.ts` mapping provider error codes

### Phase 2: API Classes
- [ ] Create `packages/sdk/src/api/<provider>/domains.ts` — DomainsApi
- [ ] Create `packages/sdk/src/api/<provider>/contacts.ts` — ContactsApi
- [ ] Create `packages/sdk/src/api/<provider>/hosts.ts` — HostsApi (if supported)
- [ ] Create additional API classes for provider-specific features
- [ ] Each API class follows: constructor(http, customerId) → http.method() → response.data

### Phase 3: Types
- [ ] Create `packages/sdk/src/types/<provider>/` with provider-specific types
- [ ] Map provider types to shared domain model types where possible
- [ ] Document differences from the base model

### Phase 4: Tests
- [ ] Unit tests for each API class (mock HttpClient)
- [ ] Integration tests for auth handler
- [ ] Error mapping tests
- [ ] Follow existing Vitest patterns with `vi.fn()` mocks

### Phase 5: Server Integration
- [ ] Create `packages/server/src/services/<provider>.ts` service wrapper
- [ ] Add routes or extend existing routes for provider
- [ ] Add provider config to server config schema

### Phase 6: CLI Integration
- [ ] Add CLI commands or extend existing commands
- [ ] Add provider config to CLI config store

## Critical Implementation Details

- **Path params:** Always `encodeURIComponent()` for domains, IDs
- **Query params:** Only include if `!== undefined`, join arrays with commas
- **Pagination:** Marker-based (not offset). Response: `{ total, marker }`
- **Timeouts:** Default 30s, per-request overrides supported
- **Multi-tenant:** customerId required; defaults to 'DEFAULT'
- **Auth formats vary:** GoDaddy uses `sso-key {key}:{secret}`, others differ
- **Nameservers:** Require 2-13 NS records
- **Premium holds:** 96-hour locks, check expiration before purchasing
- **Actions are async:** Many operations return an actionId — poll for completion

## Provider-Specific Knowledge

### GoDaddy
- **Auth:** `Authorization: sso-key {API_KEY}:{API_SECRET}`
- **Base URLs:** OTE: `https://api.ote-godaddy.com`, Prod: `https://api.godaddy.com`
- **API Version:** `/v2/` prefix on all paths
- **Customer paths:** `/v2/customers/{customerId}/domains/...`
- **Non-customer paths:** `/v2/domains/available`, `/v2/domains/tlds`, `/v2/domains/suggest`
- **Retryable statuses:** 429, 500, 502, 503, 504

### When Adding a New Provider
Study the provider's API docs for:
1. Authentication mechanism (API key, OAuth, HMAC, etc.)
2. Base URL structure and environments (sandbox/production)
3. Rate limits and retry policies
4. Error response format
5. Pagination approach
6. Async operation model (if any)
7. Which domain operations are supported
8. Provider-specific features not in the base model

## Key Source Files Reference

| File | Purpose |
|------|---------|
| `packages/sdk/src/client/index.ts` | Main client class |
| `packages/sdk/src/client/http-client.ts` | HTTP abstraction with auth/retry/rate-limit |
| `packages/sdk/src/client/auth.ts` | Authentication handler |
| `packages/sdk/src/client/retry.ts` | Retry logic with exponential backoff |
| `packages/sdk/src/client/rate-limiter.ts` | Window-based rate limiter |
| `packages/sdk/src/client/errors.ts` | Typed error classes |
| `packages/sdk/src/client/types.ts` | Config and request/response types |
| `packages/sdk/src/api/domains.ts` | Domains API (primary reference) |
| `packages/sdk/src/api/contacts.ts` | Contacts API |
| `packages/sdk/src/api/hosts.ts` | Hosts + DNSSEC API |
| `packages/sdk/src/api/actions.ts` | Action tracking + polling |
| `packages/sdk/src/api/notifications.ts` | Notifications API |
| `packages/sdk/src/api/premium.ts` | Premium domains API |
| `packages/sdk/src/api/premium/workflow.ts` | Purchase orchestration |
| `packages/sdk/src/types/` | All type definitions |
| `packages/sdk/src/index.ts` | Exports + module augmentation |
| `packages/server/src/services/godaddy.ts` | Server service wrapper |
| `packages/server/src/routes/` | REST API routes |
| `packages/server/src/middleware/` | Auth, rate-limit, tenant middleware |
| `packages/cli/src/` | CLI commands and config |

## Output Style

- Be precise and implementation-focused
- Show code following the exact patterns above
- When implementing a new provider, always reference the GoDaddy implementation as the template
- Flag where provider APIs differ from the base model
- Prioritize type safety — every request and response should be typed
- Follow TDD: write tests alongside implementation
