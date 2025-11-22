# CN15: Exception Handling

## Purpose
Manage "Cannot Collect" reports from field workers, approve or reject with action plans.

## Features
- **Exception List**: Table showing time, location, type (oversize/blocked/other), status
- **Approve**: Provide action plan (e.g., "Send crane truck tomorrow 8am")
- **Reject**: Provide reason (e.g., "Duplicate report")
- **Status Tracking**: Pending → Approved/Rejected
- **History Log**: Track all actions (placeholder)

## Usage
1. Navigate to **Exceptions > Exception Handling**
2. Review pending exceptions in table
3. Click **Approve** to accept exception and provide plan
4. Click **Reject** to decline exception with reason
5. Toast notification confirms action

## API Endpoints
- `GET /api/exceptions` – fetch all exception reports
- `GET /api/exceptions/:id` – fetch exception detail
- `POST /api/exceptions/:id/approve` – approve exception
  - Request: `{ plan, scheduledAt? }`
  - Response: `{ ok, message }`
- `POST /api/exceptions/:id/reject` – reject exception
  - Request: `{ reason }`
  - Response: `{ ok, message }`

## Mock Data
12 sample exceptions with random types and statuses. Mock approve/reject returns success.

## Notes
- Only pending exceptions can be approved/rejected
- Approved exceptions should trigger follow-up tasks (backend logic)
- Photo evidence display not yet implemented (requires image upload)
- Scheduled action date picker not yet implemented

