/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Reports Management Page - Redesigned based on Mobile App
 */

import React, { useState, useEffect } from "react";
import SidebarPro from "../../navigation/SidebarPro.jsx";
import FormModal from "../../components/common/FormModal.jsx";
import ConfirmDialog from "../../components/common/ConfirmDialog.jsx";
import Toast from "../../components/common/Toast.jsx";
import api from "../../lib/api.js";

export default function Reports() {
  const [activeTab, setActiveTab] = useState("citizen"); // 'citizen' or 'worker'
  const [activeCategory, setActiveCategory] = useState("all"); // 'all', 'violation', 'damage'
  const [reports, setReports] = useState([]);
  const [personnel, setPersonnel] = useState([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedReport, setSelectedReport] = useState(null);
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [actionData, setActionData] = useState({
    status: "",
    resolution_notes: "",
    assigned_to: "",
  });
  const [toast, setToast] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadReports();
    loadPersonnel();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab]);

  async function loadReports() {
    setLoading(true);
    try {
      const res = await api.getIncidents({ limit: 1000 });
      if (res.ok && Array.isArray(res.data)) {
        setReports(res.data);
      } else {
        setToast({ message: res.error || "Không thể tải danh sách báo cáo", type: "error" });
        setReports([]);
      }
    } catch (error) {
      console.error("Error loading reports:", error);
      setToast({ message: "Lỗi khi tải danh sách báo cáo", type: "error" });
      setReports([]);
    } finally {
      setLoading(false);
    }
  }

  async function loadPersonnel() {
    const res = await api.getPersonnel({ status: "active" });
    if (res.ok && Array.isArray(res.data)) {
      setPersonnel(res.data);
    }
  }

  async function handleViewDetail(report) {
    try {
      const res = await api.getIncident(report.id);
      if (res.ok && res.data) {
        setSelectedReport(res.data);
      } else {
        setSelectedReport(report);
      }
    } catch (error) {
      console.error("Error fetching report details:", error);
      setSelectedReport(report);
    }
    setDetailModalOpen(true);
  }

  function handleAction(report) {
    setSelectedReport(report);
    setActionData({
      status: report.status,
      resolution_notes: report.resolution_notes || "",
      assigned_to: report.assigned_to || "",
    });
    setModalOpen(true);
  }

  async function handleSubmitAction() {
    if (!selectedReport) return;

    setLoading(true);
    setModalOpen(false);
    try {
      const res = await api.updateIncidentStatus(selectedReport.id, actionData);

      if (res.ok) {
        setToast({ message: "Đã cập nhật trạng thái báo cáo", type: "success" });
        await Promise.all([loadReports(), loadPersonnel()]);
        setSelectedReport(null);
      } else {
        setToast({ message: res.error || "Cập nhật thất bại", type: "error" });
      }
    } catch (error) {
      console.error("Error updating report:", error);
      setToast({ message: "Lỗi khi cập nhật báo cáo", type: "error" });
    } finally {
      setLoading(false);
    }
  }

  async function handleDelete() {
    if (!selectedReport) return;

    setLoading(true);
    setDeleteConfirmOpen(false);
    try {
      const res = await api.deleteIncident(selectedReport.id);

      if (res.ok) {
        setToast({ message: "Đã xóa báo cáo", type: "success" });
        setSelectedReport(null);
        await loadReports();
      } else {
        setToast({ message: res.error || "Xóa thất bại", type: "error" });
      }
    } catch (error) {
      console.error("Error deleting report:", error);
      setToast({ message: "Lỗi khi xóa báo cáo", type: "error" });
    } finally {
      setLoading(false);
    }
  }

  function handleDeleteClick(report) {
    setSelectedReport(report);
    setDeleteConfirmOpen(true);
  }

  const typeLabels = {
    illegal_dump: "Vứt rác trái phép",
    wrong_classification: "Phân loại sai",
    overloaded_bin: "Thùng rác quá tải",
    littering: "Xả rác bừa bãi",
    burning_waste: "Đốt rác",
    broken_bin: "Thùng rác hỏng",
    damaged_equipment: "Thiết bị hư hỏng",
    road_damage: "Đường bị hư",
    facility_damage: "Cơ sở vật chất hư hỏng",
    missed_collection: "Bỏ sót thu gom",
    overflow: "Tràn rác",
    vehicle_issue: "Sự cố xe",
    other: "Khác",
  };

  const statusLabels = {
    pending: "Chờ xử lý",
    open: "Đã tiếp nhận",
    in_progress: "Đang xử lý",
    resolved: "Đã giải quyết",
    closed: "Đã đóng",
    rejected: "Từ chối",
  };

  const statusColors = {
    pending: "#ff9800",
    open: "#2196f3",
    in_progress: "#9c27b0",
    resolved: "#4caf50",
    closed: "#607d8b",
    rejected: "#f44336",
  };

  const statusIcons = {
    pending: "⏰",
    open: "📋",
    in_progress: "🔄",
    resolved: "✅",
    closed: "🔒",
    rejected: "❌",
  };

  const priorityLabels = {
    low: "Thấp",
    medium: "Trung bình",
    high: "Cao",
    urgent: "Khẩn cấp",
  };

  const priorityColors = {
    low: "#4caf50",
    medium: "#ff9800",
    high: "#ff5722",
    urgent: "#f44336",
  };

  const categoryLabels = {
    violation: "Vi phạm",
    damage: "Hư hỏng",
  };

  // Filter reports based on tab and category
  const filteredReports = reports.filter((r) => {
    if (!r.reporter_id) return false;

    // Filter by tab (citizen/worker)
    if (activeTab === "citizen") {
      const isPersonnel = personnel.some((p) => p.id === r.reporter_id);
      if (isPersonnel) return false;
      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(r.reporter_id) && personnel.length > 0) return false;
    } else {
      const isPersonnel = personnel.some((p) => p.id === r.reporter_id);
      if (!isPersonnel) return false;
    }

    // Filter by category
    if (activeCategory !== "all" && r.report_category !== activeCategory) {
      return false;
    }

    return true;
  });

  // Get reporter name
  function getReporterName(report) {
    const personnelMember = personnel.find((p) => p.id === report.reporter_id);
    if (personnelMember) {
      return personnelMember.name || `Nhân viên ${report.reporter_id.substring(0, 8)}`;
    }
    if (report.reporter_name) {
      return report.reporter_name;
    }
    return "Người dùng";
  }

  // Get reporter phone
  function getReporterPhone(report) {
    const personnelMember = personnel.find((p) => p.id === report.reporter_id);
    if (personnelMember) {
      return personnelMember.phone || "N/A";
    }
    return report.reporter_phone || "N/A";
  }

  // Format date
  function formatDate(dateString) {
    if (!dateString) return "N/A";
    const date = new Date(dateString);
    const now = new Date();
    const diff = now - date;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 60) {
      return `${minutes} phút trước`;
    } else if (hours < 24) {
      return `${hours} giờ trước`;
    } else if (days === 1) {
      return "Hôm qua";
    } else if (days < 7) {
      return `${days} ngày trước`;
    } else {
      return date.toLocaleDateString("vi-VN");
    }
  }

  // Parse image URLs
  function parseImageUrls(imageUrls) {
    if (!imageUrls) return [];
    if (Array.isArray(imageUrls)) return imageUrls;
    if (typeof imageUrls === "string") {
      if (imageUrls.startsWith("{") && imageUrls.endsWith("}")) {
        return imageUrls.substring(1, imageUrls.length - 1).split(",").filter((s) => s.trim());
      }
      return [imageUrls];
    }
    return [];
  }

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
                onClick={() => {
                  setActiveTab("citizen");
                  setActiveCategory("all");
                }}
                style={{
                  padding: "12px 24px",
                  border: "none",
                  background: "none",
                  fontSize: 16,
                  fontWeight: activeTab === "citizen" ? 600 : 400,
                  color: activeTab === "citizen" ? "#1976d2" : "#666",
                  borderBottom: activeTab === "citizen" ? "3px solid #1976d2" : "none",
                  cursor: "pointer",
                  marginBottom: -2,
                }}
              >
                Báo cáo từ người dân (
                {reports.filter((r) => {
                  if (!r.reporter_id) return false;
                  const isPersonnel = personnel.some((p) => p.id === r.reporter_id);
                  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
                  return !isPersonnel && (uuidPattern.test(r.reporter_id) || !personnel.length);
                }).length}
                )
              </button>
              <button
                onClick={() => {
                  setActiveTab("worker");
                  setActiveCategory("all");
                }}
                style={{
                  padding: "12px 24px",
                  border: "none",
                  background: "none",
                  fontSize: 16,
                  fontWeight: activeTab === "worker" ? 600 : 400,
                  color: activeTab === "worker" ? "#1976d2" : "#666",
                  borderBottom: activeTab === "worker" ? "3px solid #1976d2" : "none",
                  cursor: "pointer",
                  marginBottom: -2,
                }}
              >
                Báo cáo từ nhân viên (
                {reports.filter((r) => {
                  if (!r.reporter_id) return false;
                  return personnel.some((p) => p.id === r.reporter_id);
                }).length}
                )
              </button>
            </div>

            {/* Category Filter */}
            <div
              style={{
                display: "flex",
                gap: 8,
                marginBottom: 16,
                padding: "8px 0",
              }}
            >
              <button
                onClick={() => setActiveCategory("all")}
                style={{
                  padding: "8px 16px",
                  border: "1px solid #ddd",
                  borderRadius: 6,
                  background: activeCategory === "all" ? "#1976d2" : "white",
                  color: activeCategory === "all" ? "white" : "#666",
                  cursor: "pointer",
                  fontSize: 14,
                }}
              >
                Tất cả
              </button>
              <button
                onClick={() => setActiveCategory("violation")}
                style={{
                  padding: "8px 16px",
                  border: "1px solid #ddd",
                  borderRadius: 6,
                  background: activeCategory === "violation" ? "#f44336" : "white",
                  color: activeCategory === "violation" ? "white" : "#666",
                  cursor: "pointer",
                  fontSize: 14,
                }}
              >
                Vi phạm
              </button>
              <button
                onClick={() => setActiveCategory("damage")}
                style={{
                  padding: "8px 16px",
                  border: "1px solid #ddd",
                  borderRadius: 6,
                  background: activeCategory === "damage" ? "#ff9800" : "white",
                  color: activeCategory === "damage" ? "white" : "#666",
                  cursor: "pointer",
                  fontSize: 14,
                }}
              >
                Hư hỏng
              </button>
            </div>

            {/* Reports List */}
            {loading && filteredReports.length === 0 ? (
              <div style={{ padding: 40, textAlign: "center", color: "#666" }}>
                Đang tải...
              </div>
            ) : filteredReports.length === 0 ? (
              <div style={{ padding: 40, textAlign: "center", color: "#666" }}>
                <div style={{ fontSize: 48, marginBottom: 16 }}>📋</div>
                <div style={{ fontSize: 16, marginBottom: 8 }}>
                  Không có báo cáo từ {activeTab === "citizen" ? "người dân" : "nhân viên"}
                  {activeCategory !== "all" && ` - ${categoryLabels[activeCategory]}`}
                </div>
              </div>
            ) : (
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fill, minmax(400px, 1fr))",
                  gap: 16,
                }}
              >
                {filteredReports.map((report) => {
                  const imageUrls = parseImageUrls(report.image_urls);
                  const statusColor = statusColors[report.status] || "#999";
                  const priorityColor = priorityColors[report.priority] || "#999";

                  return (
                    <div
                      key={report.id}
                      style={{
                        background: "white",
                        borderRadius: 12,
                        padding: 16,
                        boxShadow: "0 2px 8px rgba(0,0,0,0.1)",
                        border: "1px solid #e0e0e0",
                        cursor: "pointer",
                        transition: "all 0.2s",
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.boxShadow = "0 4px 12px rgba(0,0,0,0.15)";
                        e.currentTarget.style.transform = "translateY(-2px)";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.boxShadow = "0 2px 8px rgba(0,0,0,0.1)";
                        e.currentTarget.style.transform = "translateY(0)";
                      }}
                      onClick={() => handleViewDetail(report)}
                    >
                      {/* Header */}
                      <div
                        style={{
                          display: "flex",
                          justifyContent: "space-between",
                          alignItems: "flex-start",
                          marginBottom: 12,
                        }}
                      >
                        <div style={{ flex: 1 }}>
                          <div
                            style={{
                              fontSize: 16,
                              fontWeight: 600,
                              marginBottom: 4,
                              color: "#333",
                            }}
                          >
                            {typeLabels[report.type] || report.type}
                          </div>
                          <div style={{ fontSize: 12, color: "#666" }}>
                            {categoryLabels[report.report_category] || report.report_category}
                          </div>
                        </div>
                        <div
                          style={{
                            padding: "6px 12px",
                            borderRadius: 20,
                            background: `${statusColor}15`,
                            border: `1px solid ${statusColor}`,
                            display: "flex",
                            alignItems: "center",
                            gap: 6,
                            fontSize: 12,
                            fontWeight: 500,
                            color: statusColor,
                          }}
                        >
                          <span>{statusIcons[report.status] || "📋"}</span>
                          <span>{statusLabels[report.status] || report.status}</span>
                        </div>
                      </div>

                      {/* Description */}
                      {report.description && (
                        <div
                          style={{
                            fontSize: 14,
                            color: "#666",
                            marginBottom: 12,
                            lineHeight: 1.5,
                            display: "-webkit-box",
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: "vertical",
                            overflow: "hidden",
                          }}
                        >
                          {report.description}
                        </div>
                      )}

                      {/* Images Preview */}
                      {imageUrls.length > 0 && (
                        <div
                          style={{
                            display: "flex",
                            gap: 8,
                            marginBottom: 12,
                            overflowX: "auto",
                          }}
                        >
                          {imageUrls.slice(0, 3).map((url, idx) => (
                            <img
                              key={idx}
                              src={url}
                              alt={`Ảnh ${idx + 1}`}
                              style={{
                                width: 60,
                                height: 60,
                                objectFit: "cover",
                                borderRadius: 8,
                                border: "1px solid #e0e0e0",
                              }}
                              onError={(e) => {
                                e.target.style.display = "none";
                              }}
                            />
                          ))}
                          {imageUrls.length > 3 && (
                            <div
                              style={{
                                width: 60,
                                height: 60,
                                borderRadius: 8,
                                background: "#f5f5f5",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                fontSize: 12,
                                fontWeight: 600,
                                color: "#666",
                                border: "1px solid #e0e0e0",
                              }}
                            >
                              +{imageUrls.length - 3}
                            </div>
                          )}
                        </div>
                      )}

                      {/* Footer */}
                      <div
                        style={{
                          display: "flex",
                          justifyContent: "space-between",
                          alignItems: "center",
                          paddingTop: 12,
                          borderTop: "1px solid #f0f0f0",
                        }}
                      >
                        <div style={{ fontSize: 12, color: "#666" }}>
                          <div>👤 {getReporterName(report)}</div>
                          <div style={{ marginTop: 4 }}>
                            ⏰ {formatDate(report.created_at)}
                          </div>
                        </div>
                        <div
                          style={{
                            padding: "4px 8px",
                            borderRadius: 4,
                            background: `${priorityColor}15`,
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: 500,
                          }}
                        >
                          {priorityLabels[report.priority] || report.priority}
                        </div>
                      </div>

                      {/* Action Buttons */}
                      <div
                        style={{
                          display: "flex",
                          gap: 8,
                          marginTop: 12,
                        }}
                        onClick={(e) => e.stopPropagation()}
                      >
                        <button
                          className="btn btn-sm btn-primary"
                          onClick={() => handleViewDetail(report)}
                          disabled={loading}
                          style={{ flex: 1 }}
                        >
                          Chi tiết
                        </button>
                        {report.status !== "closed" && report.status !== "rejected" && (
                          <button
                            className="btn btn-sm"
                            onClick={() => handleAction(report)}
                            disabled={loading}
                            style={{
                              flex: 1,
                              backgroundColor: "#4caf50",
                              color: "white",
                            }}
                          >
                            Xử lý
                          </button>
                        )}
                        <button
                          className="btn btn-sm"
                          onClick={() => handleDeleteClick(report)}
                          disabled={loading}
                          style={{
                            backgroundColor: "#dc2626",
                            color: "white",
                          }}
                        >
                          Xóa
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </main>
      </div>

      {/* Detail Modal */}
      <FormModal
        open={detailModalOpen}
        title="Chi tiết báo cáo"
        onClose={() => {
          setDetailModalOpen(false);
          setSelectedReport(null);
        }}
        onSubmit={() => {
          setDetailModalOpen(false);
          setSelectedReport(null);
        }}
        submitText="Đóng"
      >
        {selectedReport && (
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            <div>
              <strong>Người báo cáo:</strong> {getReporterName(selectedReport)}
              <br />
              <strong>Số điện thoại:</strong> {getReporterPhone(selectedReport)}
              <br />
              <strong>ID:</strong> {selectedReport.reporter_id}
            </div>
            <div>
              <strong>Phân loại:</strong>{" "}
              {selectedReport.report_category
                ? categoryLabels[selectedReport.report_category] || selectedReport.report_category
                : "Chưa phân loại"}
              <br />
              <strong>Loại sự cố:</strong>{" "}
              {selectedReport.type
                ? typeLabels[selectedReport.type] || selectedReport.type
                : "N/A"}
            </div>
            <div>
              <strong>Mô tả:</strong>
              <p
                style={{
                  marginTop: 8,
                  padding: 12,
                  backgroundColor: "#f5f5f5",
                  borderRadius: 6,
                  whiteSpace: "pre-wrap",
                }}
              >
                {selectedReport.description || "Không có mô tả"}
              </p>
            </div>
            <div>
              <strong>Địa chỉ:</strong> {selectedReport.location_address || "Không có"}
              <br />
              <strong>Tọa độ:</strong>{" "}
              {selectedReport.latitude && selectedReport.longitude
                ? `${selectedReport.latitude}, ${selectedReport.longitude}`
                : "N/A"}
            </div>
            <div>
              <strong>Ưu tiên:</strong>{" "}
              {selectedReport.priority
                ? priorityLabels[selectedReport.priority] || selectedReport.priority
                : "N/A"}
              <br />
              <strong>Trạng thái:</strong>{" "}
              {selectedReport.status
                ? statusLabels[selectedReport.status] || selectedReport.status
                : "N/A"}
            </div>
            <div>
              <strong>Thời gian tạo:</strong>{" "}
              {selectedReport.created_at
                ? new Date(selectedReport.created_at).toLocaleString("vi-VN")
                : "N/A"}
              <br />
              {selectedReport.updated_at && (
                <>
                  <strong>Thời gian cập nhật:</strong>{" "}
                  {new Date(selectedReport.updated_at).toLocaleString("vi-VN")}
                  <br />
                </>
              )}
              {selectedReport.resolved_at && (
                <>
                  <strong>Thời gian giải quyết:</strong>{" "}
                  {new Date(selectedReport.resolved_at).toLocaleString("vi-VN")}
                </>
              )}
            </div>
            {selectedReport.assigned_to && (
              <div>
                <strong>Được giao cho:</strong>{" "}
                {personnel.find((p) => p.id === selectedReport.assigned_to)?.name || "N/A"}
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
                    whiteSpace: "pre-wrap",
                  }}
                >
                  {selectedReport.resolution_notes}
                </p>
              </div>
            )}
            {parseImageUrls(selectedReport.image_urls).length > 0 && (
              <div>
                <strong>Hình ảnh ({parseImageUrls(selectedReport.image_urls).length}):</strong>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fill, minmax(150px, 1fr))",
                    gap: 8,
                    marginTop: 8,
                  }}
                >
                  {parseImageUrls(selectedReport.image_urls).map((url, idx) => (
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
                        border: "1px solid #e0e0e0",
                      }}
                      onClick={() => window.open(url, "_blank")}
                      onError={(e) => {
                        e.target.style.display = "none";
                      }}
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
        onClose={() => {
          setModalOpen(false);
          setSelectedReport(null);
        }}
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
              onChange={(e) => setActionData({ ...actionData, status: e.target.value })}
              style={{
                width: "100%",
                padding: "8px 12px",
                border: "1px solid #ccc",
                borderRadius: 6,
              }}
            >
              <option value="pending">Chờ xử lý</option>
              <option value="open">Đã tiếp nhận</option>
              <option value="in_progress">Đang xử lý</option>
              <option value="resolved">Đã giải quyết</option>
              <option value="closed">Đã đóng</option>
              <option value="rejected">Từ chối</option>
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
              onChange={(e) => setActionData({ ...actionData, assigned_to: e.target.value })}
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

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        open={deleteConfirmOpen}
        title="Xác nhận xóa báo cáo"
        message={`Bạn có chắc chắn muốn xóa báo cáo này? Hành động này không thể hoàn tác.`}
        onConfirm={handleDelete}
        onCancel={() => {
          setDeleteConfirmOpen(false);
          setSelectedReport(null);
        }}
        confirmLabel="Xóa"
        cancelLabel="Hủy"
      />

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
