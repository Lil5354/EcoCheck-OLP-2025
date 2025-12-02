/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Application router configuration
 */

import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import App from "./App.jsx";
import Schedules from "./pages/operations/Schedules.jsx";
import RouteOptimization from "./pages/operations/RouteOptimization.jsx";
import DynamicDispatch from "./pages/operations/DynamicDispatch.jsx";
import AirQuality from "./pages/operations/AirQuality.jsx";
import POI from "./pages/operations/POI.jsx";
import SensorAlerts from "./pages/operations/SensorAlerts.jsx";
import AnalyticsPage from "./pages/analytics/Analytics.jsx";
import Fleet from "./pages/master/Fleet.jsx";
import Personnel from "./pages/master/Personnel.jsx";
import DepotsDumps from "./pages/master/DepotsDumps.jsx";
import Reports from "./pages/reports/Reports.jsx";
import GamificationDashboard from "./pages/gamification/GamificationDashboard.jsx";

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
        <Route
          path="/operations/air-quality"
          element={<AirQuality />}
        />
        <Route
          path="/operations/poi"
          element={<POI />}
        />
        <Route
          path="/operations/sensor-alerts"
          element={<SensorAlerts />}
        />
        <Route path="/analytics" element={<AnalyticsPage />} />
        <Route path="/gamification" element={<GamificationDashboard />} />
        <Route path="/master/fleet" element={<Fleet />} />
        <Route path="/master/personnel" element={<Personnel />} />
        <Route path="/master/depots-dumps" element={<DepotsDumps />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
