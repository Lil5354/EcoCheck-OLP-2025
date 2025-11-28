import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import App from "./App.jsx";
import Schedules from "./pages/operations/Schedules.jsx";
import RouteOptimization from "./pages/operations/RouteOptimization.jsx";
import DynamicDispatch from "./pages/operations/DynamicDispatch.jsx";
import AnalyticsPage from "./pages/analytics/Analytics.jsx";
import Fleet from "./pages/master/Fleet.jsx";
import Personnel from "./pages/master/Personnel.jsx";
import DepotsDumps from "./pages/master/DepotsDumps.jsx";
import Reports from "./pages/reports/Reports.jsx";

export default function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<App />} />
        <Route path="/operations/schedules" element={<Schedules />} />
        <Route
          path="/operations/route-optimization"
          element={<RouteOptimization />}
        />
        <Route
          path="/operations/dynamic-dispatch"
          element={<DynamicDispatch />}
        />
        <Route path="/analytics" element={<AnalyticsPage />} />
        <Route path="/master/fleet" element={<Fleet />} />
        <Route path="/master/personnel" element={<Personnel />} />
        <Route path="/master/depots-dumps" element={<DepotsDumps />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
