#!/bin/bash
# ============================================================
# 恋爱积分簿 — Full API Test (custom auth, token-based)
#
# Usage:
#   # Full run: registers 2 fresh test accounts and pairs them
#   bash servicenow/test-api.sh
#
#   # Login only (account already exists):
#   bash servicenow/test-api.sh --login <username> <password>
# ============================================================

INSTANCE="dev405150.service-now.com"
BASE="https://${INSTANCE}/api/x_887486_love_app/love_score"
PUB_HEADERS=(-H "Content-Type: application/json" -H "Accept: application/json")

PASS_COUNT=0
FAIL_COUNT=0
API_KEY=""
MATCH_ID=""
PAIR_CODE=""
CREATED_ENTRY_ID=""
CREATED_CAT_ID=""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ PASS${NC} — $1"; ((PASS_COUNT++)); }
fail() { echo -e "${RED}❌ FAIL${NC} — $1"; ((FAIL_COUNT++)); }
info() { echo -e "${YELLOW}   → $1${NC}"; }
section() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

auth_headers() { echo "-H" "Authorization: Bearer ${API_KEY}" "-H" "Content-Type: application/json" "-H" "Accept: application/json"; }

echo ""
echo "============================================================"
echo "  恋爱积分簿 — API Full Test (custom token auth)"
echo "  Instance : ${INSTANCE}"
echo "  Base URL : ${BASE}"
echo "============================================================"

# ── MODE: login only ─────────────────────────────────────────
if [ "$1" = "--login" ]; then
  USERNAME="$2"; PASSWORD="$3"
  if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: bash servicenow/test-api.sh --login <username> <password>"
    exit 1
  fi
  section "LOGIN"
  RES=$(curl -s -w "\n%{http_code}" -X POST "${BASE}/auth/login" "${PUB_HEADERS[@]}" \
    -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}")
  HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
  API_KEY=$(echo "$BODY" | grep -o '"apiKey":"[^"]*"' | cut -d'"' -f4)
  MATCH_ID=$(echo "$BODY" | grep -o '"matchId":"[^"]*"' | cut -d'"' -f4)
  if [ "$HTTP" = "200" ] && [ -n "$API_KEY" ]; then
    pass "Login → HTTP $HTTP | matchId=${MATCH_ID:-<empty>}"
    info "$BODY"
  else
    fail "Login → HTTP $HTTP"; info "$BODY"; exit 1
  fi
  echo ""; echo "API_KEY=${API_KEY}"; echo "MATCH_ID=${MATCH_ID}"; exit 0
fi

# ── REGISTER TWO TEST ACCOUNTS ────────────────────────────────
TS=$(date +%s)
USER1="test_cs_${TS}"
USER2="test_tt_${TS}"
PASS1="pass_cs_${TS}"
PASS2="pass_tt_${TS}"

