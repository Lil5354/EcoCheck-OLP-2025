# CN7 Deployment Checklist

**Feature:** CN7 - Incident Management & Dynamic Dispatch  
**Version:** 1.0.0  
**Date:** 2025-11-23

---

## Pre-Deployment Checklist

### 1. Code Review ✅
- [x] All code changes reviewed
- [x] No syntax errors or warnings
- [x] Follows project coding standards
- [x] Proper error handling implemented
- [x] Console logs appropriate (not excessive)

### 2. Dependencies ✅
- [x] `uuid` package added to `backend/package.json`
- [x] All existing dependencies compatible
- [x] No version conflicts

### 3. Database ✅
- [x] Migration 008 exists (`db/migrations/008_create_alerts_table.sql`)
- [x] PostGIS extension required (for ST_X, ST_Y functions)
- [x] No schema changes needed

### 4. Documentation ✅
- [x] Implementation summary created
- [x] Testing guide created
- [x] Quick reference created
- [x] API endpoints documented

---

## Deployment Steps

### Step 1: Install Dependencies
```bash
cd backend
npm install
```

**Verify:**
```bash
npm list uuid
# Should show: uuid@9.0.1
```

### Step 2: Verify Database
```bash
# Connect to database
psql -h localhost -U ecocheck_user -d ecocheck

# Check if alerts table exists
\dt alerts

# Check if PostGIS is enabled
SELECT PostGIS_Version();

# If not, enable it:
CREATE EXTENSION IF NOT EXISTS postgis;

# Verify migration 008 ran
SELECT * FROM alerts LIMIT 1;
```

### Step 3: Restart Backend
```bash
# If using Docker
docker compose restart backend

# Or if running locally
cd backend
npm run dev
```

**Verify:**
```bash
# Check health endpoint
curl http://localhost:3000/health

# Check alerts endpoint
curl http://localhost:3000/api/alerts
```

### Step 4: Restart Frontend
```bash
# If using Docker
docker compose restart frontend-web

# Or if running locally
cd frontend-web-manager
npm run dev
```

**Verify:**
- Open http://localhost:3001
- Navigate to "Điều phối động"
- Page loads without errors

### Step 5: Verify Cron Job
```bash
# Watch backend logs
docker logs -f ecocheck-backend

# Should see every 15 seconds:
# 🛰️  Running Missed Point Detection...
```

---

## Post-Deployment Verification

### Test 1: API Endpoints ✅

#### Get Alerts
```bash
curl http://localhost:3000/api/alerts
```
**Expected:** `{ "ok": true, "data": [...] }`

#### Dispatch Alert (Get Nearest Vehicles)
```bash
curl -X POST http://localhost:3000/api/alerts/1/dispatch
```
**Expected:** `{ "ok": true, "data": [vehicles...] }`

#### Assign Vehicle
```bash
curl -X POST http://localhost:3000/api/alerts/1/assign \
  -H "Content-Type: application/json" \
  -d '{"vehicle_id": "V02"}'
```
**Expected:** `{ "ok": true, "data": { "route_id": "...", ... } }`

### Test 2: Frontend UI ✅

1. Navigate to http://localhost:3001/operations/dynamic-dispatch
2. Verify table displays alerts (if any exist)
3. Click "Tạo tuyến mới" on an alert
4. Verify modal opens with vehicle list
5. Click "Giao việc" on a vehicle
6. Verify success toast appears
7. Verify alert status updates

### Test 3: End-to-End Workflow ✅

```bash
# 1. Start a test route
curl -X POST http://localhost:3000/api/test/start-route \
  -H "Content-Type: application/json" \
  -d '{"route_id": "test-1", "vehicle_id": "V01"}'

# 2. Wait 15-30 seconds for missed point detection

# 3. Check alerts
curl http://localhost:3000/api/alerts

# 4. Assign vehicle (use alert_id from step 3)
curl -X POST http://localhost:3000/api/alerts/1/assign \
  -H "Content-Type: application/json" \
  -d '{"vehicle_id": "V02"}'

# 5. Simulate check-in (use route_id from step 4)
curl -X POST http://localhost:3000/api/rt/checkin \
  -H "Content-Type: application/json" \
  -d '{"route_id": "...", "point_id": "P1", "vehicle_id": "V02"}'

# 6. Verify alert resolved
curl http://localhost:3000/api/alerts
# Alert status should be 'resolved'
```

---

## Rollback Plan

If issues occur, rollback using these steps:

### 1. Identify Last Good Commit
```bash
git log --oneline
# Find commit before CN7 implementation
```

### 2. Revert Code Changes
```bash
# Option A: Soft revert (keep changes as uncommitted)
git reset --soft <commit-hash>

# Option B: Hard revert (discard all changes)
git reset --hard <commit-hash>
```

### 3. Restore Dependencies
```bash
cd backend
npm install
```

### 4. Restart Services
```bash
docker compose restart backend frontend-web
```

### 5. Verify Rollback
```bash
# Check if new endpoints are gone
curl http://localhost:3000/api/alerts/1/assign
# Should return 404
```

---

## Monitoring

### Key Metrics to Watch

1. **Alert Creation Rate**
   ```sql
   SELECT COUNT(*), alert_type 
   FROM alerts 
   WHERE created_at > NOW() - INTERVAL '1 hour'
   GROUP BY alert_type;
   ```

2. **Alert Resolution Time**
   ```sql
   SELECT 
     AVG(EXTRACT(EPOCH FROM (details->>'resolved_at')::timestamptz - created_at)) as avg_seconds
   FROM alerts 
   WHERE status = 'resolved';
   ```

3. **Assignment Success Rate**
   ```sql
   SELECT 
     COUNT(*) FILTER (WHERE status IN ('acknowledged', 'resolved')) * 100.0 / COUNT(*) as success_rate
   FROM alerts;
   ```

### Log Monitoring

**Watch for these logs:**
- ✅ `[object Object] Detection...` (every 15s)
- ✅ `🚨 MISSED POINT DETECTED!` (when incident occurs)
- ✅ `🚨 LATE CHECK-IN DETECTED!` (when late check-in occurs)
- ✅ `✅ Alert X assigned to vehicle Y` (on assignment)
- ✅ `✅ Resolved N alert(s) for point X` (on resolution)

**Watch for errors:**
- ❌ Database connection errors
- ❌ Query syntax errors
- ❌ UUID generation errors
- ❌ PostGIS function errors

---

## Support Contacts

**Technical Issues:**
- Check `CN7_TESTING_GUIDE.md` for troubleshooting
- Review backend logs: `docker logs ecocheck-backend`
- Check database: `psql -h localhost -U ecocheck_user -d ecocheck`

**Documentation:**
- Implementation: `CN7_IMPLEMENTATION_SUMMARY.md`
- Testing: `CN7_TESTING_GUIDE.md`
- Quick Reference: `CN7_QUICK_REFERENCE.md`

---

## Sign-Off

- [ ] All pre-deployment checks passed
- [ ] Dependencies installed successfully
- [ ] Database verified
- [ ] Backend restarted and healthy
- [ ] Frontend restarted and accessible
- [ ] API endpoints tested
- [ ] Frontend UI tested
- [ ] End-to-end workflow verified
- [ ] Monitoring in place
- [ ] Team notified of deployment

**Deployed by:** _________________  
**Date:** _________________  
**Time:** _________________  
**Status:** _________________

---

**Last Updated:** 2025-11-23  
**Version:** 1.0.0

