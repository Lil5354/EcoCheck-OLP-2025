# CN8: Analytics & Prediction

## Purpose
Visualize collection performance metrics, timeseries data, and forecast future waste volumes using ML models.

## Features
- **KPI Cards**: Total collected (tons), points completed, fuel saving %
- **Timeseries Chart**: Line chart showing collection volume over time (hourly/daily granularity)
- **Forecast**: Predict next 7 days waste volume with weather parameter
- **Export**: Download CSV (placeholder)

## Usage
1. Navigate to **Analytics > Analytics & Prediction**
2. View KPI cards at the top
3. Scroll to **Collection Timeseries** for historical data
4. Click **Predict Next 7 Days** to generate forecast
5. Review Actual vs Forecast data

## API Endpoints
- `GET /api/analytics/summary?from=&to=` – fetch KPI summary
- `GET /api/analytics/timeseries?granularity=hour|day&from=&to=` – fetch timeseries data
- `GET /api/analytics/predict?days=7&weather=sunny|rainy` – generate forecast

## Mock Data
- Summary: totalTons=122.3, completed=934, fuelSaving=8.5%, byType={household:62, recyclable:31, bulky:7}
- Timeseries: 24 hourly data points with random values
- Forecast: 7 days actual + 7 days forecast with slight variation

## Notes
- Chart rendering is placeholder (text only). Integrate with recharts or similar library for production.
- Weather parameter affects forecast model (backend logic)
- Date range filters not yet implemented in UI