section "REGISTER: char1 (他) — ${USER1}"
RES=$(curl -s -w "\n%{http_code}" -X POST "${BASE}/auth/register" "${PUB_HEADERS[@]}" \
  -d "{\"username\":\"${USER1}\",\"password\":\"${PASS1}\",\"charId\":\"char1\"}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
PAIR_CODE=$(echo "$BODY" | grep -o '"pairCode":"[^"]*"' | cut -d'"' -f4)
API_KEY1=$(echo "$BODY" | grep -o '"apiKey":"[^"]*"' | cut -d'"' -f4)
if [ "$HTTP" = "201" ] && [ -n "$API_KEY1" ] && [ -n "$PAIR_CODE" ]; then
  pass "POST /auth/register → HTTP $HTTP | pairCode=${PAIR_CODE}"
  info "$BODY"
else
  fail "POST /auth/register → HTTP $HTTP"; info "$BODY"
  echo -e "${RED}Cannot continue.${NC}"; exit 1
fi

section "REGISTER: char2 (她) — ${USER2} with pair code ${PAIR_CODE}"
RES=$(curl -s -w "\n%{http_code}" -X POST "${BASE}/auth/register" "${PUB_HEADERS[@]}" \
  -d "{\"username\":\"${USER2}\",\"password\":\"${PASS2}\",\"charId\":\"char2\",\"pairCode\":\"${PAIR_CODE}\"}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
API_KEY2=$(echo "$BODY" | grep -o '"apiKey":"[^"]*"' | cut -d'"' -f4)
MATCH_ID=$(echo "$BODY" | grep -o '"matchId":"[^"]*"' | cut -d'"' -f4)
if [ "$HTTP" = "201" ] && [ -n "$MATCH_ID" ]; then
  pass "POST /auth/register (char2) → HTTP $HTTP | matchId=${MATCH_ID}"
  info "$BODY"
else
  fail "POST /auth/register (char2) → HTTP $HTTP"; info "$BODY"
  echo -e "${RED}Cannot continue.${NC}"; exit 1
fi

section "LOGIN: verify char1 after pairing"
RES=$(curl -s -w "\n%{http_code}" -X POST "${BASE}/auth/login" "${PUB_HEADERS[@]}" \
  -d "{\"username\":\"${USER1}\",\"password\":\"${PASS1}\"}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
API_KEY=$(echo "$BODY" | grep -o '"apiKey":"[^"]*"' | cut -d'"' -f4)
if [ "$HTTP" = "200" ] && [ -n "$API_KEY" ]; then
  pass "POST /auth/login → HTTP $HTTP"
  info "$BODY"
else
  fail "POST /auth/login → HTTP $HTTP"; info "$BODY"; exit 1
fi
# Use char1's token for remaining tests
AUTH_H=(-H "Authorization: Bearer ${API_KEY}" -H "Content-Type: application/json" -H "Accept: application/json")

# ── TESTS 1–10 ────────────────────────────────────────────────
section "CONFIG"
echo "TEST 1: GET /config"
RES=$(curl -s -w "\n%{http_code}" "${BASE}/config" "${AUTH_H[@]}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
[ "$HTTP" = "200" ] && pass "GET /config → $HTTP" || fail "GET /config → $HTTP"; info "$BODY"

echo ""
echo "TEST 2: PUT /config"
RES=$(curl -s -w "\n%{http_code}" -X PUT "${BASE}/config" "${AUTH_H[@]}" \
  -d '{"mode":"reward","rewardTarget":100,"punishThreshold":-80}')
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
[ "$HTTP" = "200" ] && pass "PUT /config → $HTTP" || fail "PUT /config → $HTTP"; info "$BODY"

section "CATEGORIES"
echo "TEST 3: GET /categories"
RES=$(curl -s -w "\n%{http_code}" "${BASE}/categories" "${AUTH_H[@]}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
COUNT=$(echo "$BODY" | grep -o '"id"' | wc -l | tr -d ' ')
[ "$HTTP" = "200" ] && pass "GET /categories → $HTTP | ${COUNT} categories" || fail "GET /categories → $HTTP"; info "$BODY"

echo ""
echo "TEST 4: POST /categories"
RES=$(curl -s -w "\n%{http_code}" -X POST "${BASE}/categories" "${AUTH_H[@]}" \
  -d '{"icon":"🧪","name":"API测试分类","pts":5}')
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
CREATED_CAT_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
[ "$HTTP" = "201" ] && [ -n "$CREATED_CAT_ID" ] && \
  pass "POST /categories → $HTTP | id=${CREATED_CAT_ID}" || fail "POST /categories → $HTTP"; info "$BODY"

section "REWARDS & PUNISHMENTS"
echo "TEST 5: GET /rewards"
RES=$(curl -s -w "\n%{http_code}" "${BASE}/rewards" "${AUTH_H[@]}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
COUNT=$(echo "$BODY" | grep -o '"id"' | wc -l | tr -d ' ')
[ "$HTTP" = "200" ] && pass "GET /rewards → $HTTP | ${COUNT} rewards" || fail "GET /rewards → $HTTP"

echo ""
echo "TEST 6: GET /punishments"
RES=$(curl -s -w "\n%{http_code}" "${BASE}/punishments" "${AUTH_H[@]}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
COUNT=$(echo "$BODY" | grep -o '"id"' | wc -l | tr -d ' ')
[ "$HTTP" = "200" ] && pass "GET /punishments → $HTTP | ${COUNT} punishments" || fail "GET /punishments → $HTTP"

section "ENTRIES"
TODAY=$(date +%Y-%m-%d); MONTH=$(date +%Y-%m)
echo "TEST 7: POST /entries"
RES=$(curl -s -w "\n%{http_code}" -X POST "${BASE}/entries" "${AUTH_H[@]}" \
  -d "{\"charId\":\"char1\",\"catId\":\"\",\"catName\":\"API测试分类\",\"icon\":\"🧪\",\"pts\":5,\"desc\":\"自动测试\",\"month\":\"${MONTH}\",\"date\":\"${TODAY}\"}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
CREATED_ENTRY_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
[ "$HTTP" = "201" ] && [ -n "$CREATED_ENTRY_ID" ] && \
  pass "POST /entries → $HTTP | id=${CREATED_ENTRY_ID}" || fail "POST /entries → $HTTP"; info "$BODY"

echo ""
echo "TEST 8: GET /entries"
RES=$(curl -s -w "\n%{http_code}" "${BASE}/entries?month=${MONTH}" "${AUTH_H[@]}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
[ "$HTTP" = "200" ] && pass "GET /entries → $HTTP" || fail "GET /entries → $HTTP"

echo ""
echo "TEST 9: PUT /entries/${CREATED_ENTRY_ID}"
if [ -n "$CREATED_ENTRY_ID" ]; then
  RES=$(curl -s -w "\n%{http_code}" -X PUT "${BASE}/entries/${CREATED_ENTRY_ID}" "${AUTH_H[@]}" \
    -d '{"desc":"更新后的描述","pts":10}')
  HTTP=$(echo "$RES" | tail -1)
  [ "$HTTP" = "200" ] && pass "PUT /entries/{id} → $HTTP" || fail "PUT /entries/{id} → $HTTP"
else
  fail "PUT /entries/{id} — skipped (no entry id)"
fi

section "HISTORY"
echo "TEST 10: GET /history"
RES=$(curl -s -w "\n%{http_code}" "${BASE}/history" "${AUTH_H[@]}")
HTTP=$(echo "$RES" | tail -1); BODY=$(echo "$RES" | head -1)
[ "$HTTP" = "200" ] && pass "GET /history → $HTTP" || fail "GET /history → $HTTP"

section "CLEANUP"
if [ -n "$CREATED_ENTRY_ID" ]; then
  echo "DELETE /entries/${CREATED_ENTRY_ID}"
  RES=$(curl -s -w "\n%{http_code}" -X DELETE "${BASE}/entries/${CREATED_ENTRY_ID}" "${AUTH_H[@]}")
  HTTP=$(echo "$RES" | tail -1)
  [ "$HTTP" = "200" ] && pass "DELETE /entries/{id} → $HTTP ✅" || fail "DELETE /entries/{id} → $HTTP"
fi
if [ -n "$CREATED_CAT_ID" ]; then
  echo "DELETE /categories/${CREATED_CAT_ID}"
  RES=$(curl -s -w "\n%{http_code}" -X DELETE "${BASE}/categories/${CREATED_CAT_ID}" "${AUTH_H[@]}")
  HTTP=$(echo "$RES" | tail -1)
  [ "$HTTP" = "200" ] && pass "DELETE /categories/{id} → $HTTP ✅" || fail "DELETE /categories/{id} → $HTTP"
fi

# ── SUMMARY ───────────────────────────────────────────────────
echo ""
echo "============================================================"
echo -e "  RESULTS: ${GREEN}${PASS_COUNT} passed${NC}  |  ${RED}${FAIL_COUNT} failed${NC}"
echo "============================================================"
if [ "$FAIL_COUNT" -eq "0" ]; then
  echo -e "${GREEN}🎉 All tests passed!${NC}"
else
  echo -e "${RED}⚠️  ${FAIL_COUNT} test(s) failed — check output above.${NC}"
  echo ""
  echo "Common causes:"
  echo "  401 → bad/expired token or 'Requires Authentication' still TRUE in SN"
  echo "  404 → API path wrong or resource not created in SN"
  echo "  u_password / u_api_key fields missing from u_love_auth"
  echo "  u_pair_code field missing from u_love_match"
fi
echo ""
