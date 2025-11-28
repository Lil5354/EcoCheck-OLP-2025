/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Reports Management Page
 */

import React, { useState, useEffect } from "react";
import SidebarPro from "../../navigation/SidebarPro.jsx";
import Table from "../../components/common/Table.jsx";
import FormModal from "../../components/common/FormModal.jsx";
import Toast from "../../components/common/Toast.jsx";
import api from "../../lib/api.js";

export default function Reports() {
  const [activeTab, setActiveTab] = useState("citizen"); // 'citizen' or 'worker'
  const [reports, setReports] = useState([]);
  const [personnel, setPersonnel] = useState([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedReport, setSelectedReport] = useState(null);
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [actionData, setActionData] = useState({
    status: "",
    resolution_notes: "",
    assigned_to: "",
  });
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadReports();
    loadPersonnel();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab]);

  async function loadReports() {
    // Citizen reports: reporter_id starts with user ID pattern
    // Worker reports: check if reporter is in personnel table
    const res = await api.getIncidents({ limit: 100 });
    if (res.ok && Array.isArray(res.data)) {
      // Filter based on active tab
      // For simplicity, we'll use a naming convention:
      // Citizen: reporter_id contains user IDs
      // Worker: reporter_id contains personnel IDs or check against personnel list
      setReports(res.data);
    }
  }

  async function loadPersonnel() {
    const res = await api.getPersonnel({ status: "active" });
    if (res.ok && Array.isArray(res.data)) {
      setPersonnel(res.data);
    }
  }

  function handleViewDetail(report) {
    setSelectedReport(report);
    setDetailModalOpen(true);
  }

  function handleAction(report) {
    setSelectedReport(report);
    setActionData({
      status: report.status,
      resolution_notes: "",
      assigned_to: report.assigned_to || "",
    });
    setModalOpen(true);
  }

  async function handleSubmitAction() {
    if (!selectedReport) return;

    setModalOpen(false);
    const res = await api.updateIncidentStatus(selectedReport.id, actionData);

    if (res.ok) {
      setToast({ message: "Đã cập nhật trạng thái báo cáo", type: "success" });
      loadReports();
    } else {
      setToast({ message: res.error || "Cập nhật thất bại", type: "error" });
    }
  }

  const typeLabels = {
    // Violations
    illegal_dump: "Vứt rác trái phép",
    wrong_classification: "Phân loại sai",
    overloaded_bin: "Thùng rác quá tải",
    littering: "Xả rác bừa bãi",
    burning_waste: "Đốt rác",
    // Damages
    broken_bin: "Thùng rác hỏng",
    damaged_equipment: "Thiết bị hư hỏng",
    road_damage: "Đường bị hư",
    facility_damage: "Cơ sở vật chất hư hỏng",
    // Other
    missed_collection: "Bỏ sót thu gom",
    overflow: "Tràn rác",
    vehicle_issue: "Sự cố xe",
    other: "Khác",
  };

  const statusLabels = {
    pending: "Chờ xử lý",
    open: "Đã mở",
    in_progress: "Đang xử lý",
    resolved: "Đã giải quyết",
    closed: "Đã đóng",
    rejected: "Đã từ chối",
  };

  const priorityLabels = {
    low: "Thấp",
    medium: "Trung bình",
    high: "Cao",
    urgent: "Khẩn cấp",
  };

  const categoryLabels = {
    violation: "Vi phạm",
    damage: "Hư hỏng",
  };

  // Filter reports based on tab
  const filteredReports = reports.filter((r) => {
    if (activeTab === "citizen") {
      // Citizen reports: reporter_id starts with user UUID pattern or not in personnel
      const isPersonnel = personnel.some((p) => p.id === r.reporter_id);
      return !isPersonnel;
    } else {
      // Worker reports: reporter_id in personnel
      return personnel.some((p) => p.id === r.reporter_id);
    }
  });

  const columns = [
    {
      key: "created_at",
      label: "Thời gian",
      render: (r) => new Date(r.created_at).toLocaleString("vi-VN"),
    },
    {
      key: "reporter",
      label: "Người báo cáo",
      render: (r) => r.reporter_name || r.reporter_phone || "N/A",
    },
    {
      key: "category",
      label: "Phân loại",
      render: (r) => categoryLabels[r.report_category] || r.report_category,
    },
    {
      key: "type",
      label: "Loại sự cố",
      render: (r) => typeLabels[r.type] || r.type,
    },
    {
      key: "priority",
      label: "Ưu tiên",
      render: (r) => {
        const colors = {
          low: "#4caf50",
          medium: "#ff9800",
          high: "#ff5722",
          urgent: "#f44336",
        };
        return (
          <span
            style={{
              padding: "4px 8px",
              borderRadius: 4,
              backgroundColor: colors[r.priority] || "#999",
              color: "white",
              fontSize: 12,
              fontWeight: 500,
            }}
          >
            {priorityLabels[r.priority] || r.priority}
          </span>
        );
      },
    },
    {
      key: "status",
      label: "Trạng thái",
      render: (r) => {
        const colors = {
          pending: "#ff9800",
          open: "#2196f3",
          in_progress: "#9c27b0",
          resolved: "#4caf50",
          closed: "#607d8b",
          rejected: "#f44336",
        };
        return (
          <span
            style={{
              padding: "4px 8px",
              borderRadius: 4,
              backgroundColor: colors[r.status] || "#999",
              color: "white",
              fontSize: 12,
              fontWeight: 500,
            }}
          >
            {statusLabels[r.status] || r.status}
          </span>
        );
      },
    },
    {
      key: "photos",
      label: "Ảnh",
      render: (r) => (
        <span style={{ fontSize: 14 }}>📷 {r.image_urls?.length || 0}</span>
      ),
    },
    {
      key: "action",
      label: "Hành động",
      render: (r) => (
        <div style={{ display: "flex", gap: 4 }}>
          <button
            className="btn btn-sm btn-primary"
            onClick={() => handleViewDetail(r)}
          >
            Chi tiết
          </button>
          {r.status !== "closed" && r.status !== "rejected" && (
            <button
              className="btn btn-sm"
              onClick={() => handleAction(r)}
              style={{ backgroundColor: "#4caf50", color: "white" }}
            >
              Xử lý
            </button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <h1 style={{ fontSize: 24, fontWeight: 600, marginBottom: 16 }}>
              Quản lý báo cáo
            </h1>

            {/* Tabs */}
            <div
              style={{
                display: "flex",
                gap: 8,
                marginBottom: 16,
                borderBottom: "2px solid #e0e0e0",
              }}
            >
              <button
                onClick={() => setActiveTab("citizen")}
                style={{
                  padding: "12px 24px",
                  border: "none",
                  background: "none",
                  fontSize: 16,
                  fontWeight: activeTab === "citizen" ? 600 : 400,
                  color: activeTab === "citizen" ? "#1976d2" : "#666",
                  borderBottom:
                    activeTab === "citizen" ? "3px solid #1976d2" : "none",
                  cursor: "pointer",
                  marginBottom: -2,
                }}
              >
                Báo cáo từ người dân ({filteredReports.length})
              </button>
              <button
                onClick={() => setActiveTab("worker")}
                style={{
                  padding: "12px 24px",
                  border: "none",
                  background: "none",
                  fontSize: 16,
                  fontWeight: activeTab === "worker" ? 600 : 400,
                  color: activeTab === "worker" ? "#1976d2" : "#666",
                  borderBottom:
                    activeTab === "worker" ? "3px solid #1976d2" : "none",
                  cursor: "pointer",
                  marginBottom: -2,
                }}
              >
                Báo cáo từ nhân viên ({filteredReports.length})
              </button>
            </div>

            <div className="card">
              <Table
                columns={columns}
                data={filteredReports}
                emptyText={`Không có báo cáo từ ${
                  activeTab === "citizen" ? "người dân" : "nhân viên"
                }`}
              />
            </div>
          </div>
        </main>
      </div>

      {/* Detail Modal */}
      <FormModal
        open={detailModalOpen}
        title="Chi tiết báo cáo"
        onClose={() => setDetailModalOpen(false)}
        onSubmit={() => setDetailModalOpen(false)}
        submitText="Đóng"
      >
        {selectedReport && (
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <div>
              <strong>Người báo cáo:</strong> {selectedReport.reporter_name}
              <br />
              <strong>Số điện thoại:</strong> {selectedReport.reporter_phone}
            </div>
            <div>
              <strong>Phân loại:</strong>{" "}
              {categoryLabels[selectedReport.report_category]}
              <br />
              <strong>Loại sự cố:</strong> {typeLabels[selectedReport.type]}
            </div>
            <div>
              <strong>Mô tả:</strong>
              <p
                style={{
                  marginTop: 8,
                  padding: 12,
                  backgroundColor: "#f5f5f5",
                  borderRadius: 6,
                }}
              >
                {selectedReport.description}
              </p>
            </div>
            <div>
              <strong>Địa chỉ:</strong>{" "}
              {selectedReport.location_address || "Không có"}
              <br />
              <strong>Tọa độ:</strong> {selectedReport.latitude},{" "}
              {selectedReport.longitude}
            </div>
            <div>
              <strong>Ưu tiên:</strong>{" "}
              {priorityLabels[selectedReport.priority]}
              <br />
              <strong>Trạng thái:</strong> {statusLabels[selectedReport.status]}
            </div>
            {selectedReport.assigned_to && (
              <div>
                <strong>Được giao cho:</strong>{" "}
                {personnel.find((p) => p.id === selectedReport.assigned_to)
                  ?.name || "N/A"}
              </div>
            )}
            {selectedReport.resolution_notes && (
              <div>
                <strong>Ghi chú xử lý:</strong>
                <p
                  style={{
                    marginTop: 8,
                    padding: 12,
                    backgroundColor: "#f5f5f5",
                    borderRadius: 6,
                  }}
                >
                  {selectedReport.resolution_notes}
                </p>
              </div>
            )}
            {selectedReport.image_urls &&
              selectedReport.image_urls.length > 0 && (
                <div>
                  <strong>
                    Hình ảnh ({selectedReport.image_urls.length}):
                  </strong>
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns:
                        "repeat(auto-fill, minmax(150px, 1fr))",
                      gap: 8,
                      marginTop: 8,
                    }}
                  >
                    {selectedReport.image_urls.map((url, idx) => (
                      <img
                        key={idx}
                        src={url}
                        alt={`Ảnh ${idx + 1}`}
                        style={{
                          width: "100%",
                          height: 150,
                          objectFit: "cover",
                          borderRadius: 6,
                          cursor: "pointer",
                        }}
                        onClick={() => window.open(url, "_blank")}
                      />
                    ))}
                  </div>
                </div>
              )}
          </div>
        )}
      </FormModal>

      {/* Action Modal */}
      <FormModal
        open={modalOpen}
        title="Xử lý báo cáo"
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmitAction}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div>
            <label
              style={{
                display: "block",
                marginBottom: 4,
                fontSize: 14,
                fontWeight: 500,
              }}
            >
              Trạng thái
            </label>
            <select
              value={actionData.status}
              onChange={(e) =>
                setActionData({ ...actionData, status: e.target.value })
              }
              style={{
                width: "100%",
                padding: "8px 12px",
                border: "1px solid #ccc",
                borderRadius: 6,
              }}
            >
              <option value="pending">Chờ xử lý</option>
              <option value="open">Đã mở</option>
              <option value="in_progress">Đang xử lý</option>
              <option value="resolved">Đã giải quyết</option>
              <option value="closed">Đã đóng</option>
              <option value="rejected">Đã từ chối</option>
            </select>
          </div>

          <div>
            <label
              style={{
                display: "block",
                marginBottom: 4,
                fontSize: 14,
                fontWeight: 500,
              }}
            >
              Giao cho nhân viên
            </label>
            <select
              value={actionData.assigned_to}
              onChange={(e) =>
                setActionData({ ...actionData, assigned_to: e.target.value })
              }
              style={{
                width: "100%",
                padding: "8px 12px",
                border: "1px solid #ccc",
                borderRadius: 6,
              }}
            >
              <option value="">-- Chưa giao --</option>
              {personnel.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name} ({p.role})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label
              style={{
                display: "block",
                marginBottom: 4,
                fontSize: 14,
                fontWeight: 500,
              }}
            >
              Ghi chú xử lý
            </label>
            <textarea
              value={actionData.resolution_notes}
              onChange={(e) =>
                setActionData({
                  ...actionData,
                  resolution_notes: e.target.value,
                })
              }
              rows={4}
              placeholder="Nhập ghi chú về cách xử lý..."
              style={{
                width: "100%",
                padding: "8px 12px",
                border: "1px solid #ccc",
                borderRadius: 6,
                resize: "vertical",
              }}
            />
          </div>
        </div>
      </FormModal>

      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}
