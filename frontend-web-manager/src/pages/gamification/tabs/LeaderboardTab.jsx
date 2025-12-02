/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Leaderboard Management Tab
 */

import React, { useState, useEffect } from "react";
import api from "../../../lib/api.js";
import Table from "../../../components/common/Table.jsx";

export default function LeaderboardTab({ showToast }) {
  const [loading, setLoading] = useState(true);
  const [leaderboard, setLeaderboard] = useState([]);
  const [period, setPeriod] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    loadLeaderboard();
  }, [period]);

  async function loadLeaderboard() {
    setLoading(true);
    try {
      const res = await api.getLeaderboard({ period, limit: 100 });
      if (res.ok) {
        setLeaderboard(res.data || []);
      } else {
        showToast(res.error || "Lỗi tải bảng xếp hạng", "error");
      }
    } catch (error) {
      showToast("Lỗi: " + error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  const getRankIcon = (rank) => {
    if (rank === 1) return "🥇";
    if (rank === 2) return "🥈";
    if (rank === 3) return "🥉";
    return null;
  };

  const getRankTierColor = (tier) => {
    const colors = {
      "Huyền thoại": "#fbbf24",
      "Chuyên gia": "#8b5cf6",
      "Chiến binh xanh": "#06b6d4",
      "Người tích cực": "#22c55e",
      "Người mới": "#94a3b8",
    };
    return colors[tier] || "#94a3b8";
  };

  const filteredLeaderboard = leaderboard.filter((entry) =>
    entry.userName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const columns = [
    {
      key: "rank",
      label: "Hạng",
      render: (row) => (
        <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
          {getRankIcon(row.rank) || `#${row.rank}`}
        </div>
      ),
    },
    {
      key: "userName",
      label: "Người dùng",
      render: (row) => (
        <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
          {row.avatarUrl ? (
            <img
              src={row.avatarUrl}
              alt={row.userName}
              style={{
                width: "32px",
                height: "32px",
                borderRadius: "50%",
                objectFit: "cover",
              }}
            />
          ) : (
            <div
              style={{
                width: "32px",
                height: "32px",
                borderRadius: "50%",
                background: "#e0e0e0",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "0.875rem",
                fontWeight: "600",
                color: "#666",
              }}
            >
              {(row.userName || "U")[0].toUpperCase()}
            </div>
          )}
          <span>{row.userName || "User"}</span>
        </div>
      ),
    },
    {
      key: "points",
      label: "Điểm",
      render: (row) => (
        <span style={{ fontWeight: "600", color: "#22c55e" }}>
          {row.points?.toLocaleString() || 0} điểm
        </span>
      ),
    },
    {
      key: "rankTier",
      label: "Rank Tier",
      render: (row) => (
        <span
          style={{
            padding: "0.25rem 0.75rem",
            borderRadius: "12px",
            fontSize: "0.875rem",
            fontWeight: "500",
            background: `${getRankTierColor(row.rankTier)}20`,
            color: getRankTierColor(row.rankTier),
          }}
        >
          {row.rankTier || "Người mới"}
        </span>
      ),
    },
    {
      key: "level",
      label: "Cấp độ",
      render: (row) => <span>Level {row.level || 1}</span>,
    },
  ];

  if (loading) {
    return (
      <div style={{ textAlign: "center", padding: "4rem 0" }}>
        <div>Đang tải dữ liệu...</div>
      </div>
    );
  }

  return (
    <div>
      {/* Filters */}
      <div
        style={{
          display: "flex",
          gap: "1rem",
          marginBottom: "1.5rem",
          alignItems: "center",
        }}
      >
        <div style={{ flex: 1 }}>
          <input
            type="text"
            placeholder="Tìm kiếm theo tên người dùng..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              width: "100%",
              padding: "0.75rem",
              border: "1px solid #ddd",
              borderRadius: "4px",
              fontSize: "0.875rem",
            }}
          />
        </div>
        <select
          value={period}
          onChange={(e) => setPeriod(e.target.value)}
          style={{
            padding: "0.75rem",
            border: "1px solid #ddd",
            borderRadius: "4px",
            fontSize: "0.875rem",
            minWidth: "150px",
          }}
        >
          <option value="all">Tất cả thời gian</option>
          <option value="weekly">Tuần này</option>
          <option value="monthly">Tháng này</option>
        </select>
        <button
          onClick={loadLeaderboard}
          style={{
            padding: "0.75rem 1.5rem",
            background: "#1976d2",
            color: "white",
            border: "none",
            borderRadius: "4px",
            cursor: "pointer",
            fontSize: "0.875rem",
            fontWeight: "500",
          }}
        >
          Làm mới
        </button>
      </div>

      {/* Statistics */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: "1rem",
          marginBottom: "1.5rem",
        }}
      >
        <div
          style={{
            padding: "1rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <div style={{ color: "#666", fontSize: "0.875rem" }}>Tổng số người dùng</div>
          <div style={{ fontSize: "1.5rem", fontWeight: "bold", color: "#1976d2" }}>
            {filteredLeaderboard.length}
          </div>
        </div>
        <div
          style={{
            padding: "1rem",
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          }}
        >
          <div style={{ color: "#666", fontSize: "0.875rem" }}>Điểm trung bình</div>
          <div style={{ fontSize: "1.5rem", fontWeight: "bold", color: "#22c55e" }}>
            {filteredLeaderboard.length > 0
              ? Math.round(
                  filteredLeaderboard.reduce((sum, u) => sum + (u.points || 0), 0) /
                    filteredLeaderboard.length
                ).toLocaleString()
              : 0}
          </div>
        </div>
      </div>

      {/* Leaderboard Table */}
      <div
        style={{
          background: "white",
          borderRadius: "8px",
          boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
          padding: "1.5rem",
        }}
      >
        <Table
          columns={columns}
          data={filteredLeaderboard}
          emptyText="Không có dữ liệu bảng xếp hạng"
        />
      </div>
    </div>
  );
}

