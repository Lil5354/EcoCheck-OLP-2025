# Schedule & Check-in Unification - Implementation Summary

## Overview
Merged "Đặt lịch" (Schedule) and "Check-in rác" (Check-in) into a single unified feature called "Yêu cầu thu gom" (Waste Collection Request).

## Problem Statement
Previously, the app had two separate features that were conceptually the same:
- **Check-in rác** (CheckInPage): User submits "I have waste" with type, weight, location
- **Đặt lịch** (ScheduleListPage): User views/manages scheduled pickups

This caused:
- Confusing UX (same workflow split across different pages)
- Duplicate navigation entries
- Unclear user mental model

## Solution
Unified both features into a single coherent workflow:
1. User has waste → Creates collection request (CreateRequestPage)
2. System creates schedule record
3. User views requests in "Schedule" tab
4. Worker collects and confirms

---

## Changes Made

### 1. Created New Page: `create_request_page.dart`
**Location**: `lib/presentation/pages/checkin/create_request_page.dart`

**Features**:
- Replaces old CheckInPage
- Form with 5 sections:
  1. Waste type selection (organic, recyclable, hazardous)
  2. Weight estimation (1-50kg slider)
  3. Scheduled date (date picker)
  4. Time slot selection (morning/afternoon/evening)
  5. GPS location display
- Rewards preview based on waste type and weight
- Integrated with ScheduleBloc for backend submission
- BlocListener for state handling (loading, success, error)

**Key Improvements**:
- Changed title from "Check-in Rác" → "Yêu cầu thu gom rác"
- Changed subtitle from "Giúp hệ thống biết bạn có rác" → "Đặt lịch thu gom rác tại nhà bạn"
- Changed button from "Check-in ngay" → "Tạo yêu cầu"
- Added date and time slot selectors (previously immediate)

---

### 2. Updated ScheduleBloc
**Location**: `lib/presentation/blocs/schedule/schedule_bloc.dart`

**Changes**:
- Added `EcoCheckRepository` dependency injection
- Marked as using mock data (TODO: Backend Schedule API not implemented)
- Methods:
  - `_onSchedulesLoaded`: Load schedules (filtered by status)
  - `_onScheduleCreateRequested`: Create new schedule
  - `_onScheduleCancelRequested`: Cancel existing schedule
  - `_onScheduleDetailRequested`: Get schedule details

**Backend Integration Status**:
- ⚠️ **Currently using mock data** - Backend `/api/schedules` endpoints not yet implemented
- TODO comments added for future backend integration
- Structure ready for API connection when available

---

### 3. Updated ScheduleListPage
**Location**: `lib/presentation/pages/schedule/schedule_list_page.dart`

**Changes**:
- Converted from StatefulWidget to StatelessWidget with BlocProvider
- Replaced mock data with BlocBuilder<ScheduleBloc, ScheduleState>
- Added loading, error, and empty states
- 3 tabs: "Chờ xác nhận", "Đã xác nhận", "Hoàn thành"
- FAB button text: "Đặt lịch mới" → "Yêu cầu thu gom"
- FAB now navigates to CreateRequestPage (instead of CreateSchedulePage)

**State Handling**:
- `ScheduleLoading`: Shows CircularProgressIndicator
- `ScheduleError`: Shows error message with retry button
- `ScheduleLoaded`: Displays schedules in tabs

---

### 4. Updated Navigation (HomePage)
**Location**: `lib/presentation/pages/home/widgets/quick_actions_grid.dart`

**Changes**:
- Changed quick action title: "Check-in rác" → "Yêu cầu thu gom"
- Navigation now wraps CreateRequestPage with BlocProvider<ScheduleBloc>
- Added necessary imports (flutter_bloc, injection_container)

**Navigation Flow**:
```
HomePage Quick Actions 
  → "Yêu cầu thu gom" button
  → BlocProvider(ScheduleBloc) 
  → CreateRequestPage
  → Success → Back to HomePage
```

---

### 5. Updated Dependency Injection
**Location**: `lib/core/di/injection_container.dart`

**Changes**:
```dart
// Before
sl.registerFactory(() => ScheduleBloc());

// After
sl.registerFactory(() => ScheduleBloc(repository: sl<EcoCheckRepository>()));
```

**Result**: ScheduleBloc now receives EcoCheckRepository for backend calls

---

## File Structure Changes

### Created Files:
- `lib/presentation/pages/checkin/create_request_page.dart` ✅

### Modified Files:
- `lib/presentation/blocs/schedule/schedule_bloc.dart` ✅
- `lib/presentation/pages/schedule/schedule_list_page.dart` ✅
- `lib/presentation/pages/home/widgets/quick_actions_grid.dart` ✅
- `lib/core/di/injection_container.dart` ✅

### Deprecated Files (Not Deleted):
- `lib/presentation/pages/checkin/checkin_page.dart` ⚠️ (Old version, kept for reference)
- `lib/presentation/pages/schedule/create_schedule_page.dart` ⚠️ (Similar functionality, may merge later)

---

## User Experience Flow

### Before:
```
1. User clicks "Check-in rác" → Immediate submission
2. User clicks "Đặt lịch" → Schedule for later
   → Two separate mental models
```

### After:
```
1. User clicks "Yêu cầu thu gom" → Single unified form
   → Choose date & time
   → Submit request
2. User views all requests in "Schedule" tab
   → Clear status tracking
```

