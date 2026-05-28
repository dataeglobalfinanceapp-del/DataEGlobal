import 'package:flutter/material.dart';

import '../../../../services/liability_service.dart';
import '../../models/budget_data.dart';
import '../../services/auth_service.dart';
import '../../widgets/budget_sum_chart.dart';

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

  @override
  void initState() {
    super.initState();
    _updateDateRange();
    _loadBudgetData();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    _endDate = now;

    if (_selectedPeriod == 'Month') {
      _startDate = DateTime(now.year, now.month);
    } else if (_selectedPeriod == 'Year') {
      _startDate = DateTime(now.year);
    } else {
      _startDate = now.subtract(const Duration(days: 6));
    }
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoadingBudget = true);
    final data = await LiabilityService.loadBudgetData(
      startDate: _startDate,
      endDate: _endDate,
      period: '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
    );

    if (!mounted) return;
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
      appBar: AppBar(
        title: const Text('FinApp'),
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
      body: RefreshIndicator(
        onRefresh: _loadBudgetData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _isLoadingBudget
                    ? const SizedBox(
                        width: 250,
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : BudgetSumChart(
                        data: _budgetData,
                        periodKey: _selectedPeriod,
                      ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Color(0xFF1E40AF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _budgetData.period.isEmpty
                        ? '${_formatDate(_startDate)} - ${_formatDate(_endDate)}'
                        : _budgetData.period,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildPeriodButton('Week'),
                  const SizedBox(width: 12),
                  _buildPeriodButton('Month'),
                  const SizedBox(width: 12),
                  _buildPeriodButton('Year'),
                ],
              ),
              const SizedBox(height: 32),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _buildFeatureCard(
                    icon: Icons.document_scanner_outlined,
                    label: 'SCAN',
                    color: const Color(0xFFDEFACF),
                    onTap: () => _openAndRefresh('/scan'),
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
                    color: const Color.fromARGB(255, 239, 220, 252),
                    iconColor: const Color(0xFF166534),
                    textColor: const Color(0xFF166534),
                    onTap: () => _openAndRefresh('/reserves'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.trending_up,
                    label: 'INVESTMENTS',
                    color: const Color(0xFFFCE7F3),
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
                    icon: Icons.flag,
                    label: 'TAX',
                    color: const Color(0xFFE0F2FE),
                    onTap: () => _openAndRefresh('/tax'),
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

  Widget _buildPeriodButton(String label) {
    final isSelected = _selectedPeriod == label;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _selectPeriod(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF1F2937) : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: 0,
          side: isSelected
              ? BorderSide.none
              : const BorderSide(color: Colors.grey, width: 1),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required Color color,
    Color iconColor = const Color(0xFF1E40AF),
    Color textColor = Colors.black87,
    VoidCallback? onTap,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
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
