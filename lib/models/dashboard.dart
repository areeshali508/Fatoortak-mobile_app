import 'package:flutter/material.dart';

class DashboardMetricModel {
  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final bool trendUp;

  const DashboardMetricModel({
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
  });
}

class DashboardProgressModel {
  final String title;
  final String value;
  final String subtitle;
  final double progress;

  const DashboardProgressModel({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
  });
}

class DashboardTrendModel {
  final List<double> values;
  final List<String> labels;
  final int highlightIndex;

  const DashboardTrendModel({
    required this.values,
    required this.labels,
    required this.highlightIndex,
  });
}

class DashboardStatModel {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool showDot;
  final String? deltaText;

  const DashboardStatModel({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.showDot,
    required this.deltaText,
  });
}

class DashboardCustomerModel {
  final String name;
  final String time;
  final String amount;
  final String initials;
  final Color color;

  const DashboardCustomerModel({
    required this.name,
    required this.time,
    required this.amount,
    required this.initials,
    required this.color,
  });
}
