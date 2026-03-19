// モード種別
enum SalaryMode { hourly, monthly, project }

class SalarySettings {
  final SalaryMode mode;

  // 時給 / 月給・年収モード
  final double hourlyAmount;
  final double monthlyAmount;
  final double annualAmount;
  final int workDaysPerMonth;
  final double workHoursPerDay;
  final bool useAnnual;

  // 案件単価モード
  final double projectAmount;

  // 案件モード：目標時給（設定時のみ損益分岐点を表示）
  final double targetHourlyRate;

  const SalarySettings({
    this.mode = SalaryMode.hourly,
    this.hourlyAmount = 0,
    this.monthlyAmount = 0,
    this.annualAmount = 0,
    this.workDaysPerMonth = 20,
    this.workHoursPerDay = 8,
    this.useAnnual = false,
    this.projectAmount = 0,
    this.targetHourlyRate = 0,
  });

  /// 時給換算値（時給・月給・年収モード用）
  double get hourlyRate {
    switch (mode) {
      case SalaryMode.hourly:
        return hourlyAmount;
      case SalaryMode.monthly:
        if (useAnnual) {
          final h = workDaysPerMonth * 12 * workHoursPerDay;
          return h <= 0 ? 0 : annualAmount / h;
        } else {
          final h = workDaysPerMonth * workHoursPerDay;
          return h <= 0 ? 0 : monthlyAmount / h;
        }
      case SalaryMode.project:
        return 0;
    }
  }

  /// 目標時給が設定されているか
  bool get hasTargetRate => targetHourlyRate > 0;

  /// 設定が有効かどうか
  bool get isValid {
    switch (mode) {
      case SalaryMode.hourly:
        return hourlyAmount > 0;
      case SalaryMode.monthly:
        return useAnnual ? annualAmount > 0 : monthlyAmount > 0;
      case SalaryMode.project:
        return projectAmount > 0;
    }
  }

  SalarySettings copyWith({
    SalaryMode? mode,
    double? hourlyAmount,
    double? monthlyAmount,
    double? annualAmount,
    int? workDaysPerMonth,
    double? workHoursPerDay,
    bool? useAnnual,
    double? projectAmount,
    double? targetHourlyRate,
  }) {
    return SalarySettings(
      mode: mode ?? this.mode,
      hourlyAmount: hourlyAmount ?? this.hourlyAmount,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      annualAmount: annualAmount ?? this.annualAmount,
      workDaysPerMonth: workDaysPerMonth ?? this.workDaysPerMonth,
      workHoursPerDay: workHoursPerDay ?? this.workHoursPerDay,
      useAnnual: useAnnual ?? this.useAnnual,
      projectAmount: projectAmount ?? this.projectAmount,
      targetHourlyRate: targetHourlyRate ?? this.targetHourlyRate,
    );
  }

  Map<String, dynamic> toMap() => {
        'mode': mode.index,
        'hourlyAmount': hourlyAmount,
        'monthlyAmount': monthlyAmount,
        'annualAmount': annualAmount,
        'workDaysPerMonth': workDaysPerMonth,
        'workHoursPerDay': workHoursPerDay,
        'useAnnual': useAnnual,
        'projectAmount': projectAmount,
        'targetHourlyRate': targetHourlyRate,
      };

  factory SalarySettings.fromMap(Map<String, dynamic> map) => SalarySettings(
        mode: SalaryMode.values[map['mode'] as int? ?? 0],
        hourlyAmount: (map['hourlyAmount'] as num?)?.toDouble() ?? 0,
        monthlyAmount: (map['monthlyAmount'] as num?)?.toDouble() ?? 0,
        annualAmount: (map['annualAmount'] as num?)?.toDouble() ?? 0,
        workDaysPerMonth: map['workDaysPerMonth'] as int? ?? 20,
        workHoursPerDay: (map['workHoursPerDay'] as num?)?.toDouble() ?? 8,
        useAnnual: map['useAnnual'] as bool? ?? false,
        projectAmount: (map['projectAmount'] as num?)?.toDouble() ?? 0,
        targetHourlyRate: (map['targetHourlyRate'] as num?)?.toDouble() ?? 0,
      );
}
