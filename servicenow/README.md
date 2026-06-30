# 恋爱积分簿 — ServiceNow Setup Guide

Instance: **dev405150.service-now.com**

---

## Step 1 — Create Tables

Go to **System Definition → Tables → New** and create these 6 tables:

### Table 1: `u_love_config` (App Configuration)
| Field Name | Type | Label | Default |
|---|---|---|---|
| u_mode | String(20) | 模式 | `reward` |
| u_reward_target | Integer | 奖励目标分 | `100` |
| u_punish_threshold | Integer | 惩罚阈值分 | `-80` |

### Table 2: `u_love_category` (Score Categories)
| Field Name | Type | Label |
|---|---|---|
| u_name | String(100) | 名称 |
| u_icon | String(10) | 图标(Emoji) |
| u_pts | Integer | 分数 |
| u_active | True/False | 启用 |

### Table 3: `u_love_entry` (Score Entries)
| Field Name | Type | Label |
|---|---|---|
| u_category | Reference → u_love_category | 分类 |
| u_icon | String(10) | 图标 |
| u_pts | Integer | 分数 |
| u_description | String(500) | 说明 |
| u_month | String(7) | 月份 (YYYY-MM) |
| u_date | Date | 日期 |

### Table 4: `u_love_reward` (Reward Tiers)
| Field Name | Type | Label |
|---|---|---|
| u_name | String(100) | 奖励名称 |
| u_icon | String(10) | 图标 |
| u_min_pts | Integer | 最低分数 |
| u_description | String(500) | 说明 |

### Table 5: `u_love_punishment` (Punishment Tiers)
| Field Name | Type | Label |
|---|---|---|
| u_name | String(100) | 惩罚名称 |
| u_icon | String(10) | 图标 |
| u_min_pts | Integer | 最低负分（绝对值）|
| u_description | String(500) | 说明 |

### Table 6: `u_love_monthly` (Monthly Settlements)
| Field Name | Type | Label |
|---|---|---|
| u_month | String(7) | 月份 (YYYY-MM) |
| u_total_pts | Integer | 总分 |
| u_mode | String(20) | 模式 |
| u_result_name | String(200) | 结果名称 |
| u_settled_at | Date/Time | 结算时间 |

---

## Step 2 — Seed Default Data

1. Go to **System Definition → Scripts → Background**
2. Paste the contents of `background-setup.js`
3. Click **Run script**
4. Check the output log — should see "Setup Complete!"

---

## Step 3 — Create Scripted REST API

1. Go to **System Web Services → Scripted REST APIs → New**
2. Fill in:
   - **Name**: Love Score API
   - **API ID**: `love_score`
   - **Base API path**: `/api/global/love_score`
3. Save the record
4. Open the **Resources** related list and add **10 resources**:

| # | Name | HTTP Method | Relative Path |
|---|---|---|---|
| 1 | Get Config | GET | `/config` |
| 2 | Update Config | PUT | `/config` |
| 3 | Get Categories | GET | `/categories` |
| 4 | Get Entries | GET | `/entries` |
| 5 | Add Entry | POST | `/entries` |
| 6 | Delete Entry | DELETE | `/entries/{id}` |
| 7 | Get Rewards | GET | `/rewards` |
| 8 | Get Punishments | GET | `/punishments` |
| 9 | Get History | GET | `/history` |
| 10 | Settle Month | POST | `/monthly/settle` |

For each resource, paste the corresponding code block from `scripted-rest-api.js`.

---

## Step 4 — Enable CORS

1. Go to **System Web Services → REST API Explorer**
2. Open **CORS Rules** (left panel)
3. Click **New**
4. Set:
   - **REST API**: Love Score API
   - **Domain**: `*` (or your specific host / `file://` for local HTML)
   - **HTTP Methods**: GET, POST, PUT, DELETE
5. Save

---

## Step 5 — Test the API

Open REST API Explorer or use curl:

```bash
# Test config endpoint
curl -u admin:password \
  "https://dev405150.service-now.com/api/global/love_score/config"

# Test categories
curl -u admin:password \
  "https://dev405150.service-now.com/api/global/love_score/categories"
```

---

## Step 6 — Connect the Frontend

1. Open `index.html` in your browser (Chrome/Safari/Firefox)
2. Enter:
   - **SN Instance**: `dev405150.service-now.com`
   - **Username**: your SN admin username
   - **Password**: your SN admin password
3. Click **连接**

> **Note**: If running from `file://`, make sure your CORS rule allows `*`.
> For production use, host the HTML on a web server with a fixed domain.

---

## Modifying Tables

| What to change | Where |
|---|---|
| Add/edit score categories | `u_love_category` table in SN |
| Add/edit reward tiers | `u_love_reward` table in SN |
| Add/edit punishments | `u_love_punishment` table in SN |
| Change target score | App Settings (⚙️ button) or `u_love_config` table |
| View monthly history | `u_love_monthly` table in SN or History tab in app |

---

## Architecture

```
Browser (index.html + app.js)
        │
        │ HTTPS REST (Basic Auth)
        ▼
ServiceNow (dev405150.service-now.com)
  ├── Scripted REST API (/api/global/love_score/*)
  ├── u_love_config       — App settings
  ├── u_love_category     — Score categories (editable)
  ├── u_love_entry        — Individual entries per month
  ├── u_love_reward       — Reward tiers (editable)
  ├── u_love_punishment   — Punishment tiers (editable)
  └── u_love_monthly      — Settled month records
```

---

## Demo Mode (No SN Needed)

Click **"跳过 → 使用本地模式"** on the login screen.  
All data is stored in browser `localStorage`. Great for testing!
