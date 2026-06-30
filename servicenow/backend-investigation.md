# ServiceNow Backend Investigation
## 恋爱积分簿 — Two-User Sharing Design

---

## Current Architecture (v1)

```
Browser → Basic Auth → Global Scripted REST API → SN Tables (u_love_*)
```

**Works for**: single user, quick setup  
**Problems for two users**: authentication, no user tracking, images can't sync

---

## Two-User Sharing — The Core Problem

The two of you want to **both open the app on your own phones** and see **the same score data in real time**. ServiceNow is perfect as the shared backend — but you need the right auth strategy.

### Option A: Shared Service Account ✅ (Recommended for personal use)

Create **one dedicated SN user** that the app uses on both phones.

```
Phone A (你) ──┐
               ├──► love_score_service (SN user) ──► SN Tables (shared)
Phone B (他) ──┘
```

**Steps:**
1. In SN: **User Admin → Users → New**
   - User ID: `love_score_service`
   - Password: choose a strong password
   - First name: Love Score, Last name: Bot
   - **Active**: true, **Web service access only**: true
2. Create a custom role: `x_love_score_user`
   - Go to: User Administration → Roles → New
   - Name: `x_love_score_user`
3. Grant that role Read/Write ACLs only on the 6 love score tables
4. Assign the role to `love_score_service`
5. Both phones use these same credentials in the app

**Pro**: Simple, no separate logins needed  
**Con**: If credentials leak, anyone can write to your tables

---

### Option B: Two Named SN Users (More Secure)

Create **two SN users**, one per person. Both can read/write the shared tables.

```
Phone A → user: ycs_love  → SN Tables (shared)
Phone B → user: him_love  → SN Tables (shared)
```

**Steps** (same as Option A, but create two users):
1. User 1: `ycs_love` (you)
2. User 2: `partner_love` (him)
3. Both get role `x_love_score_user`
4. You enter your credentials in the app, he enters his

**Pro**: Audit trail (can see who added which entry), individual passwords  
**Con**: Slightly more setup; need to re-enable login UI in app

**To re-enable login**: In `app.js`, change `boot()` back to prompt for credentials:
```js
async function boot() {
  document.getElementById('setup-overlay').classList.remove('hidden');
  // or restore session from localStorage
}
```

---

### Option C: OAuth / API Key (Best Security, Most Complex)

Use SN's OAuth 2.0 with a client credentials flow. Not practical for a personal couple's app — skip this unless you want enterprise-level security.

---

## Recommended Setup for Your Case

**Use Option A (Service Account)** — here's the complete setup:

### 1. Create ACL Role in SN

Go to: **System Definition → Roles → New**
```
Name:        x_love_score_user
Description: Love Score App access
Suffix:      x_love_score_user
```

### 2. Create ACLs for each table

Go to: **Security → Access Control (ACL) → New**  
Repeat for all 6 tables: `u_love_config`, `u_love_category`, `u_love_entry`, `u_love_reward`, `u_love_punishment`, `u_love_monthly`

For each table, create **2 ACLs**:
- **Read**: Operation = read, Roles = x_love_score_user
- **Write**: Operation = write, Roles = x_love_score_user

### 3. Create the service user

```
User ID:              love_score_service
Password:             (set a strong password — save it!)
Web service access only: ✓ (checked)
Role:                 x_love_score_user
```

### 4. CORS Configuration (critical for browser access)

Go to: **System Web Services → REST API Explorer → CORS Rules → New**
```
REST API:     Love Score API (your scripted REST API)
Domain:       *
HTTP Methods: GET, POST, PUT, DELETE
Max Age:      3600
```

---

## Table Design — What Should Go in SN vs. Browser

| Data | Storage | Why |
|------|---------|-----|
| Score entries | SN `u_love_entry` | Must be shared between users |
| Monthly history | SN `u_love_monthly` | Permanent record, shared |
| Categories | SN `u_love_category` | Shared, admin can edit in SN |
| Rewards / Punishments | SN `u_love_reward` / `u_love_punishment` | Shared, editable |
| Mode, thresholds | SN `u_love_config` | Shared setting |
| **Character names** | SN `u_love_config` | **Add these fields** (see below) |
| **Character images** | Browser localStorage only | Base64 is too large for SN text fields |

### Add Name Fields to `u_love_config`

Add two String(50) fields:
- `u_char_name1` — default: `Pochacco`
- `u_char_name2` — default: `阿呆`

Then update the GET /config and PUT /config API endpoints to include these.

> **Note on images**: Character images are stored in each phone's localStorage separately (they're big base64 strings). This means each person sets their own image independently. If you want truly shared images, you'd need to either:
> - Store them as SN Attachments (complex)
> - Host them at a public URL and store just the URL in SN config

---

## Adding "Who Added This" Tracking

Once you have two named users, add a `u_added_by` field to `u_love_entry`:

```javascript
// In POST /entries resource:
gr.setValue('u_added_by', gs.getUserDisplayName()); // auto-filled from logged-in user
```

Then in the frontend entry list, show who added each entry:
```
💑 陪伴时光  +10   [你]
⏰ 约会迟到   -5   [他]
```

---

## Real-Time Sync Between Two Phones

SN doesn't push updates — the app must poll. Add auto-refresh:

```javascript
// In app.js boot():
setInterval(async () => {
  if (document.visibilityState === 'visible') {
    const entries = await Data.getEntries(S.month);
    if (JSON.stringify(entries) !== JSON.stringify(S.entries)) {
      S.entries = entries;
      // re-render entries and score
    }
  }
}, 30000); // refresh every 30 seconds
```

Or add a manual "sync" pull-to-refresh button.

---

## Complete Recommended Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   ServiceNow (dev405150)                    │
│                                                             │
│  Scripted REST API (/api/global/love_score/*)               │
│  ├── /config          GET/PUT — shared settings + names    │
│  ├── /categories      GET — shared score categories        │
│  ├── /entries         GET/POST/DELETE — monthly records     │
│  ├── /rewards         GET — reward tiers                   │
│  ├── /punishments     GET — punishment tiers               │
│  └── /history         GET + /monthly/settle POST           │
│                                                             │
│  Tables (all shared):                                       │
│  u_love_config    ← mode, thresholds, char names          │
│  u_love_category  ← editable score categories             │
│  u_love_entry     ← who added, when, how many points      │
│  u_love_reward    ← reward tiers (admin editable)         │
│  u_love_punishment← punishment tiers (admin editable)     │
│  u_love_monthly   ← settled months history                │
│                                                             │
│  Auth: love_score_service (shared service account)         │
│  OR:   ycs_love + partner_love (named users)               │
└─────────────────────────────────────────────────────────────┘
         ▲ HTTPS REST (Basic Auth) + CORS enabled
         │
┌────────┴────────┐    ┌─────────────────┐
│   Phone A (你)  │    │   Phone B (他)  │
│  index.html     │    │  index.html     │
│  Shared data ✓  │    │  Shared data ✓  │
│  Own image ✓    │    │  Own image ✓    │
└─────────────────┘    └─────────────────┘
```

---

## Quick Checklist to Go Live

- [ ] Create 6 tables in SN (see README.md)
- [ ] Run background-setup.js to seed default data  
- [ ] Create Scripted REST API with 10 resources
- [ ] Create `love_score_service` user with role and ACLs
- [ ] Enable CORS rule for the REST API
- [ ] Add `u_char_name1` + `u_char_name2` fields to `u_love_config`
- [ ] Update GET/PUT /config endpoints to include name fields
- [ ] Re-enable login in app (or hardcode service account credentials)
- [ ] Test from both phones
- [ ] Add auto-refresh polling (optional)
