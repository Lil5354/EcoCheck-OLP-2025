/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Points Management Tab
 */

import React, { useState, useEffect } from "react";
import api from "../../../lib/api.js";
import Table from "../../../components/common/Table.jsx";
import FormModal from "../../../components/common/FormModal.jsx";

export default function PointsTab({ showToast }) {
  const [loading, setLoading] = useState(true);
  const [transactions, setTransactions] = useState([]);
  const [pagination, setPagination] = useState({ total: 0, limit: 50, offset: 0 });
  const [filters, setFilters] = useState({
    user_id: "",
    date_from: "",
    date_to: "",
    transaction_type: "",
  });
  const [rules, setRules] = useState(null);
  const [adjustModalOpen, setAdjustModalOpen] = useState(false);
  const [adjustForm, setAdjustForm] = useState({
    user_id: "",
    points: 0,
    reason: "",
  });

  useEffect(() => {
    loadTransactions();
    loadRules();
  }, [filters, pagination.offset]);

  async function loadTransactions() {
    setLoading(true);
    try {
      const params = {
        ...filters,
        limit: pagination.limit,
        offset: pagination.offset,
      };
      Object.keys(params).forEach((key) => {
        if (!params[key]) delete params[key];
      });

      const res = await api.getPointTransactions(params);
      if (res.ok) {
        setTransactions(res.data || []);
        setPagination((prev) => ({ ...prev, total: res.pagination?.total || 0 }));
      } else {
        showToast(res.error || "Lỗi tải lịch sử điểm", "error");
      }
    } catch (error) {
      showToast("Lỗi: " + error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  async function loadRules() {
    try {
      const res = await api.getPointsRules();
      if (res.ok) {
        setRules(res.data);
      }
    } catch (error) {
      console.error("Error loading rules:", error);
    }
  }

  async function handleAdjustPoints() {
    if (!adjustForm.user_id || !adjustForm.reason) {
      showToast("Vui lòng điền đầy đủ thông tin", "error");
      return;
    }

    try {
      const res = await api.adjustPoints(
        adjustForm.user_id,
        parseInt(adjustForm.points),
        adjustForm.reason
      );
      if (res.ok) {
        showToast("Điều chỉnh điểm thành công", "success");
        setAdjustModalOpen(false);
        setAdjustForm({ user_id: "", points: 0, reason: "" });
        loadTransactions();
      } else {
        showToast(res.error || "Điều chỉnh điểm thất bại", "error");
      }
    } catch (error) {
      showToast("Lỗi: " + error.message, "error");
    }
  }

  const getTransactionTypeColor = (type) => {
    const colors = {
      earn: "#22c55e",
      bonus: "#f59e0b",
      reward: "#8b5cf6",
      adjustment: "#06b6d4",
      penalty: "#ef4444",
      spend: "#ef4444",
    };
    return colors[type] || "#666";
  };

  const columns = [
    {
      key: "createdAt",
      label: "Thời gian",
      render: (row) =>
        new Date(row.createdAt).toLocaleString("vi-VN", {
          day: "2-digit",
          month: "2-digit",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        }),
    },
    {
      key: "userName",
      label: "Người dùng",
    },
    {
      key: "points",
      label: "Điểm",
      render: (row) => (
        <span
          style={{
            fontWeight: "600",
            color: row.points >= 0 ? "#22c55e" : "#ef4444",
          }}
        >
          {row.points >= 0 ? "+" : ""}
          {row.points.toLocaleString()} điểm
        </span>
      ),
    },
    {
      key: "transactionType",
      label: "Loại",
      render: (row) => (
        <span
          style={{
            padding: "0.25rem 0.75rem",
            borderRadius: "12px",
            fontSize: "0.875rem",
            fontWeight: "500",
            background: `${getTransactionTypeColor(row.transactionType)}20`,
            color: getTransactionTypeColor(row.transactionType),
          }}
        >
          {row.transactionType}
        </span>
      ),
    },
    {
      key: "reason",
      label: "Lý do",
    },
  ];

  if (loading && transactions.length === 0) {
    return (
      <div style={{ textAlign: "center", padding: "4rem 0" }}>
        <div>Đang tải dữ liệu...</div>
      </div>
    );
  }

  return (
    <div>
      {/* Header Actions */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "1.5rem",
        }}
      >
        <h2 style={{ margin: 0, fontSize: "1.25rem", fontWeight: "600" }}>
          Lịch sử giao dịch điểm
        </h2>
        <button
          onClick={() => setAdjustModalOpen(true)}
          style={{
            padding: "0.75rem 1.5rem",
            background: "#22c55e",
            color: "white",
            border: "none",
            borderRadius: "4px",
            cursor: "pointer",
            fontSize: "0.875rem",
            fontWeight: "500",
          }}
        >
          + Điều chỉnh điểm
        </button>
      </div>

      {/* Filters */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: "1rem",
          marginBottom: "1.5rem",
        }}
      >
        <input
          type="text"
          placeholder="Tìm theo tên/email/User ID..."
          value={filters.user_id}
          onChange={(e) => setFilters({ ...filters, user_id: e.target.value })}
          style={{
            padding: "0.75rem",
            border: "1px solid #ddd",
            borderRadius: "4px",
            fontSize: "0.875rem",
          }}
        />
        <input
          type="date"
          placeholder="Từ ngày"
          value={filters.date_from}
          onChange={(e) => setFilters({ ...filters, date_from: e.target.value })}
          style={{
            padding: "0.75rem",
            border: "1px solid #ddd",
            borderRadius: "4px",
            fontSize: "0.875rem",
          }}
        />
        <input
          type="date"
          placeholder="Đến ngày"
          value={filters.date_to}
          onChange={(e) => setFilters({ ...filters, date_to: e.target.value })}
          style={{
            padding: "0.75rem",
            border: "1px solid #ddd",
            borderRadius: "4px",
            fontSize: "0.875rem",
          }}
        />
        <select
          value={filters.transaction_type}
          onChange={(e) => setFilters({ ...filters, transaction_type: e.target.value })}
          style={{
            padding: "0.75rem",
            border: "1px solid #ddd",
            borderRadius: "4px",
            fontSize: "0.875rem",
          }}
        >
          <option value="">Tất cả loại</option>
          <option value="earn">Earn</option>
          <option value="bonus">Bonus</option>
          <option value="reward">Reward</option>
          <option value="adjustment">Adjustment</option>
          <option value="penalty">Penalty</option>
          <option value="spend">Spend</option>
        </select>
        <button
          onClick={() => {
            setFilters({ user_id: "", date_from: "", date_to: "", transaction_type: "" });
            setPagination((prev) => ({ ...prev, offset: 0 }));
          }}
          style={{
            padding: "0.75rem 1.5rem",
            background: "#ef4444",
            color: "white",
            border: "none",
            borderRadius: "4px",
            cursor: "pointer",
            fontSize: "0.875rem",
          }}
        >
          Xóa bộ lọc
        </button>
      </div>

      {/* Rules Section */}
      {rules && (
        <div
          style={{
            background: "white",
            borderRadius: "8px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            padding: "1.5rem",
            marginBottom: "1.5rem",
          }}
        >
          <h3 style={{ margin: "0 0 1rem 0", fontSize: "1.125rem", fontWeight: "600" }}>
            Quy tắc tính điểm
          </h3>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
              gap: "1rem",
            }}
          >
            {rules.rules?.map((rule) => (
              <div
                key={rule.wasteType}
                style={{
                  padding: "1rem",
                  background: "#f9fafb",
                  borderRadius: "4px",
                  border: "1px solid #e5e7eb",
                }}
              >
                <div style={{ fontWeight: "600", marginBottom: "0.25rem" }}>
                  {rule.description}
                </div>
                <div style={{ color: "#666", fontSize: "0.875rem" }}>
                  {rule.points} điểm
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Transactions Table */}
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
          data={transactions}
          emptyText="Không có giao dịch nào"
        />

        {/* Pagination */}
        {pagination.total > pagination.limit && (
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginTop: "1rem",
              paddingTop: "1rem",
              borderTop: "1px solid #e0e0e0",
            }}
          >
            <div style={{ color: "#666", fontSize: "0.875rem" }}>
              Hiển thị {pagination.offset + 1} -{" "}
              {Math.min(pagination.offset + pagination.limit, pagination.total)} /{" "}
              {pagination.total}
            </div>
            <div style={{ display: "flex", gap: "0.5rem" }}>
              <button
                onClick={() =>
                  setPagination((prev) => ({
                    ...prev,
                    offset: Math.max(0, prev.offset - prev.limit),
                  }))
                }
                disabled={pagination.offset === 0}
                style={{
                  padding: "0.5rem 1rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                  background: "white",
                  cursor: pagination.offset === 0 ? "not-allowed" : "pointer",
                  opacity: pagination.offset === 0 ? 0.5 : 1,
                }}
              >
                Trước
              </button>
              <button
                onClick={() =>
                  setPagination((prev) => ({
                    ...prev,
                    offset: prev.offset + prev.limit,
                  }))
                }
                disabled={pagination.offset + pagination.limit >= pagination.total}
                style={{
                  padding: "0.5rem 1rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                  background: "white",
                  cursor:
                    pagination.offset + pagination.limit >= pagination.total
                      ? "not-allowed"
                      : "pointer",
                  opacity:
                    pagination.offset + pagination.limit >= pagination.total ? 0.5 : 1,
                }}
              >
                Sau
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Adjust Points Modal */}
      <FormModal
        open={adjustModalOpen}
        title="Điều chỉnh điểm"
        onClose={() => {
          setAdjustModalOpen(false);
          setAdjustForm({ user_id: "", points: 0, reason: "" });
        }}
        onSubmit={handleAdjustPoints}
        submitLabel="Điều chỉnh"
      >
          <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                User ID / Tên / Email *
              </label>
              <input
                type="text"
                value={adjustForm.user_id}
                onChange={(e) => setAdjustForm({ ...adjustForm, user_id: e.target.value })}
                placeholder="Nhập UUID, tên hoặc email của user"
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                }}
              />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                Điểm (âm để trừ, dương để cộng) *
              </label>
              <input
                type="number"
                value={adjustForm.points}
                onChange={(e) =>
                  setAdjustForm({ ...adjustForm, points: parseInt(e.target.value) || 0 })
                }
                placeholder="Nhập số điểm"
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                }}
              />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "0.5rem", fontWeight: "500" }}>
                Lý do *
              </label>
              <textarea
                value={adjustForm.reason}
                onChange={(e) => setAdjustForm({ ...adjustForm, reason: e.target.value })}
                placeholder="Nhập lý do điều chỉnh điểm"
                rows={3}
                style={{
                  width: "100%",
                  padding: "0.75rem",
                  border: "1px solid #ddd",
                  borderRadius: "4px",
                  resize: "vertical",
                }}
              />
            </div>
          </div>
        </FormModal>
    </div>
  );
}

