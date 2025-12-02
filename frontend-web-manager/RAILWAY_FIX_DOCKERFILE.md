# 🔧 Fix: Dockerfile does not exist on Railway

## Problem
Railway error: `Dockerfile 'Dockerfile.railway' does not exist`

## Root Cause
The Dockerfile Path in Railway Settings is configured incorrectly relative to the Root Directory.

## ✅ Solution: Fix Railway Settings

### Step 1: Check Root Directory
1. Go to Railway Dashboard → Frontend Service → **Settings** tab
2. Find **Source** section
3. Check **Root Directory** value:
   - ✅ **CORRECT**: `frontend-web-manager` (no leading/trailing slashes)
   - ❌ **WRONG**: Empty, `.`, or `frontend-web-manager/`

### Step 2: Fix Dockerfile Path Based on Root Directory

#### If Root Directory = `frontend-web-manager`:
1. Go to **Settings** → **Build** section
2. Find **Dockerfile Path** field
3. **CHANGE** from: `frontend-web-manager/Dockerfile.railway`
4. **TO**: `Dockerfile.railway` (relative path, no prefix)
5. Click **Save**

#### If Root Directory is EMPTY:
1. **First**, set Root Directory = `frontend-web-manager` in **Source** section
2. Then set Dockerfile Path = `Dockerfile.railway` (relative)
3. Click **Save**

### Step 3: Verify Environment Variable
1. Go to **Variables** tab
2. Ensure `RAILWAY_DOCKERFILE_PATH=frontend-web-manager/Dockerfile.railway` exists
3. If it exists, you can either:
   - **Option A**: Keep it and clear Dockerfile Path in Settings (let env var override)
   - **Option B**: Remove env var and use Settings configuration

### Step 4: Redeploy
1. Go to **Deployments** tab
2. Click **Redeploy** or push a new commit
3. Check build logs - should see:
   - ✅ `FROM node:22-alpine AS build`
   - ✅ `FROM nginx:alpine`
   - ❌ NO `RUN apk add --no-cache curl postgresql-client` (backend commands)

## 📋 Quick Checklist

- [ ] Root Directory = `frontend-web-manager` (in Settings → Source)
- [ ] Dockerfile Path = `Dockerfile.railway` (relative, in Settings → Build)
- [ ] `RAILWAY_DOCKERFILE_PATH` env var exists (optional, can override Settings)
- [ ] Redeployed service
- [ ] Build logs show frontend Dockerfile (node:22-alpine, nginx:alpine)

## 🎯 Expected Result

After fixing, Railway should:
1. Find `Dockerfile.railway` in `frontend-web-manager/` directory
2. Build successfully with frontend configuration
3. Deploy nginx server listening on Railway's PORT


