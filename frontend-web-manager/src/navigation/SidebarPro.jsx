/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 * Sidebar Navigation Component
 */

import React from "react";
import { NavLink } from "react-router-dom";
import logo from "../assets/ecocheck-logo.svg";
import {
  MdOutlineDashboard,
  MdOutlineMap,
  MdOutlineAnalytics,
  MdOutlineRoute,
  MdSettings,
  MdLocalShipping,
  MdPeopleAlt,
  MdWarehouse,
  MdWarningAmber,
  MdCalendarToday,
  MdAir,
  MdLocationOn,
  MdSensors,
  MdEmojiEvents,
} from "react-icons/md";

const groups = [
  {
    title: "ĐIỀU HƯỚNG",
    items: [
      { to: "/", label: "Bảng điều khiển", icon: <MdOutlineDashboard /> },
    ],
  },
  {
    title: "VẬN HÀNH",
    items: [
      {
        to: "/operations/schedules",
        label: "Lịch thu gom",
        icon: <MdCalendarToday />,
      },
      {
        to: "/operations/route-optimization",
        label: "Tối ưu tuyến đường",
        icon: <MdOutlineRoute />,
      },
      {
        to: "/operations/dynamic-dispatch",
        label: "Điều phối động",
        icon: <MdOutlineMap />,
      },
      {
        to: "/operations/air-quality",
        label: "Chất lượng không khí",
        icon: <MdAir />,
      },
      {
        to: "/operations/poi",
        label: "Điểm quan tâm",
        icon: <MdLocationOn />,
      },
      {
        to: "/operations/sensor-alerts",
        label: "Cảnh báo cảm biến",
        icon: <MdSensors />,
      },
    ],
  },
  {
    title: "PHÂN TÍCH",
    items: [
      {
        to: "/analytics",
        label: "Phân tích & Dự đoán",
        icon: <MdOutlineAnalytics />,
      },
      {
        to: "/gamification",
        label: "Gamification",
        icon: <MdEmojiEvents />,
      },
    ],
  },
  {
    title: "DỮ LIỆU CHỦ",
    items: [
      { to: "/master/fleet", label: "Đội xe", icon: <MdLocalShipping /> },
      { to: "/master/personnel", label: "Nhân sự", icon: <MdPeopleAlt /> },
      {
        to: "/master/depots-dumps",
        label: "Trạm thu gom",
        icon: <MdWarehouse />,
      },
    ],
  },
  {
    title: "BÁO CÁO",
    items: [
      { to: "/reports", label: "Quản lý báo cáo", icon: <MdWarningAmber /> },
    ],
  },
];

export default function SidebarPro() {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <img src={logo} alt="EcoCheck" className="sidebar-logo" />
        <span className="sidebar-brand">EcoCheck</span>
      </div>
      <nav className="nav">
        {groups.map((g) => (
          <div key={g.title} className="nav-group">
            <h6 className="nav-group-title">{g.title}</h6>
            {g.items.map((it) => (
              <NavLink
                key={it.to}
                to={it.to}
                className={({ isActive }) =>
                  `nav-item ${isActive ? "active" : ""}`
                }
              >
                <span className="nav-ico" aria-hidden>
                  {it.icon}
                </span>
                <span>{it.label}</span>
              </NavLink>
            ))}
          </div>
        ))}
      </nav>
      <div className="sidebar-foot">© {new Date().getFullYear()} EcoCheck</div>
    </aside>
  );
}
