import 'package:flutter/material.dart';

class MenuGrid extends StatelessWidget {
  const MenuGrid({super.key});

  final List<Map<String, dynamic>> items = const [
    {
      'label': 'DEPOSIT',
      'icon': Icons.home,
      'badge': 4,
      'color': Color(0xFFEFF6FF),
    },
    {
      'label': 'EXPENSE',
      'icon': Icons.bar_chart,
      'badge': 0,
      'color': Color(0xFFFFFBEB),
    },
    {
      'label': 'INVESTMENTS',
      'icon': Icons.trending_up,
      'badge': 0,
      'color': Color(0xFFF5F3FF),
    },
    {
      'label': 'BALANCE',
      'icon': Icons.account_balance_wallet,
      'badge': 0,
      'color': Color(0xFFECFDF5),
    },
    {
      'label': 'LIABILITIES',
      'icon': Icons.credit_card,
      'badge': 0,
      'color': Color(0xFFFEF2F2),
    },
    {
      'label': 'PAYROLL',
      'icon': Icons.people,
      'badge': 4,
      'color': Color(0xFFEFF6FF),
    },
    {
      'label': 'GOAL',
      'icon': Icons.flag,
      'badge': 0,
      'color': Color(0xFFFFF7ED),
    },
    {
      'label': 'MARKETING',
      'icon': Icons.campaign,
      'badge': 0,
      'color': Color(0xFFF0FDF4),
    },
    {
      'label': 'REMINDER',
      'icon': Icons.alarm,
      'badge': 0,
      'color': Color(0xFFFDF4FF),
    },
    {
      'label': 'PERSONAL',
      'icon': Icons.person,
      'badge': 0,
      'color': Color(0xFFF0F9FF),
    },
    {
      'label': 'SHOPPING',
      'icon': Icons.shopping_bag,
      'badge': 0,
      'color': Color(0xFFFFF1F2),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: item['color'],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'], size: 36, color: Colors.blueGrey.shade700),
              const SizedBox(height: 8),
              Text(
                item['label'],
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (item['badge'] > 0)
          Positioned(
            top: 6,
            right: 6,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: Colors.red,
              child: Text(
                '${item['badge']}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}
