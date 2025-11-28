import React from "react";
import {
  MdAccessTime,
  MdPerson,
  MdLocationOn,
  MdDelete,
  MdAssignment,
} from "react-icons/md";
import "./TimeSlotView.css";

const timeSlots = [
  { id: "morning", label: "Sáng", time: "6:00 - 11:00", icon: "🌅" },
  { id: "afternoon", label: "Chiều", time: "13:00 - 17:00", icon: "☀️" },
  { id: "evening", label: "Tối", time: "17:00 - 20:00", icon: "🌙" },
];

const wasteTypeConfig = {
  household: {
    color: "var(--waste-household)",
    icon: "🏠",
    label: "Sinh hoạt",
  },
  recyclable: {
    color: "var(--waste-recyclable)",
    icon: "♻️",
    label: "Tái chế",
  },
  organic: { color: "var(--waste-organic)", icon: "🌿", label: "Hữu cơ" },
  bulky: { color: "var(--waste-bulky)", icon: "📦", label: "Cồng kềnh" },
  hazardous: { color: "var(--waste-hazardous)", icon: "⚠️", label: "Nguy hại" },
};

const statusConfig = {
  scheduled: { color: "var(--status-scheduled)", label: "Đã lên lịch" },
  assigned: { color: "var(--status-assigned)", label: "Đã phân công" },
  in_progress: { color: "var(--status-in-progress)", label: "Đang thực hiện" },
  completed: { color: "var(--status-completed)", label: "Hoàn thành" },
  cancelled: { color: "var(--status-cancelled)", label: "Đã hủy" },
};

export default function TimeSlotView({
  schedules,
  onAssign,
  onDelete,
  onViewDetails,
}) {
  const groupedSchedules = timeSlots.map((slot) => ({
    ...slot,
    items: schedules.filter((s) => s.time_slot === slot.id),
  }));

  return (
    <div className="timeslot-container">
      {groupedSchedules.map((slot) => (
        <div key={slot.id} className="timeslot-section">
          <div className="timeslot-header">
            <span className="timeslot-icon">{slot.icon}</span>
            <div className="timeslot-info">
              <h3 className="timeslot-title">{slot.label}</h3>
              <p className="timeslot-time">
                <MdAccessTime size={16} />
                {slot.time}
              </p>
            </div>
            <span className="timeslot-count">{slot.items.length}</span>
          </div>

          <div className="timeslot-cards">
            {slot.items.length === 0 ? (
              <div className="empty-slot">
                <p>Chưa có lịch thu gom</p>
              </div>
            ) : (
              slot.items.map((schedule) => (
                <ScheduleCard
                  key={schedule.schedule_id || schedule.id}
                  schedule={schedule}
                  onAssign={onAssign}
                  onDelete={onDelete}
                  onViewDetails={onViewDetails}
                />
              ))
            )}
          </div>
        </div>
      ))}
    </div>
  );
}

function ScheduleCard({ schedule, onAssign, onDelete, onViewDetails }) {
  const wasteType =
    wasteTypeConfig[schedule.waste_type] || wasteTypeConfig.household;
  const status = statusConfig[schedule.status] || statusConfig.scheduled;

  return (
    <div
      className="schedule-card"
      onClick={() => onViewDetails && onViewDetails(schedule)}
    >
      <div className="schedule-card-header">
        <div
          className="waste-type-badge"
          style={{ backgroundColor: wasteType.color }}
        >
          <span className="waste-icon">{wasteType.icon}</span>
          <span className="waste-label">{wasteType.label}</span>
        </div>
        <span
          className="status-badge"
          style={{ backgroundColor: status.color }}
        >
          {status.label}
        </span>
      </div>

      <div className="schedule-card-body">
        <div className="schedule-info-row">
          <MdPerson size={18} className="info-icon" />
          <span className="info-text">
            {schedule.citizen_name || "Chưa xác định"}
          </span>
        </div>

        <div className="schedule-info-row">
          <MdLocationOn size={18} className="info-icon" />
          <span className="info-text">
            {schedule.address || "Chưa có địa chỉ"}
          </span>
        </div>

        {schedule.employee_name && (
          <div className="schedule-info-row assigned">
            <MdAssignment size={18} className="info-icon" />
            <span className="info-text">{schedule.employee_name}</span>
          </div>
        )}

        <div className="schedule-weight">
          <span className="weight-label">Khối lượng ước tính:</span>
          <span className="weight-value">
            {schedule.estimated_weight || 0} kg
          </span>
        </div>
      </div>

      <div className="schedule-card-footer">
        <button
          className="btn-action btn-assign"
          onClick={(e) => {
            e.stopPropagation();
            onAssign && onAssign(schedule);
          }}
        >
          <MdAssignment size={16} />
          {schedule.employee_id ? "Đổi NV" : "Phân công"}
        </button>

        <button
          className="btn-action btn-delete"
          onClick={(e) => {
            e.stopPropagation();
            onDelete && onDelete(schedule);
          }}
        >
          <MdDelete size={16} />
          Xóa
        </button>
      </div>
    </div>
  );
}
