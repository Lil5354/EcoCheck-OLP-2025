/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Gamification Management Page
 */

import React, { useState, useEffect } from "react";
import SidebarPro from "../../navigation/SidebarPro.jsx";
import api from "../../lib/api.js";
import OverviewTab from "./tabs/OverviewTab.jsx";
import LeaderboardTab from "./tabs/LeaderboardTab.jsx";
import PointsTab from "./tabs/PointsTab.jsx";
import BadgesTab from "./tabs/BadgesTab.jsx";
import Toast from "../../components/common/Toast.jsx";

export default function GamificationDashboard() {
  const [activeTab, setActiveTab] = useState("overview"); // "overview", "leaderboard", "points", "badges"
  const [toast, setToast] = useState(null);

  const showToast = (message, type = "success") => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  return (
    <div className="app layout">
      <SidebarPro active="gamification" />
      <div className="content">
        <main className="main">
          <div className="container">
            <div className="page-header" style={{ marginBottom: "2rem" }}>
              <h1 className="page-title">Quản lý điểm xanh & Bảng xếp hạng</h1>
            </div>

            {/* Tabs Navigation */}
            <div className="tabs-nav" style={{ borderBottom: "2px solid #e0e0e0", marginBottom: "2rem" }}>
              <button
                className={`tab-button ${activeTab === "overview" ? "active" : ""}`}
                onClick={() => setActiveTab("overview")}
                style={{
                  padding: "1rem 2rem",
                  border: "none",
                  background: "none",
                  fontSize: "1rem",
                  fontWeight: activeTab === "overview" ? "600" : "400",
                  color: activeTab === "overview" ? "#1976d2" : "#666",
                  borderBottom: activeTab === "overview" ? "3px solid #1976d2" : "3px solid transparent",
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
              >
                Tổng quan
              </button>
              <button
                className={`tab-button ${activeTab === "leaderboard" ? "active" : ""}`}
                onClick={() => setActiveTab("leaderboard")}
                style={{
                  padding: "1rem 2rem",
                  border: "none",
                  background: "none",
                  fontSize: "1rem",
                  fontWeight: activeTab === "leaderboard" ? "600" : "400",
                  color: activeTab === "leaderboard" ? "#1976d2" : "#666",
                  borderBottom: activeTab === "leaderboard" ? "3px solid #1976d2" : "3px solid transparent",
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
              >
                Bảng xếp hạng
              </button>
              <button
                className={`tab-button ${activeTab === "points" ? "active" : ""}`}
                onClick={() => setActiveTab("points")}
                style={{
                  padding: "1rem 2rem",
                  border: "none",
                  background: "none",
                  fontSize: "1rem",
                  fontWeight: activeTab === "points" ? "600" : "400",
                  color: activeTab === "points" ? "#1976d2" : "#666",
                  borderBottom: activeTab === "points" ? "3px solid #1976d2" : "3px solid transparent",
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
              >
                Quản lý điểm
              </button>
              <button
                className={`tab-button ${activeTab === "badges" ? "active" : ""}`}
                onClick={() => setActiveTab("badges")}
                style={{
                  padding: "1rem 2rem",
                  border: "none",
                  background: "none",
                  fontSize: "1rem",
                  fontWeight: activeTab === "badges" ? "600" : "400",
                  color: activeTab === "badges" ? "#1976d2" : "#666",
                  borderBottom: activeTab === "badges" ? "3px solid #1976d2" : "3px solid transparent",
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
              >
                Quản lý huy hiệu
              </button>
            </div>

            {/* Tab Content */}
            <div className="tab-content">
              {activeTab === "overview" && <OverviewTab showToast={showToast} />}
              {activeTab === "leaderboard" && <LeaderboardTab showToast={showToast} />}
              {activeTab === "points" && <PointsTab showToast={showToast} />}
              {activeTab === "badges" && <BadgesTab showToast={showToast} />}
            </div>

            {/* Toast Notification */}
            {toast && (
              <Toast
                message={toast.message}
                type={toast.type}
                onClose={() => setToast(null)}
              />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

