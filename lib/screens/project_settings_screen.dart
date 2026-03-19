import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/salary_settings.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class ProjectSettingsScreen extends StatefulWidget {
  final Project project;
  final int index;

  const ProjectSettingsScreen({
    super.key,
    required this.project,
    required this.index,
  });

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  late SalaryMode _mode;
  late bool _useAnnual;
  late TextEditingController _nameCtrl;
  late TextEditingController _hourlyCtrl;
  late TextEditingController _monthlyCtrl;
  late TextEditingController _annualCtrl;
  late TextEditingController _daysCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _projectCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.project.settings;
    _mode = s.mode;
    _useAnnual = s.useAnnual;
    _nameCtrl = TextEditingController(text: widget.project.name);
    _hourlyCtrl = TextEditingController(
        text: s.hourlyAmount > 0 ? s.hourlyAmount.toStringAsFixed(0) : '');
    _monthlyCtrl = TextEditingController(
        text: s.monthlyAmount > 0 ? s.monthlyAmount.toStringAsFixed(0) : '');
    _annualCtrl = TextEditingController(
        text: s.annualAmount > 0 ? s.annualAmount.toStringAsFixed(0) : '');
    _daysCtrl = TextEditingController(text: s.workDaysPerMonth.toString());
    _hoursCtrl = TextEditingController(text: s.workHoursPerDay.toStringAsFixed(1));
    _projectCtrl = TextEditingController(
        text: s.projectAmount > 0 ? s.projectAmount.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hourlyCtrl.dispose();
    _monthlyCtrl.dispose();
    _annualCtrl.dispose();
    _daysCtrl.dispose();
    _hoursCtrl.dispose();
    _projectCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final settings = SalarySettings(
      mode: _mode,
      hourlyAmount: double.tryParse(_hourlyCtrl.text.replaceAll(',', '')) ?? 0,
      monthlyAmount: double.tryParse(_monthlyCtrl.text.replaceAll(',', '')) ?? 0,
      annualAmount: double.tryParse(_annualCtrl.text.replaceAll(',', '')) ?? 0,
      workDaysPerMonth: (int.tryParse(_daysCtrl.text) ?? 20).clamp(1, 31),
      workHoursPerDay: (double.tryParse(_hoursCtrl.text) ?? 8.0).clamp(0.5, 24.0),
      useAnnual: _useAnnual,
      projectAmount: double.tryParse(_projectCtrl.text.replaceAll(',', '')) ?? 0,
    );

    final provider = context.read<AppProvider>();
    provider.updateProjectSettings(widget.index, settings);
    if (_nameCtrl.text.trim().isNotEmpty) {
      provider.updateProjectName(widget.index, _nameCtrl.text.trim());
    }

    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  double get _previewRate {
    switch (_mode) {
      case SalaryMode.hourly:
        return double.tryParse(_hourlyCtrl.text) ?? 0;
      case SalaryMode.monthly:
        final days = int.tryParse(_daysCtrl.text) ?? 20;
        final hours = double.tryParse(_hoursCtrl.text) ?? 8;
        final h = days * hours;
        if (h <= 0) return 0;
        if (_useAnnual) {
          return (double.tryParse(_annualCtrl.text) ?? 0) / (h * 12);
        } else {
          return (double.tryParse(_monthlyCtrl.text) ?? 0) / h;
        }
      case SalaryMode.project:
        return double.tryParse(_projectCtrl.text) ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close_rounded,
              color: AppTheme.secondary, size: 22),
        ),
        title: Text(
          widget.project.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '保存',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── プロジェクト名 ─────────────────────
              _Label('プロジェクト名'),
              const SizedBox(height: 10),
              _Field(
                ctrl: _nameCtrl,
                hint: '例：Webサイト制作、コンサル案件',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),

              // ── 計算モード ─────────────────────────
              _Label('計算モード'),
              const SizedBox(height: 10),
              _ModeSelector(
                selected: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 28),

              // ── モード別入力 ───────────────────────
              if (_mode == SalaryMode.hourly)
                _HourlySection(
                  ctrl: _hourlyCtrl,
                  onChanged: () => setState(() {}),
                )
              else if (_mode == SalaryMode.monthly)
                _MonthlySection(
                  useAnnual: _useAnnual,
                  monthlyCtrl: _monthlyCtrl,
                  annualCtrl: _annualCtrl,
                  daysCtrl: _daysCtrl,
                  hoursCtrl: _hoursCtrl,
                  onToggle: (v) => setState(() => _useAnnual = v),
                  onChanged: () => setState(() {}),
                )
              else
                _ProjectSection(
                  ctrl: _projectCtrl,
                  onChanged: () => setState(() {}),
                ),

              // ── プレビュー ─────────────────────────
              const SizedBox(height: 28),
              if (_previewRate > 0) ...[
                _PreviewBlock(mode: _mode, rate: _previewRate),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── モードセレクター ─────────────────────────────────
class _ModeSelector extends StatelessWidget {
  final SalaryMode selected;
  final ValueChanged<SalaryMode> onChanged;
  const _ModeSelector({required this.selected, required this.onChanged});

  static const _items = [
    (SalaryMode.hourly, '時給'),
    (SalaryMode.monthly, '月給/年収'),
    (SalaryMode.project, '案件単価'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _items.map((item) {
          final isSelected = selected == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppTheme.onSurface : AppTheme.subtle,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 時給セクション ───────────────────────────────────
class _HourlySection extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onChanged;
  const _HourlySection({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('時給'),
        const SizedBox(height: 10),
        _Field(
          ctrl: ctrl,
          prefix: '¥',
          suffix: '/ 時間',
          hint: '2,000',
          numeric: true,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

// ── 月給・年収セクション ─────────────────────────────
class _MonthlySection extends StatelessWidget {
  final bool useAnnual;
  final TextEditingController monthlyCtrl;
  final TextEditingController annualCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController hoursCtrl;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChanged;

  const _MonthlySection({
    required this.useAnnual,
    required this.monthlyCtrl,
    required this.annualCtrl,
    required this.daysCtrl,
    required this.hoursCtrl,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Chip(label: '月給', active: !useAnnual, onTap: () => onToggle(false)),
            const SizedBox(width: 8),
            _Chip(label: '年収', active: useAnnual, onTap: () => onToggle(true)),
          ],
        ),
        const SizedBox(height: 14),
        if (!useAnnual) ...[
          _Label('月給'),
          const SizedBox(height: 10),
          _Field(
            ctrl: monthlyCtrl,
            prefix: '¥',
            suffix: '/ 月',
            hint: '300,000',
            numeric: true,
            onChanged: (_) => onChanged(),
          ),
        ] else ...[
          _Label('年収'),
          const SizedBox(height: 10),
          _Field(
            ctrl: annualCtrl,
            prefix: '¥',
            suffix: '/ 年',
            hint: '4,000,000',
            numeric: true,
            onChanged: (_) => onChanged(),
          ),
        ],
        const SizedBox(height: 24),
        _Label('勤務条件'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('月の出勤日数', style: AppTheme.bodySmall),
                  const SizedBox(height: 6),
                  _Field(
                    ctrl: daysCtrl,
                    suffix: '日',
                    hint: '20',
                    numeric: true,
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1日の労働時間', style: AppTheme.bodySmall),
                  const SizedBox(height: 6),
                  _Field(
                    ctrl: hoursCtrl,
                    suffix: '時間',
                    hint: '8.0',
                    numeric: true,
                    isDecimal: true,
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 案件単価セクション ───────────────────────────────
class _ProjectSection extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onChanged;
  const _ProjectSection({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('案件金額'),
        const SizedBox(height: 10),
        _Field(
          ctrl: ctrl,
          prefix: '¥',
          hint: '100,000',
          numeric: true,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'ストップウォッチを動かすと、時間経過とともに「実質時給」がリアルタイムで下がっていきます。効率の価値を数字で実感できます。',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.subtle,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}

// ── プレビューブロック ────────────────────────────────
class _PreviewBlock extends StatelessWidget {
  final SalaryMode mode;
  final double rate;
  const _PreviewBlock({required this.mode, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode == SalaryMode.project ? '時給シミュレーション' : '時給換算',
            style: AppTheme.sectionLabel,
          ),
          const SizedBox(height: 12),
          if (mode != SalaryMode.project) ...[
            Text(
              '${formatYen(rate)} / h',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: AppTheme.onSurface,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 0.5, color: AppTheme.divider),
            const SizedBox(height: 12),
            _Row('1分間の価値', formatYen(rate / 60, showDecimal: true)),
            const SizedBox(height: 7),
            _Row('1日 8時間の価値', formatYen(rate * 8)),
            const SizedBox(height: 7),
            _Row('1週間（40h）の価値', formatYen(rate * 40)),
          ] else ...[
            _Row('5時間で完了した場合', '${formatYen(rate / 5)} / h'),
            const SizedBox(height: 7),
            _Row('10時間で完了した場合', '${formatYen(rate / 10)} / h'),
            const SizedBox(height: 7),
            _Row('20時間で完了した場合', '${formatYen(rate / 20)} / h'),
            const SizedBox(height: 7),
            _Row('40時間で完了した場合', '${formatYen(rate / 40)} / h'),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String l;
  final String v;
  const _Row(this.l, this.v);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 13, color: AppTheme.subtle)),
          Text(
            v,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
}

// ── 共通パーツ ───────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTheme.sectionLabel);
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String? prefix;
  final String? suffix;
  final String hint;
  final bool numeric;
  final bool isDecimal;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.ctrl,
    this.prefix,
    this.suffix,
    required this.hint,
    this.numeric = false,
    this.isDecimal = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? (isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number)
          : TextInputType.text,
      inputFormatters: numeric && !isDecimal
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppTheme.onSurface,
      ),
      decoration: InputDecoration(
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: const TextStyle(fontSize: 16, color: AppTheme.subtle),
        suffixText: suffix,
        suffixStyle: const TextStyle(fontSize: 13, color: AppTheme.subtle),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16, color: AppTheme.divider),
        filled: true,
        fillColor: AppTheme.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.onSurface, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.onSurface : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.subtle,
          ),
        ),
      ),
    );
  }
}
