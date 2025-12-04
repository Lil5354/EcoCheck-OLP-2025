/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_state.dart';
import 'leaderboard_entry_card.dart';

/// Leaderboard Tab Widget - Hiển thị bảng xếp hạng
class LeaderboardTab extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const LeaderboardTab({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return LeaderboardEntryCard(entry: entries[index]);
      },
    );
  }
}
