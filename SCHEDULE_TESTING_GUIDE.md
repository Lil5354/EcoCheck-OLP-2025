# Testing Guide: Schedule & Check-in Unification

## Quick Test Workflow

### Prerequisites
- Backend running on `http://localhost:3000` (macOS) or `http://10.0.2.2:3000` (Android emulator)
- Flutter app compiled and running
- Logged in with demo account: 0901234567 / 123456

---

## Test Case 1: Create New Waste Collection Request

### Steps:
1. Open app → Navigate to HomePage
2. Click "Yêu cầu thu gom" quick action button (green card)
3. Verify CreateRequestPage opens

### Form Testing:
4. **Select Waste Type**:
   - Tap "Rác sinh hoạt" (household) → Verify selected with green border
   - Tap "Rác tái chế" (recyclable) → Verify selected
   - Tap "Rác cồng kềnh" (hazardous) → Verify selected

5. **Adjust Weight**:
   - Drag slider from 5kg → 10kg → 25kg
   - Verify weight display updates in green box on right

6. **Select Date**:
   - Tap date picker
   - Select tomorrow's date
   - Verify date displays correctly (e.g., "T2, 25/11/2024")

7. **Select Time Slot**:
   - Tap "Sáng (6:00 - 11:00)" → Verify selected with green border
   - Tap "Chiều (13:00 - 17:00)" → Verify selected
   - Tap "Tối (17:00 - 20:00)" → Verify selected

8. **Verify Location**:
   - Check GPS location shows: "123 Nguyễn Huệ, Q1, TP.HCM"
   - Check coordinates: "Lat: 10.762622, Long: 106.660172"

9. **Verify Rewards**:
   - Check rewards calculation:
     - Organic waste: +10 points
     - Recyclable waste: +20 points
     - Hazardous waste: +30 points
     - Weight >= 10kg: +10 extra points

10. **Submit Request**:
    - Tap "Tạo yêu cầu" button
    - Verify loading dialog appears
    - Verify success dialog appears with message: "Lịch thu gom đã được tạo..."
    - Tap "OK" on success dialog
    - Verify navigation back to HomePage

### Expected Results:
- ✅ All form fields work correctly
- ✅ Loading and success dialogs appear
- ✅ Navigation works smoothly
- ✅ No errors in console

---

## Test Case 2: View Waste Collection Requests

### Steps:
1. From HomePage → Tap "Schedule" tab in bottom navigation (calendar icon)
2. Verify ScheduleListPage opens

### Tab Testing:
3. **Chờ xác nhận Tab**:
   - Verify empty state message: "Không có lịch chờ xác nhận"
   - (After creating request) Verify new request appears here

4. **Đã xác nhận Tab**:
   - Verify empty state message: "Không có lịch đã xác nhận"

5. **Hoàn thành Tab**:
   - Verify empty state message: "Chưa có lịch hoàn thành"

### Expected Results:
- ✅ All 3 tabs accessible
- ✅ Empty states show correct messages
- ✅ Tab switching works smoothly

---

## Test Case 3: Complete Flow (Create → View)

### Steps:
1. From HomePage → Click "Yêu cầu thu gom"
2. Fill form:
   - Waste type: "Rác tái chế"
   - Weight: 7.5kg
   - Date: Tomorrow
   - Time: "Sáng (6:00 - 11:00)"
3. Tap "Tạo yêu cầu"
4. Wait for success dialog → Tap "OK"
5. Navigate to "Schedule" tab
6. Go to "Chờ xác nhận" tab

### Expected Results:
- ✅ New schedule appears in "Chờ xác nhận" tab
- ✅ Schedule shows correct details:
  - Waste type: Recyclable icon (recycling symbol)
  - Weight: 7.5kg
  - Date: Tomorrow
  - Time: Sáng (6:00 - 11:00)
  - Status: pending (orange color)
  - Address: 123 Nguyễn Huệ, Q1, TP.HCM

---

## Test Case 4: Navigation from Schedule List

### Steps:
1. From ScheduleListPage
2. Tap FAB button "Yêu cầu thu gom" (bottom right)
3. Verify CreateRequestPage opens

### Expected Results:
- ✅ FAB button works
- ✅ Navigation correct
- ✅ BlocProvider properly initialized

---

## Test Case 5: Error Handling

