import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/widgets/app_date_range_selector.dart';
import 'package:savetep/providers/expense_category_provider.dart';
import 'package:savetep/services/app_clock.dart';

import 'controllers/profit_loss_controller.dart';
import 'models/profit_loss_state.dart';
import 'repositories/profit_loss_repository.dart';
import 'widgets/profit_loss_statement.dart';
import 'widgets/profit_loss_year_selector.dart';

class ProfitLossScreen extends ConsumerStatefulWidget {
  final DateTimeRange? initialDateRange;

  const ProfitLossScreen({super.key, this.initialDateRange});

  @override
  ConsumerState<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends ConsumerState<ProfitLossScreen> {
  late final ProfitLossController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfitLossController(
      initialDateRange: widget.initialDateRange,
      repository: LiabilityProfitLossRepository(
        expenseCategoryRepository: ref.read(expenseCategoryRepositoryProvider),
      ),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final ProfitLossState state = _controller.state;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profit and Loss',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: _controller.load,
            child: _bodyFor(state),
          ),
        );
      },
    );
  }

  Widget _bodyFor(ProfitLossState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage case final String message) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(
              onPressed: _controller.load,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: <Widget>[
        ProfitLossYearSelector(
          year: state.year,
          onPrevious: () => _controller.changeYear(-1),
          onNext: () => _controller.changeYear(1),
        ),
        const SizedBox(height: 8),
        AppDateRangeSelector(
          key: const ValueKey<String>('profit-loss-date-range-button'),
          range: state.dateRange,
          firstDate: DateTime(state.year - 5),
          lastDate: DateTime(state.year + 5, 12, 31),
          currentDate: AppClock.now,
          helpText: 'Select Profit and Loss period',
          tooltip: 'Select Profit and Loss date range',
          onRangeChanged: _controller.setDateRange,
        ),
        const SizedBox(height: 12),
        ProfitLossStatement(report: _controller.report),
      ],
    );
  }
}
