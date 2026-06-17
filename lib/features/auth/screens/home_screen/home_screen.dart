import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../services/app_clock.dart';
import '../../../../services/liability_service.dart';
import '../../models/budget_data.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../user_setting/user_settings_routes.dart';
import '../user_setting/widgets/user_logo_menu_button.dart';
import 'budget_donut_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPeriod = 'Week';
  late DateTime _startDate;
  late DateTime _endDate;
  BudgetData _budgetData = const BudgetData();
  bool _isLoadingBudget = true;
  int _budgetLoadSerial = 0;

  @override
  void initState() {
    super.initState();
    LiabilityService.dataVersion.addListener(_handleBudgetDataChanged);
    _updateDateRange();
    unawaited(_loadBudgetData());
  }

  @override
  void dispose() {
    LiabilityService.dataVersion.removeListener(_handleBudgetDataChanged);
    super.dispose();
  }

  void _handleBudgetDataChanged() {
    if (!mounted) return;
    unawaited(_loadBudgetData());
  }

  void _updateDateRange() {
    final now = AppClock.now;
    _endDate = now;

    switch (_selectedPeriod) {
      case 'Day':
        _startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Month':
        _startDate = DateTime(now.year, now.month);
        break;
      case '3 Months':
        _startDate = DateTime(now.year, now.month - 2);
        break;
      case 'Week':
      default:
        _startDate = now.subtract(const Duration(days: 6));
    }
  }

  Future<void> _loadBudgetData() async {
    final loadSerial = ++_budgetLoadSerial;
    setState(() {
      _updateDateRange();
      _isLoadingBudget = true;
    });

    final startDate = _startDate;
    final endDate = _endDate;
    final data = await LiabilityService.loadBudgetData(
      startDate: startDate,
      endDate: endDate,
      period: '${_formatDate(startDate)} - ${_formatDate(endDate)}',
    );

    if (!mounted || loadSerial != _budgetLoadSerial) return;
    setState(() {
      _budgetData = data;
      _isLoadingBudget = false;
    });
  }

  Future<void> _openAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    if (!mounted) return;
    await _loadBudgetData();
  }

  Future<void> _selectPeriod(String label) async {
    setState(() {
      _selectedPeriod = label;
      _updateDateRange();
    });
    await _loadBudgetData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5ED),
      appBar: AppBar(
        leadingWidth: 64,
        leading: UserLogoMenuButton(
          onPressed: () =>
              Navigator.pushNamed(context, UserSettingsRoutes.settings),
        ),
        title: const Text('SaveTep'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentItem: AppBottomNavItem.home,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBudgetData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangePill(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPeriodButton('Day'),
                  const SizedBox(width: 8),
                  _buildPeriodButton('Week'),
                  const SizedBox(width: 8),
                  _buildPeriodButton('Month'),
                  const SizedBox(width: 8),
                  _buildPeriodButton('3 Months'),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: _isLoadingBudget
                    ? const SizedBox(
                        width: 250,
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : BudgetDonutChart(
                        data: _budgetData,
                        periodKey: _selectedPeriod,
                      ),
              ),
              const SizedBox(height: 28),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _buildFeatureCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'DEPOSIT',
                    color: const Color(0xFFDFF7EA),
                    iconColor: const Color(0xFF0F766E),
                    textColor: const Color(0xFF064E3B),
                    onTap: () => _openAndRefresh('/scan-deposit'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'EXPENSE',
                    color: const Color(0xFFFFE8D6),
                    iconColor: const Color(0xFFB45309),
                    textColor: const Color(0xFF7C2D12),
                    onTap: () => _openAndRefresh('/scan-expense'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.receipt,
                    label: 'TRANSACTION',
                    color: const Color(0xFFE0F2FE),
                    onTap: () => _openAndRefresh('/transactions'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.savings_outlined,
                    label: 'RESERVES',
                    color: const Color.fromARGB(255, 255, 199, 161),
                    iconColor: const Color(0xFF166534),
                    textColor: const Color.fromARGB(255, 12, 99, 4),
                    onTap: () => _openAndRefresh('/reserves'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.flag,
                    label: 'PROFIT & LOSS',
                    color: const Color(0xFFE0F2FE),
                    onTap: () => _openAndRefresh('/tax'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.credit_card,
                    label: 'LIABILITIES',
                    color: const Color(0xFFFED7AA),
                    onTap: () => _openAndRefresh('/liabilities'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.people,
                    label: 'PAYROLL',
                    color: const Color(0xFFFECDD3),
                  ),
                  _buildFeatureCard(
                    icon: Icons.trending_up,
                    label: 'INVESTMENTS',
                    color: const Color(0xFFFCE7F3),
                  ),
                  _buildFeatureCard(
                    icon: Icons.campaign,
                    label: 'MARKETING',
                    color: const Color(0xFFE9D5FF),
                  ),
                  _buildFeatureCard(
                    icon: Icons.notifications,
                    label: 'REMINDER',
                    color: const Color(0xFFFCE7F3),
                    onTap: () => _openAndRefresh('/reminders'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangePill() {
    final periodLabel = _budgetData.period.isEmpty
        ? '${_formatDate(_startDate)} - ${_formatDate(_endDate)}'
        : _budgetData.period;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7DEC9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0E5E54)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              periodLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF173E37),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label) {
    final isSelected = _selectedPeriod == label;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _selectPeriod(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF075E54) : Colors.white,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF173E37),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          side: isSelected
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFD7DEC9), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required Color color,
    Color iconColor = const Color(0xFF1E40AF),
    Color textColor = Colors.black87,
    String? metricValue,
    String? metricLabel,
    VoidCallback? onTap,
  }) {
    final hasMetric = metricValue != null && metricValue.trim().isNotEmpty;
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: hasMetric ? 24 : 28, color: iconColor),
          SizedBox(height: hasMetric ? 6 : 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (hasMetric) ...[
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                metricValue,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            if (metricLabel != null && metricLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                metricLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.68),
                ),
              ),
            ],
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(onTap: onTap, child: card);
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
