import React, { useState, useEffect } from "react";
import SidebarPro from "../../navigation/SidebarPro.jsx";
import Table from "../../components/common/Table.jsx";
import Toast from "../../components/common/Toast.jsx";
import FormModal from "../../components/common/FormModal.jsx";
import TimeSlotView from "../../components/schedule/TimeSlotView.jsx";
import api from "../../lib/api.js";
import { MdViewList, MdViewModule, MdFilterList } from "react-icons/md";
import io from "socket.io-client";

export default function Schedules() {
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);
  const [filterStatus, setFilterStatus] = useState("");
  const [personnel, setPersonnel] = useState([]);
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [selectedSchedule, setSelectedSchedule] = useState(null);
  const [selectedEmployeeId, setSelectedEmployeeId] = useState("");
  const [viewMode, setViewMode] = useState("timeslot"); // 'timeslot' or 'table'
  const [detailsModalOpen, setDetailsModalOpen] = useState(false);

  useEffect(() => {
    loadSchedules();
    loadPersonnel();

    // Connect to Socket.IO for real-time updates
    const socket = io("http://localhost:3000");

    socket.on("connect", () => {
      console.log("✅ Connected to Socket.IO server");
    });

    socket.on("schedule:created", (newSchedule) => {
      console.log("📡 New schedule created:", newSchedule);
      setToast({
        message: `Lịch mới từ ${newSchedule.citizen_name || "người dân"}`,
        type: "success",
      });
      // Add new schedule to the list
      setSchedules((prev) => [newSchedule, ...prev]);
    });

    socket.on("schedule:updated", (updatedSchedule) => {
      console.log("📡 Schedule updated:", updatedSchedule);
      // Update schedule in the list
      setSchedules((prev) =>
        prev.map((s) =>
          (s.schedule_id || s.id) ===
          (updatedSchedule.schedule_id || updatedSchedule.id)
            ? updatedSchedule
            : s
        )
      );
    });

    socket.on("disconnect", () => {
      console.log("❌ Disconnected from Socket.IO server");
    });

    // Cleanup on unmount
    return () => {
      socket.disconnect();
    };
  }, [filterStatus]);

  async function loadPersonnel() {
    try {
      const result = await api.getPersonnel({ status: "active" });
      if (result.ok) {
        const allPersonnel = Array.isArray(result.data) ? result.data : [];
        const filtered = allPersonnel.filter(
          (p) => p.role === "driver" || p.role === "collector"
        );
        setPersonnel(filtered);
      }
    } catch (error) {
      console.error("Error loading personnel:", error);
    }
  }

  function handleAssignEmployee(schedule) {
    setSelectedSchedule(schedule);
    setSelectedEmployeeId(schedule.employee_id || "");
    setAssignModalOpen(true);
  }

  async function handleSaveAssignment() {
    if (!selectedSchedule || !selectedEmployeeId) {
      setToast({ message: "Vui lòng chọn nhân viên", type: "error" });
      return;
    }

    try {
      const result = await api.updateSchedule(
        selectedSchedule.schedule_id || selectedSchedule.id,
        {
          employee_id: selectedEmployeeId,
          status: "assigned",
        }
      );

      if (result.ok) {
        setToast({ message: "Đã gán nhân viên thành công", type: "success" });
        setAssignModalOpen(false);
        setSelectedSchedule(null);
        setSelectedEmployeeId("");
        await loadSchedules();
      } else {
        setToast({ message: result.error || "Có lỗi xảy ra", type: "error" });
      }
    } catch (error) {
      setToast({
        message: "Lỗi khi gán nhân viên: " + error.message,
        type: "error",
      });
    }
  }

  async function handleDeleteSchedule(schedule) {
    if (!window.confirm("Bạn có chắc muốn xóa lịch thu gom này?")) return;

    try {
      const scheduleId = schedule.schedule_id || schedule.id;
      const result = await api.deleteSchedule(scheduleId);

      if (result.ok) {
        setToast({ message: "Đã xóa lịch thu gom", type: "success" });
        await loadSchedules();
      } else {
        setToast({
          message: result.error || "Lỗi khi xóa lịch",
          type: "error",
        });
      }
    } catch (error) {
      setToast({ message: "Lỗi: " + error.message, type: "error" });
    }
  }

  async function loadSchedules() {
    setLoading(true);
    try {
      const params = {};
      if (filterStatus) {
        params.status = filterStatus;
      }

      const result = await api.getSchedules(params);

      if (result.ok) {
        const schedulesData = Array.isArray(result.data) ? result.data : [];
        setSchedules(schedulesData);
      } else {
        setToast({
          message: result.error || "Lỗi khi tải danh sách lịch thu gom",
          type: "error",
        });
        setSchedules([]);
      }
    } catch (error) {
      setToast({
        message: "Lỗi khi tải dữ liệu: " + error.message,
        type: "error",
      });
      setSchedules([]);
    } finally {
      setLoading(false);
    }
  }

  const columns = [
    {
      key: "citizen_name",
      label: "Người đăng ký",
      render: (r) => (
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <div>
            <div style={{ fontWeight: 500 }}>
              {r.citizen_name || r.reporter_name || "N/A"}
            </div>
            <div style={{ fontSize: 12, color: "#666" }}>
              {r.citizen_phone || r.reporter_phone || "-"}
            </div>
          </div>
          {r.photo_urls && r.photo_urls.length > 0 && (
            <div
              style={{
                backgroundColor: "#4caf50",
                color: "white",
                fontSize: 10,
                padding: "2px 6px",
                borderRadius: 12,
                fontWeight: 600,
                whiteSpace: "nowrap",
              }}
              title={`${r.photo_urls.length} ảnh hiện trường`}
            >
              📷 {r.photo_urls.length}
            </div>
          )}
        </div>
      ),
    },
    {
      key: "scheduled_date",
      label: "Ngày thu gom",
      render: (r) => {
        if (!r.scheduled_date) return "-";
        const date = new Date(r.scheduled_date);
        return date.toLocaleDateString("vi-VN", {
          weekday: "short",
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
        });
      },
    },
    {
      key: "time_slot",
      label: "Khung giờ",
      render: (r) => r.time_slot || "-",
    },
    {
      key: "address",
      label: "Địa chỉ",
      render: (r) => {
        if (r.address) {
          const dateStr = r.scheduled_date
            ? new Date(r.scheduled_date).toLocaleDateString("vi-VN", {
                day: "2-digit",
                month: "2-digit",
                year: "numeric",
              })
            : "";
          return (
            <div>
              <div>{r.address}</div>
              {dateStr && (
                <div style={{ fontSize: 12, color: "#666", marginTop: 2 }}>
                  Ngày {dateStr}
                </div>
              )}
            </div>
          );
        }
        return r.latitude && r.longitude
          ? `${r.latitude.toFixed(5)}, ${r.longitude.toFixed(5)}`
          : "-";
      },
    },
    {
      key: "waste_type",
      label: "Loại rác",
      render: (r) => {
        const typeMap = {
          household: "Rác sinh hoạt",
          recyclable: "Rác tái chế",
          bulky: "Rác cồng kềnh",
          hazardous: "Rác độc hại",
          organic: "Rác hữu cơ",
        };
        const displayType = typeMap[r.waste_type] || r.waste_type;
        if (r.waste_type === "bulky") {
          return <div>{displayType} - Bulky waste</div>;
        } else if (r.waste_type === "recyclable") {
          return <div>{displayType} - Recyclable waste</div>;
        }
        return displayType;
      },
    },
    {
      key: "estimated_weight",
      label: "Khối lượng (kg)",
      render: (r) =>
        r.estimated_weight
          ? `${parseFloat(r.estimated_weight).toFixed(2)} kg`
          : "-",
    },
    {
      key: "status",
      label: "Trạng thái",
      render: (r) => {
        const statusMap = {
          pending: { label: "Chờ xử lý", color: "#ff9800" },
          scheduled: { label: "Đã lên lịch", color: "#2196f3" },
          assigned: { label: "Đã gán nhân viên", color: "#9c27b0" },
          in_progress: { label: "Đang thực hiện", color: "#00bcd4" },
          completed: { label: "Hoàn thành", color: "#4caf50" },
          cancelled: { label: "Đã hủy", color: "#f44336" },
          missed: { label: "Bỏ lỡ", color: "#9e9e9e" },
        };
        const status = statusMap[r.status] || {
          label: r.status,
          color: "#666",
        };
        return (
          <span
            style={{
              padding: "4px 8px",
              borderRadius: 12,
              backgroundColor: status.color + "20",
              color: status.color,
              fontSize: 12,
              fontWeight: 500,
            }}
          >
            {status.label}
          </span>
        );
      },
    },
    {
      key: "employee_name",
      label: "Nhân viên",
      render: (r) => (
        <div>
          {r.employee_name ? (
            <div>
              <div>{r.employee_name}</div>
              {r.employee_role && (
                <div style={{ fontSize: 12, color: "#666" }}>
                  {r.employee_role === "driver"
                    ? "Tài xế"
                    : r.employee_role === "collector"
                    ? "Nhân viên thu gom"
                    : r.employee_role}
                </div>
              )}
            </div>
          ) : (
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                flexWrap: "wrap",
              }}
            >
              <span style={{ color: "#999", fontStyle: "italic" }}>
                Chưa gán
              </span>
              {(r.status === "pending" || r.status === "scheduled") && (
                <button
                  className="btn btn-sm"
                  onClick={(e) => {
                    e.stopPropagation();
                    handleAssignEmployee(r);
                  }}
                  style={{
                    padding: "4px 8px",
                    fontSize: 12,
                    backgroundColor: "#2196f3",
                    color: "white",
                    border: "none",
                    borderRadius: 4,
                    cursor: "pointer",
                    whiteSpace: "nowrap",
                  }}
                >
                  Gán nhân viên
                </button>
              )}
            </div>
          )}
        </div>
      ),
    },
    {
      key: "created_at",
      label: "Ngày tạo",
      render: (r) => {
        if (!r.created_at) return "-";
        const date = new Date(r.created_at);
        return date.toLocaleString("vi-VN", {
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
          hour: "2-digit",
          minute: "2-digit",
        });
      },
    },
  ];

  return (
    <div className="app layout">
      <SidebarPro />
      <div className="content">
        <main className="main">
          <div className="container">
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: 20,
                flexWrap: "wrap",
                gap: 16,
              }}
            >
              <h1
                style={{
                  fontSize: 28,
                  fontWeight: 700,
                  color: "var(--text)",
                  margin: 0,
                }}
              >
                Lịch thu gom từ người dân
              </h1>
              <div
                style={{
                  display: "flex",
                  gap: 12,
                  alignItems: "center",
                  flexWrap: "wrap",
                }}
              >
                {/* View mode toggle using new CSS classes */}
                <div className="view-mode-toggle">
                  <button
                    className={`view-mode-btn ${
                      viewMode === "timeslot" ? "active" : ""
                    }`}
                    onClick={() => setViewMode("timeslot")}
                  >
                    <MdViewModule size={18} />
                    Khung giờ
                  </button>
                  <button
                    className={`view-mode-btn ${
                      viewMode === "table" ? "active" : ""
                    }`}
                    onClick={() => setViewMode("table")}
                  >
                    <MdViewList size={18} />
                    Danh sách
                  </button>
                </div>

                {/* Filter using new CSS classes */}
                <div className="filter-bar" style={{ margin: 0 }}>
                  <MdFilterList size={18} />
                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="filter-select"
                  >
                    <option value="">Tất cả trạng thái</option>
                    <option value="scheduled">Đã lên lịch</option>
                    <option value="assigned">Đã gán nhân viên</option>
                    <option value="in_progress">Đang thực hiện</option>
                    <option value="completed">Hoàn thành</option>
                    <option value="cancelled">Đã hủy</option>
                  </select>
                </div>

                <button className="btn btn-primary" onClick={loadSchedules}>
                  🔄 Làm mới
                </button>
              </div>
            </div>

            {/* Statistics Summary */}
            <div className="grid" style={{ marginBottom: 24 }}>
              <div className="col-3">
                <div className="card" style={{ padding: 16 }}>
                  <div
                    style={{
                      fontSize: 13,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Tổng lịch
                  </div>
                  <div
                    style={{
                      fontSize: 28,
                      fontWeight: 700,
                      color: "var(--primary)",
                    }}
                  >
                    {schedules.length}
                  </div>
                </div>
              </div>
              <div className="col-3">
                <div className="card" style={{ padding: 16 }}>
                  <div
                    style={{
                      fontSize: 13,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Đã gán
                  </div>
                  <div
                    style={{
                      fontSize: 28,
                      fontWeight: 700,
                      color: "var(--status-assigned)",
                    }}
                  >
                    {
                      schedules.filter(
                        (s) =>
                          s.status === "assigned" || s.status === "in_progress"
                      ).length
                    }
                  </div>
                </div>
              </div>
              <div className="col-3">
                <div className="card" style={{ padding: 16 }}>
                  <div
                    style={{
                      fontSize: 13,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Hoàn thành
                  </div>
                  <div
                    style={{
                      fontSize: 28,
                      fontWeight: 700,
                      color: "var(--status-completed)",
                    }}
                  >
                    {schedules.filter((s) => s.status === "completed").length}
                  </div>
                </div>
              </div>
              <div className="col-3">
                <div className="card" style={{ padding: 16 }}>
                  <div
                    style={{
                      fontSize: 13,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Chờ xử lý
                  </div>
                  <div
                    style={{
                      fontSize: 28,
                      fontWeight: 700,
                      color: "var(--status-pending)",
                    }}
                  >
                    {
                      schedules.filter(
                        (s) =>
                          s.status === "pending" || s.status === "scheduled"
                      ).length
                    }
                  </div>
                </div>
              </div>
            </div>

            {loading ? (
              <div
                className="card"
                style={{ padding: 60, textAlign: "center" }}
              >
                <div style={{ fontSize: 16, color: "var(--text-secondary)" }}>
                  Đang tải dữ liệu...
                </div>
              </div>
            ) : viewMode === "timeslot" ? (
              <TimeSlotView
                schedules={schedules}
                onAssign={handleAssignEmployee}
                onDelete={handleDeleteSchedule}
                onViewDetails={(schedule) => {
                  setSelectedSchedule(schedule);
                  setDetailsModalOpen(true);
                }}
              />
            ) : (
              <div className="card">
                <Table
                  columns={columns}
                  data={schedules}
                  emptyText="Chưa có lịch thu gom nào"
                />
              </div>
            )}
          </div>
        </main>
      </div>

      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      {assignModalOpen && selectedSchedule && (
        <FormModal
          title="Gán nhân viên cho lịch thu gom"
          open={assignModalOpen}
          onClose={() => {
            setAssignModalOpen(false);
            setSelectedSchedule(null);
            setSelectedEmployeeId("");
          }}
          onSubmit={handleSaveAssignment}
          submitLabel="Gán nhân viên"
        >
          <div style={{ padding: "16px 0" }}>
            <label
              style={{ display: "block", marginBottom: 8, fontWeight: 500 }}
            >
              Chọn nhân viên:
            </label>
            <select
              value={selectedEmployeeId}
              onChange={(e) => setSelectedEmployeeId(e.target.value)}
              style={{
                width: "100%",
                padding: "10px 14px",
                border: "2px solid #E0E0E0",
                borderRadius: "var(--radius)",
                fontSize: 14,
                background: "var(--surface)",
                color: "var(--text)",
              }}
            >
              <option value="">-- Chọn nhân viên --</option>
              {personnel.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name} -{" "}
                  {p.role === "driver"
                    ? "Tài xế"
                    : p.role === "collector"
                    ? "Nhân viên thu gom"
                    : p.role}
                  {p.depot_name && ` (${p.depot_name})`}
                </option>
              ))}
            </select>
            {selectedSchedule && (
              <div
                style={{
                  marginTop: 16,
                  padding: 16,
                  backgroundColor: "var(--surface-variant)",
                  borderRadius: "var(--radius)",
                }}
              >
                <div
                  style={{
                    fontSize: 12,
                    color: "var(--text-secondary)",
                    marginBottom: 8,
                    fontWeight: 600,
                  }}
                >
                  Thông tin lịch thu gom:
                </div>
                <div style={{ fontSize: 14, lineHeight: 1.6 }}>
                  <strong style={{ color: "var(--text)" }}>
                    {selectedSchedule.citizen_name ||
                      selectedSchedule.reporter_name}
                  </strong>
                  <br />
                  <span style={{ color: "var(--text-secondary)" }}>
                    {selectedSchedule.address}
                  </span>
                  <br />
                  <span style={{ color: "var(--text-secondary)" }}>
                    {selectedSchedule.scheduled_date
                      ? new Date(
                          selectedSchedule.scheduled_date
                        ).toLocaleDateString("vi-VN")
                      : "-"}{" "}
                    - {selectedSchedule.time_slot || "-"}
                  </span>
                </div>
              </div>
            )}
          </div>
        </FormModal>
      )}

      {detailsModalOpen && selectedSchedule && (
        <FormModal
          title="Chi tiết lịch thu gom"
          open={detailsModalOpen}
          onClose={() => {
            setDetailsModalOpen(false);
            setSelectedSchedule(null);
          }}
          hideSubmit={true}
        >
          <div style={{ padding: "16px 0" }}>
            <div style={{ display: "grid", gap: 16 }}>
              <div>
                <div
                  style={{
                    fontSize: 12,
                    color: "var(--text-secondary)",
                    marginBottom: 4,
                  }}
                >
                  Người đăng ký
                </div>
                <div style={{ fontSize: 15, fontWeight: 600 }}>
                  {selectedSchedule.citizen_name || "N/A"}
                </div>
                <div style={{ fontSize: 13, color: "var(--text-secondary)" }}>
                  {selectedSchedule.citizen_phone || "-"}
                </div>
              </div>

              <div>
                <div
                  style={{
                    fontSize: 12,
                    color: "var(--text-secondary)",
                    marginBottom: 4,
                  }}
                >
                  Địa chỉ
                </div>
                <div style={{ fontSize: 14 }}>
                  {selectedSchedule.address || "-"}
                </div>
              </div>

              <div className="grid" style={{ gap: 12 }}>
                <div className="col-6">
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Ngày thu gom
                  </div>
                  <div style={{ fontSize: 14 }}>
                    {selectedSchedule.scheduled_date
                      ? new Date(
                          selectedSchedule.scheduled_date
                        ).toLocaleDateString("vi-VN", {
                          weekday: "long",
                          year: "numeric",
                          month: "long",
                          day: "numeric",
                        })
                      : "-"}
                  </div>
                </div>
                <div className="col-6">
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Khung giờ
                  </div>
                  <div style={{ fontSize: 14 }}>
                    {selectedSchedule.time_slot || "-"}
                  </div>
                </div>
              </div>

              <div className="grid" style={{ gap: 12 }}>
                <div className="col-6">
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Loại rác
                  </div>
                  <div style={{ fontSize: 14 }}>
                    {selectedSchedule.waste_type || "-"}
                  </div>
                </div>
                <div className="col-6">
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Khối lượng ước tính
                  </div>
                  <div style={{ fontSize: 14 }}>
                    {selectedSchedule.estimated_weight
                      ? `${parseFloat(
                          selectedSchedule.estimated_weight
                        ).toFixed(2)} kg`
                      : "-"}
                  </div>
                </div>
              </div>

              {selectedSchedule.employee_name && (
                <div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Nhân viên được gán
                  </div>
                  <div style={{ fontSize: 14 }}>
                    {selectedSchedule.employee_name}
                  </div>
                  <div style={{ fontSize: 13, color: "var(--text-secondary)" }}>
                    {selectedSchedule.employee_role || "-"}
                  </div>
                </div>
              )}

              {selectedSchedule.notes && (
                <div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--text-secondary)",
                      marginBottom: 4,
                    }}
                  >
                    Ghi chú
                  </div>
                  <div style={{ fontSize: 14 }}>{selectedSchedule.notes}</div>
                </div>
              )}

              {selectedSchedule.photo_urls &&
                selectedSchedule.photo_urls.length > 0 && (
                  <div>
                    <div
                      style={{
                        fontSize: 12,
                        color: "var(--text-secondary)",
                        marginBottom: 8,
                      }}
                    >
                      Hình ảnh hiện trường ({selectedSchedule.photo_urls.length}{" "}
                      ảnh)
                    </div>
                    <div
                      style={{
                        display: "grid",
                        gridTemplateColumns:
                          selectedSchedule.photo_urls.length === 1
                            ? "1fr"
                            : "repeat(auto-fill, minmax(150px, 1fr))",
                        gap: 12,
                      }}
                    >
                      {selectedSchedule.photo_urls.map((url, index) => (
                        <div
                          key={index}
                          style={{
                            position: "relative",
                            paddingBottom:
                              selectedSchedule.photo_urls.length === 1
                                ? "60%"
                                : "100%",
                            borderRadius: 8,
                            overflow: "hidden",
                            backgroundColor: "#f5f5f5",
                            border: "1px solid #e0e0e0",
                          }}
                        >
                          <img
                            src={url}
                            alt={`Ảnh hiện trường ${index + 1}`}
                            style={{
                              position: "absolute",
                              top: 0,
                              left: 0,
                              width: "100%",
                              height: "100%",
                              objectFit: "cover",
                              cursor: "pointer",
                            }}
                            onClick={() => window.open(url, "_blank")}
                            onError={(e) => {
                              e.target.style.display = "none";
                              e.target.parentElement.innerHTML = `
                                <div style="
                                  position: absolute;
                                  top: 0;
                                  left: 0;
                                  width: 100%;
                                  height: 100%;
                                  display: flex;
                                  align-items: center;
                                  justify-content: center;
                                  flex-direction: column;
                                  gap: 8px;
                                  color: #999;
                                  font-size: 12px;
                                ">
                                  <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                                    <circle cx="8.5" cy="8.5" r="1.5"/>
                                    <polyline points="21 15 16 10 5 21"/>
                                  </svg>
                                  <span>Không thể tải ảnh</span>
                                </div>
                              `;
                            }}
                          />
                          <div
                            style={{
                              position: "absolute",
                              bottom: 4,
                              right: 4,
                              backgroundColor: "rgba(0,0,0,0.6)",
                              color: "white",
                              padding: "2px 6px",
                              borderRadius: 4,
                              fontSize: 11,
                              fontWeight: 500,
                            }}
                          >
                            {index + 1}/{selectedSchedule.photo_urls.length}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
            </div>
          </div>
        </FormModal>
      )}
    </div>
  );
}
