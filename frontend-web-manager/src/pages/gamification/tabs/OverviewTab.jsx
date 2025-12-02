/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Gamification Overview Tab
 */

import React, { useState, useEffect } from "react";
import api from "../../../lib/api.js";
import { AreaChart, DonutChart } from "../../../components/Charts.jsx";
import Table from "../../../components/common/Table.jsx";

export default function OverviewTab({ showToast }) {
  const [loading, setLoading] = useState(true);
  const [overview, setOverview] = useState(null);
  const [trends, setTrends] = useState({ pointsTrend: [], checkinsTrend: [] });
  const [debugInfo, setDebugInfo] = useState(null);
  const [distribution, setDistribution] = useState([]);
  const [period, setPeriod] = useState("7d");

  useEffect(() => {
    loadData();
  }, [period]);

  async function loadData() {
    setLoading(true);
    try {
      const [overviewRes, trendsRes, distributionRes] = await Promise.all([
        api.getGamificationOverview(),
        api.getGamificationTrends(period),
        api.getGamificationDistribution("rank_tier"),
      ]);

      if (overviewRes.ok) setOverview(overviewRes.data);
      if (trendsRes.ok) {
        console.log("📊 Trends API response:", trendsRes);
        console.log("📊 Trends data:", trendsRes.data);
        const trendsData = trendsRes.data || { pointsTrend: [], checkinsTrend: [] };
        console.log("📊 Points trend count:", trendsData.pointsTrend?.length || 0);
        console.log("📊 Points trend sample:", trendsData.pointsTrend?.[0]);
        console.log("📊 Checkins trend count:", trendsData.checkinsTrend?.length || 0);
        console.log("📊 Checkins trend sample:", trendsData.checkinsTrend?.[0]);
        setTrends(trendsData);
      } else {
        console.error("📊 Trends API error:", trendsRes);
      }
      if (distributionRes.ok) {
        console.log("📊 Distribution data:", distributionRes.data);
        // distributionRes.data is {type, distribution: Array, total}
        setDistribution(distributionRes.data.distribution || []);
      }
    } catch (error) {
      showToast("Lỗi tải dữ liệu: " + error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div style={{ textAlign: "center", padding: "4rem 0" }}>
        <div>Đang tải dữ liệu...</div>
      </div>
    );
  }

  const topUsersColumns = [
    { key: "rank", label: "Hạng" },
    { key: "userName", label: "Tên người dùng" },
    { key: "points", label: "Điểm", render: (row) => `${row.points.toLocaleString()} điểm` },
    { key: "level", label: "Cấp độ" },
    { key: "totalCheckins", label: "Check-ins" },
  ];

  return (
    <div>
      {/* Summary Cards */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))",
          gap: "1.5rem",
          marginBottom: "2rem",
        }}
      >
        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <div style={{ color: "#666", fontSize: "0.875rem", marginBottom: "0.5rem" }}>
            Tổng số users tích điểm
          </div>
          <div style={{ fontSize: "2rem", fontWeight: "bold", color: "#1976d2" }}>
            {overview?.totalUsers?.toLocaleString() || 0}
          </div>
        </div>

        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <div style={{ color: "#666", fontSize: "0.875rem", marginBottom: "0.5rem" }}>
            Điểm phân phát hôm nay
          </div>
          <div style={{ fontSize: "2rem", fontWeight: "bold", color: "#22c55e" }}>
            {overview?.pointsDistributed?.today?.toLocaleString() || 0}
          </div>
        </div>

        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <div style={{ color: "#666", fontSize: "0.875rem", marginBottom: "0.5rem" }}>
            Điểm phân phát tháng này
          </div>
          <div style={{ fontSize: "2rem", fontWeight: "bold", color: "#f59e0b" }}>
            {overview?.pointsDistributed?.month?.toLocaleString() || 0}
          </div>
        </div>

        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <div style={{ color: "#666", fontSize: "0.875rem", marginBottom: "0.5rem" }}>
            Huy hiệu đã unlock
          </div>
          <div style={{ fontSize: "2rem", fontWeight: "bold", color: "#8b5cf6" }}>
            {overview?.badgesUnlocked?.toLocaleString() || 0}
          </div>
        </div>
      </div>

      {/* Charts Row */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(400px, 1fr))",
          gap: "1.5rem",
          marginBottom: "2rem",
        }}
      >
        {/* Points Trend Chart */}
        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: "1rem",
            }}
          >
            <h3 style={{ margin: 0, fontSize: "1.125rem", fontWeight: "600" }}>
              Xu hướng điểm phân phát
            </h3>
            <select
              value={period}
              onChange={(e) => setPeriod(e.target.value)}
              style={{
                padding: "0.5rem",
                borderRadius: "4px",
                border: "1px solid #ddd",
                fontSize: "0.875rem",
              }}
            >
              <option value="7d">7 ngày</option>
              <option value="30d">30 ngày</option>
              <option value="month">Tháng này</option>
            </select>
          </div>
          {trends.pointsTrend && trends.pointsTrend.length > 0 ? (
            <AreaChart
              data={trends.pointsTrend.map((item) => {
                // Parse date safely - handle both string and Date object
                let dateValue;
                if (typeof item.date === 'string') {
                  dateValue = new Date(item.date);
                } else {
                  dateValue = item.date;
                }
                // Ensure valid date
                if (isNaN(dateValue.getTime())) {
                  dateValue = new Date();
                }
                const value = parseInt(item.points || 0);
                console.log('📊 Chart data point:', { value, date: item.date, dateValue });
                return {
                  value: value,
                  label: dateValue.toLocaleDateString("vi-VN", {
                    day: "2-digit",
                    month: "2-digit",
                  }),
                };
              })}
              color="#22c55e"
              height={200}
              width={520}
              labelFormatter={(value) => `${value.toLocaleString()} điểm`}
            />
          ) : (
            <div
              style={{
                height: "200px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#888",
                fontSize: "0.875rem",
              }}
            >
              Chưa có dữ liệu để hiển thị
            </div>
          )}
        </div>

        {/* Check-ins Trend Chart */}
        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", fontSize: "1.125rem", fontWeight: "600" }}>
            Xu hướng check-ins
          </h3>
          {trends.checkinsTrend && trends.checkinsTrend.length > 0 ? (
            <AreaChart
              data={trends.checkinsTrend.map((item) => {
                // Parse date safely - handle both string and Date object
                let dateValue;
                if (typeof item.date === 'string') {
                  dateValue = new Date(item.date);
                } else {
                  dateValue = item.date;
                }
                // Ensure valid date
                if (isNaN(dateValue.getTime())) {
                  dateValue = new Date();
                }
                const value = parseInt(item.checkins || item.count || 0);
                console.log('📊 Checkins chart data point:', { value, date: item.date, dateValue });
                return {
                  value: value,
                  label: dateValue.toLocaleDateString("vi-VN", {
                    day: "2-digit",
                    month: "2-digit",
                  }),
                };
              })}
              color="#06b6d4"
              height={200}
              width={520}
              labelFormatter={(value) => `${value.toLocaleString()}`}
            />
          ) : (
            <div
              style={{
                height: "200px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#888",
                fontSize: "0.875rem",
              }}
            >
              Chưa có dữ liệu để hiển thị
            </div>
          )}
        </div>
      </div>

      {/* Distribution and Top Users Row */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "400px 1fr",
          gap: "1.5rem",
          marginBottom: "2rem",
        }}
      >
        {/* Rank Tier Distribution */}
        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", fontSize: "1.125rem", fontWeight: "600" }}>
            Phân bổ Rank Tier
          </h3>
          <DonutChart
            segments={
              Array.isArray(distribution) && distribution.length > 0
                ? distribution.reduce((acc, item) => {
                    acc[item.tier] = item.count;
                    return acc;
                  }, {})
                : {}
            }
            size={200}
            colors={["#22c55e", "#06b6d4", "#f59e0b", "#ef4444", "#8b5cf6"]}
            numberFormatter={(value) => value.toLocaleString('vi-VN')}
          />
          <div style={{ marginTop: "1rem", fontSize: "0.875rem" }}>
            {Array.isArray(distribution) && distribution.length > 0 ? (
              distribution.map((item) => (
              <div
                key={item.tier}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  padding: "0.5rem 0",
                  borderBottom: "1px solid #f0f0f0",
                }}
              >
                <span>{item.tier}</span>
                <span style={{ fontWeight: "600" }}>{item.count}</span>
              </div>
            ))
            ) : (
              <div style={{ padding: "1rem", textAlign: "center", color: "#888" }}>
                Chưa có dữ liệu
              </div>
            )}
          </div>
        </div>

        {/* Top 5 Users */}
        <div
          style={{
            padding: "1.5rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", fontSize: "1.125rem", fontWeight: "600" }}>
            Top 5 người dùng
          </h3>
          {overview?.topUsers && overview.topUsers.length > 0 ? (
            <Table
              columns={topUsersColumns}
              data={overview.topUsers.map((user, idx) => ({
                rank: idx + 1,
                userName: user.userName || "User",
                points: user.points || 0,
                level: user.level || 1,
                totalCheckins: user.totalCheckins || 0,
              }))}
              emptyText="Chưa có dữ liệu"
            />
          ) : (
            <div
              style={{
                padding: "2rem",
                textAlign: "center",
                color: "#888",
                fontSize: "0.875rem",
              }}
            >
              Chưa có dữ liệu
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