### Steps:
1. **Simulate Network Error**:
   - Stop backend server
   - Try creating new request
   - Verify error SnackBar appears

2. **Simulate Timeout**:
   - (If implemented) Wait for timeout
   - Verify error message

### Expected Results:
- ✅ Errors handled gracefully
- ✅ User-friendly error messages
- ✅ No app crashes

---

## Test Case 6: State Management (BLoC)

### Steps:
1. Create new request → Go to Schedule tab
2. Verify new schedule appears (state updated)
3. Pull to refresh on Schedule tab
4. Verify data reloads

### Expected Results:
- ✅ BLoC state updates correctly
- ✅ UI reflects state changes
- ✅ No duplicate data
- ✅ No stale data

---

## Visual Testing Checklist

### CreateRequestPage:
- [ ] Header icon (trash bin) displays correctly
- [ ] Title "Tôi có rác!" in green
- [ ] All waste type cards with icons
- [ ] Slider works smoothly
- [ ] Date picker shows calendar
- [ ] Time slots have clear borders when selected
- [ ] Location section has GPS icon
- [ ] Rewards section has star icon (yellow)
- [ ] Submit button is green with icon
- [ ] Bottom info text is gray

### ScheduleListPage:
- [ ] AppBar shows "Schedule" title
- [ ] 3 tabs are visible and clickable
- [ ] Empty states show icons and messages
- [ ] Schedule cards (when data exists) show all info
- [ ] FAB button is visible and green

---

## Performance Testing

### Load Time:
1. Measure time to open CreateRequestPage: Should be < 500ms
2. Measure time to submit request: Should be < 2s (with mock)
3. Measure time to load Schedule list: Should be < 500ms

### Memory:
1. Check memory usage when navigating between pages
2. Verify no memory leaks when creating multiple requests

---

## Regression Testing

### After Backend Integration:
- [ ] All mock data replaced with API calls
- [ ] Create request sends POST /api/schedules
- [ ] Get schedules sends GET /api/schedules?citizenId=xxx
- [ ] Real GPS location instead of hardcoded
- [ ] Real user ID from auth state
- [ ] Error messages from backend displayed correctly

---

## Known Limitations (Current Mock Version)

1. **Backend API**: Currently using mock data
   - No persistence across app restarts
   - No real-time updates
   - Data stored in memory only

2. **GPS Location**: Hardcoded coordinates
   - Always shows: 10.762622, 106.660172
   - Need to implement real location service

3. **User ID**: Hardcoded 'user-123'
   - Need to get from auth state

4. **Auto-refresh**: Not implemented
   - Need to manually navigate to see updates

---

## Debug Tips

### Common Issues:

1. **Request not appearing in Schedule list**:
   - Check console for errors
   - Verify BLoC state updates
   - Check if mock list is populating

2. **Navigation not working**:
   - Verify BlocProvider is wrapping CreateRequestPage
   - Check Navigator context

3. **Form validation**:
   - Currently no validation implemented
   - All fields required but not enforced

### Debug Commands:
```bash
# Check Flutter errors
flutter logs

# Hot reload
r

# Hot restart
R

# Clear cache
flutter clean
flutter pub get
```

---

## Test Results Template

```
Date: ___________
Tester: ___________
Device: ___________ (iOS Simulator / Android Emulator / Physical Device)
Flutter Version: ___________
Backend Status: Running / Mock Data

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC1: Create Request | ✅/❌ | |
| TC2: View Requests | ✅/❌ | |
| TC3: Complete Flow | ✅/❌ | |
| TC4: FAB Navigation | ✅/❌ | |
| TC5: Error Handling | ✅/❌ | |
| TC6: State Management | ✅/❌ | |

Issues Found:
-
-
-

Overall Status: PASS / FAIL
```

---

## Next Steps After Testing

1. **If All Tests Pass**:
   - Mark feature as ready for backend integration
   - Document any UX improvements needed
   - Plan real GPS location implementation

2. **If Tests Fail**:
   - Log all errors with screenshots
   - Check console logs
   - File bug reports with reproduction steps
   - Fix issues and retest

3. **Backend Integration Prep**:
   - Coordinate with backend team on API contract
   - Plan migration from mock to real data
   - Set up error handling for API failures
   - Test with real network conditions
