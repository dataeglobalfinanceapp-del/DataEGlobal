import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPeriod = 'Week';
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(Duration(days: 6));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Progress Indicator
            Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: CircularProgressPainter(),
                      size: const Size(250, 250),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '\$0 available',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'SURPLUS 10%',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '\$0M',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: ' / \$0M',
                                style: TextStyle(
                                  color: Color(0xFF1E40AF),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Date Range
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1E40AF)),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Period Toggle
            Row(
              children: [
                _buildPeriodButton('Week'),
                const SizedBox(width: 12),
                _buildPeriodButton('Month'),
                const SizedBox(width: 12),
                _buildPeriodButton('Year'),
              ],
            ),
            const SizedBox(height: 40),

            // Feature Cards Grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
              children: [
                _buildFeatureCard(
                  icon: Icons.home,
                  label: 'DEPOSIT',
                  color: const Color(0xFFE0F2FE),
                ),
                _buildFeatureCard(
                  icon: Icons.shopping_cart,
                  label: 'EXPENSE',
                  color: const Color(0xFFFEF3C7),
                ),
                _buildFeatureCard(
                  icon: Icons.trending_up,
                  label: 'INVESTMENTS',
                  color: const Color(0xFFFCE7F3),
                ),
                _buildFeatureCard(
                  icon: Icons.savings,
                  label: 'RESERVES',
                  color: const Color(0xFFDEFACF),
                ),
                _buildFeatureCard(
                  icon: Icons.receipt,
                  label: 'LIABILITIES',
                  color: const Color(0xFFFED7AA),
                ),
                _buildFeatureCard(
                  icon: Icons.people,
                  label: 'PAYROLL',
                  color: const Color(0xFFFECDD3),
                ),
                _buildFeatureCard(
                  icon: Icons.flag,
                  label: 'GOAL',
                  color: const Color(0xFFE0F2FE),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label) {
    final isSelected = _selectedPeriod == label;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = label;
          });
        },
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
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF1E40AF)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class CircularProgressPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw segments
    final segments = [
      {'color': const Color(0xFF1E40AF), 'sweepAngle': 240}, // Dark blue
      {'color': const Color(0xFF3B82F6), 'sweepAngle': 60}, // Medium blue
      {'color': const Color(0xFF93C5FD), 'sweepAngle': 30}, // Light blue
      {'color': const Color(0xFFBFDBFE), 'sweepAngle': 30}, // Very light blue
    ];

    double startAngle = -90;
    for (var segment in segments) {
      final paint = Paint()
        ..color = segment['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _degreesToRadians(startAngle),
        _degreesToRadians(segment['sweepAngle'] as double),
        false,
        paint,
      );

      startAngle += segment['sweepAngle'] as double;
    }
  }

  double _degreesToRadians(double degrees) { 
    return degrees * (3.14159265359 / 180);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}