---

## Technical Architecture

### State Management:
```
CreateRequestPage
  ├─ BlocProvider<ScheduleBloc>
  ├─ BlocListener (for navigation)
  └─ Form with local state (_selectedWasteType, _estimatedWeight, etc.)

ScheduleListPage
  ├─ BlocProvider<ScheduleBloc>
  ├─ BlocBuilder (for UI updates)
  └─ TabController (3 tabs by status)
```

### Data Flow:
```
User submits form
  → ScheduleCreateRequested event
  → ScheduleBloc processes
  → (TODO: Call backend API)
  → Currently: Add to mock list
  → Emit ScheduleCreated state
  → BlocListener navigates back
  → ScheduleListPage auto-reloads
```

---

## Backend API Requirements (TODO)

### Endpoints Needed:
1. `POST /api/schedules` - Create new schedule
   - Body: `{scheduledDate, timeSlot, wasteType, estimatedWeight, latitude, longitude, address}`
   - Returns: Created schedule object

2. `GET /api/schedules?citizenId=xxx&status=pending` - Get schedules
   - Query params: `citizenId`, `status` (optional)
   - Returns: Array of schedules

3. `PATCH /api/schedules/:id/cancel` - Cancel schedule
   - Returns: Updated schedule with status=cancelled

4. `GET /api/schedules/:id` - Get schedule details
   - Returns: Single schedule object

### Repository Methods to Implement:
```dart
// lib/data/repositories/ecocheck_repository.dart

Future<List<ScheduleModel>> getSchedules({
  String? citizenId,
  String? status,
});

Future<ScheduleModel> createSchedule({
  required DateTime scheduledDate,
  required String timeSlot,
  required String wasteType,
  required double estimatedWeight,
  required double latitude,
  required double longitude,
  required String address,
});

Future<ScheduleModel> cancelSchedule(String scheduleId);

Future<ScheduleModel> getScheduleDetail(String scheduleId);
```

---

## Testing Checklist

### Manual Testing:
- [x] Navigate to "Yêu cầu thu gom" from HomePage quick action
- [x] Fill form with all required fields
- [x] Select date from date picker
- [x] Select time slot
- [x] Adjust weight slider
- [x] Submit request
- [x] Verify success dialog appears
- [x] Navigate back to HomePage
- [x] Go to "Schedule" tab
- [ ] Verify new request appears in "Chờ xác nhận" tab
- [ ] Test cancel functionality
- [ ] Test pull-to-refresh

### Backend Integration (When Available):
- [ ] Replace mock data in ScheduleBloc
- [ ] Test create schedule API call
- [ ] Test get schedules API call
- [ ] Test cancel schedule API call
- [ ] Verify real-time updates
- [ ] Test error handling (network errors, validation errors)

---

## Known Issues & Limitations

1. **Backend API Not Implemented**
   - Currently using mock data in ScheduleBloc
   - All TODO comments marked in code
   - Structure ready for backend integration

2. **GPS Location**
   - Currently using hardcoded mock location (10.762622, 106.660172)
   - TODO: Implement real GPS location service

3. **User ID**
   - Currently using hardcoded 'user-123'
   - TODO: Get from AuthBloc/SharedPreferences

4. **Old CheckInPage**
   - Old file still exists: `lib/presentation/pages/checkin/checkin_page.dart`
   - Not deleted to preserve reference
   - Recommendation: Delete after verification

5. **CreateSchedulePage**
   - Similar functionality to CreateRequestPage
   - May need to merge or remove duplicate

---

## Migration Notes

### For Backend Team:
1. Implement `/api/schedules` CRUD endpoints
2. Follow ScheduleModel structure in `lib/data/models/schedule_model.dart`
3. Return timestamps in ISO 8601 format
4. Support status filtering in GET endpoint

### For Frontend Team:
1. When backend ready:
   - Update `ecocheck_repository.dart` with schedule methods
   - Remove TODO comments in `schedule_bloc.dart`
   - Replace mock data logic with API calls
   - Add proper error handling
2. Implement GPS location service
3. Get user ID from auth state instead of hardcoded value

---

## Success Metrics

### User Experience:
- ✅ Single unified "Yêu cầu thu gom" feature
- ✅ Clear workflow: Create → View → Track
- ✅ Consistent terminology across app
- ✅ BLoC pattern for state management

### Code Quality:
- ✅ Separation of concerns (BLoC + Repository)
- ✅ Dependency injection
- ✅ Ready for backend integration
- ✅ Reusable widgets

### Future Enhancements:
- [ ] Real-time location tracking
- [ ] Push notifications when worker assigned
- [ ] Image upload for waste type verification
- [ ] Schedule editing functionality
- [ ] Recurring schedules

---

## Summary

Successfully unified Schedule and Check-in features into a single coherent "Waste Collection Request" workflow. The implementation uses BLoC pattern with proper dependency injection and is ready for backend API integration. Current version uses mock data but maintains the same structure and state management that will be used when backend endpoints are available.

**Key Achievement**: Simplified user mental model from 2 separate features → 1 unified experience.

**Next Steps**: 
1. Implement backend Schedule API
2. Update repository with real API calls  
3. Add GPS location service
4. Remove deprecated files after verification
