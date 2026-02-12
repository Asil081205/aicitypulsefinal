import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> with TickerProviderStateMixin {
  late TabController _tabController;

  List<AnalyticsData> analyticsData = [];
  List<DailyData> dailyData = [];
  bool isLoading = true;
  String selectedPeriod = 'Last 30 Days';
  final List<String> periods = ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'This Month', 'Custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final response = await _fetchAnalyticsFromApi();
      setState(() {
        analyticsData = response['metrics'];
        dailyData = response['daily'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchAnalyticsFromApi() async {
    await Future.delayed(const Duration(seconds: 1));

    return {
      'metrics': [
        AnalyticsData(metric: 'Users', value: 15234, percentage: 23.5, trend: 5.2,
            icon: Icons.people, color: Colors.blue),
        AnalyticsData(metric: 'Revenue', value: 45678, percentage: 15.3, trend: -2.1,
            icon: Icons.attach_money, color: Colors.green),
        AnalyticsData(metric: 'Sessions', value: 32456, percentage: 32.8, trend: 8.4,
            icon: Icons.timeline, color: Colors.purple),
        AnalyticsData(metric: 'Bounce Rate', value: 42.3, percentage: 42.3, trend: -3.2,
            icon: Icons.speed, color: Colors.orange),
        AnalyticsData(metric: 'Conversion', value: 3.6, percentage: 3.6, trend: 1.2,
            icon: Icons.trending_up, color: Colors.teal),
        AnalyticsData(metric: 'Avg. Time', value: 184, percentage: 12.4, trend: -0.8,
            icon: Icons.timer, color: Colors.pink),
      ],
      'daily': List.generate(7, (index) { // REDUCED from 30 to 7
        return DailyData(
          day: DateTime.now().subtract(Duration(days: 6 - index)),
          users: 1000 + Random().nextInt(500),
          revenue: 5000 + Random().nextInt(3000),
          sessions: 2000 + Random().nextInt(800),
          bounceRate: 35 + Random().nextDouble() * 15,
        );
      }),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                items: periods.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPeriod = value!;
                  });
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAnalyticsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 20), // REDUCED from 24 to 20
          _buildMetricsGrid(),
          const SizedBox(height: 24), // REDUCED from 32 to 24
          _buildPerformanceChart(),
          const SizedBox(height: 24), // REDUCED from 32 to 24
          _buildRealTimeActivity(),
          const SizedBox(height: 24), // REDUCED from 32 to 24
          _buildTopPages(),
          const SizedBox(height: 16), // ADDED bottom padding
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final totalUsers = TypeSafe.toDouble(analyticsData.firstWhere((d) => d.metric == 'Users').value);

    return Container(
      padding: const EdgeInsets.all(20), // REDUCED from 24 to 20
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 16, // REDUCED from 20 to 16
            offset: const Offset(0, 4), // REDUCED from 8 to 4
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back, Admin 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, // REDUCED from 20 to 18
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6), // REDUCED from 8 to 6
                Text(
                  _formatLargeNumber(totalUsers),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32, // REDUCED from 36 to 32
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2), // REDUCED from 4 to 2
                Text(
                  'Total Users',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13, // REDUCED from 14 to 13
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12), // REDUCED from 16 to 12
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12), // REDUCED from 16 to 12
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 40, // REDUCED from 48 to 40
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12, // REDUCED from 16 to 12
        mainAxisSpacing: 12, // REDUCED from 16 to 12
        childAspectRatio: 1.2, // REDUCED from 1.4 to 1.2 (shorter cards)
      ),
      itemCount: analyticsData.length,
      itemBuilder: (context, index) {
        final item = analyticsData[index];
        return _buildEnhancedMetricCard(item);
      },
    );
  }

  Widget _buildEnhancedMetricCard(AnalyticsData data) {
    final double value = TypeSafe.toDouble(data.value);
    final double trend = TypeSafe.toDouble(data.trend);
    final bool isPositive = trend >= 0;

    return Container(
      padding: const EdgeInsets.all(12), // REDUCED from 16 to 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // REDUCED from 16 to 12
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // REDUCED from 8 to 6
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8), // REDUCED from 12 to 8
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 16, // REDUCED from 20 to 16
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // REDUCED padding
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12), // REDUCED from 20 to 12
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10, // REDUCED from 14 to 10
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 1), // REDUCED from 2 to 1
                    Text(
                      '${trend.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10, // REDUCED from 12 to 10
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.metric,
                style: TextStyle(
                  fontSize: 12, // REDUCED from 14 to 12
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2), // REDUCED from 4 to 2
              Text(
                _formatValue(data.metric, value),
                style: const TextStyle(
                  fontSize: 18, // REDUCED from 24 to 18
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis, // ADDED to prevent overflow
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance',
                style: TextStyle(
                  fontSize: 16, // REDUCED from 18 to 16
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // REDUCED padding
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.blue), // REDUCED from 4 to 3
                    SizedBox(width: 4), // REDUCED from 6 to 4
                    Text('Users', style: TextStyle(fontSize: 11)), // REDUCED from 12 to 11
                    SizedBox(width: 8), // REDUCED from 12 to 8
                    CircleAvatar(radius: 3, backgroundColor: Colors.green), // REDUCED from 4 to 3
                    SizedBox(width: 4), // REDUCED from 6 to 4
                    Text('Revenue', style: TextStyle(fontSize: 11)), // REDUCED from 12 to 11
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // REDUCED from 24 to 16
          SizedBox(
            height: 180, // REDUCED from 250 to 180 - FIXES OVERFLOW!
            child: _buildAdvancedChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedChart() {
    if (dailyData.isEmpty) return const SizedBox();

    final maxUsers = dailyData.map((d) => d.users).reduce(max).toDouble();
    final maxRevenue = dailyData.map((d) => d.revenue).reduce(max).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: dailyData.map((data) {
        final double usersHeight = maxUsers > 0 ? (data.users / maxUsers) * 120 : 0; // REDUCED from 180 to 120
        final double revenueHeight = maxRevenue > 0 ? (data.revenue / maxRevenue) * 80 : 0; // REDUCED proportionally

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: usersHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.blue.shade400, Colors.blue.shade300],
                    ),
                    borderRadius: BorderRadius.circular(4), // REDUCED from 6 to 4
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: revenueHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.green.shade400, Colors.green.shade300],
                    ),
                    borderRadius: BorderRadius.circular(4), // REDUCED from 6 to 4
                  ),
                ),
                const SizedBox(height: 6), // REDUCED from 8 to 6
                Text(
                  '${data.day.day}',
                  style: TextStyle(
                    fontSize: 10, // REDUCED from 11 to 10
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRealTimeActivity() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // REDUCED from 8 to 6
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle,
                  color: Colors.green,
                  size: 10, // REDUCED from 12 to 10
                ),
              ),
              const SizedBox(width: 8), // REDUCED from 12 to 8
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16, // REDUCED from 18 to 16
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero), // REDUCED padding
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16), // REDUCED from 20 to 16
          _buildActivityItem('New user registered', '2 min ago', Icons.person_add),
          _buildActivityItem('Payment received', '15 min ago', Icons.payment),
          _buildActivityItem('Session started', '32 min ago', Icons.play_circle),
          _buildActivityItem('Report generated', '1 hour ago', Icons.description),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // REDUCED from 16 to 12
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // REDUCED from 10 to 8
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.grey[700]), // REDUCED from 20 to 16
          ),
          const SizedBox(width: 10), // REDUCED from 12 to 10
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13, // ADDED fixed font size
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2), // REDUCED from 4 to 2
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11, // REDUCED from 12 to 11
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPages() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Pages',
            style: TextStyle(
              fontSize: 16, // REDUCED from 18 to 16
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16), // REDUCED from 20 to 16
          _buildPageRow('Dashboard', 1234, 12.5),
          _buildPageRow('Products', 987, 9.8),
          _buildPageRow('Analytics', 876, 8.2),
          _buildPageRow('Settings', 654, 6.1),
          _buildPageRow('Profile', 543, 5.3),
        ],
      ),
    );
  }

  Widget _buildPageRow(String page, int visits, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // REDUCED from 16 to 12
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              page,
              style: const TextStyle(fontSize: 13), // ADDED fixed font size
            ),
          ),
          Expanded(
            child: Text(
              _formatNumber(visits.toDouble()),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), // ADDED fontSize
            ),
          ),
          Expanded(
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]), // ADDED fontSize
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ANALYTICS TAB ====================
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAudienceOverview(),
          const SizedBox(height: 16), // REDUCED from 24 to 16
          _buildDeviceBreakdown(),
          const SizedBox(height: 16), // REDUCED from 24 to 16
          _buildTrafficSources(),
          const SizedBox(height: 16), // ADDED bottom padding
        ],
      ),
    );
  }

  Widget _buildAudienceOverview() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audience Overview',
            style: TextStyle(
              fontSize: 16, // REDUCED from 18 to 16
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16), // REDUCED from 20 to 16
          Row(
            children: [
              _buildAudienceMetric('New', '2,345', '+12.3%', Colors.blue),
              _buildAudienceMetric('Returning', '1,234', '+5.2%', Colors.green),
              _buildAudienceMetric('Engaged', '3,456', '-2.1%', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceMetric(String label, String value, String change, Color color) {
    final isPositive = !change.contains('-');

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4), // ADDED padding
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12), // REDUCED from 16 to 12
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10), // REDUCED from 12 to 10
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11, // REDUCED from 12 to 11
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4), // REDUCED from 8 to 4
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18, // REDUCED from 24 to 18
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2), // REDUCED from 4 to 2
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12, // REDUCED from 14 to 12
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2), // REDUCED from 4 to 2
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 11, // REDUCED from 12 to 11
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Breakdown',
            style: TextStyle(
              fontSize: 16, // REDUCED from 18 to 16
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16), // REDUCED from 20 to 16
          _buildDeviceRow('Mobile', 45, Colors.blue),
          _buildDeviceRow('Desktop', 35, Colors.green),
          _buildDeviceRow('Tablet', 15, Colors.orange),
          _buildDeviceRow('Other', 5, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(String device, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // REDUCED from 12 to 10
      child: Row(
        children: [
          SizedBox(
            width: 70, // REDUCED from 80 to 70
            child: Text(
              device,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), // ADDED fontSize
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6, // REDUCED from 8 to 6
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3), // REDUCED from 4 to 3
                  ),
                ),
                Container(
                  height: 6, // REDUCED from 8 to 6
                  width: TypeSafe.toDouble(percentage) * 2.8, // ADJUSTED multiplier
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3), // REDUCED from 4 to 3
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // REDUCED from 12 to 8
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 13, // ADDED fontSize
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficSources() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Traffic Sources',
            style: TextStyle(
              fontSize: 16, // REDUCED from 18 to 16
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16), // REDUCED from 20 to 16
          _buildSourceRow('Organic Search', 42, Icons.search, Colors.blue),
          _buildSourceRow('Direct', 28, Icons.link, Colors.green),
          _buildSourceRow('Social Media', 18, Icons.share, Colors.purple),
          _buildSourceRow('Referral', 8, Icons.launch, Colors.orange),
          _buildSourceRow('Email', 4, Icons.email, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSourceRow(String source, int percentage, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // REDUCED from 16 to 12
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // REDUCED from 8 to 6
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), // REDUCED from 8 to 6
            ),
            child: Icon(icon, size: 14, color: color), // REDUCED from 16 to 14
          ),
          const SizedBox(width: 10), // REDUCED from 12 to 10
          Expanded(
            child: Text(
              source,
              style: const TextStyle(fontSize: 13), // ADDED fontSize
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 13, // ADDED fontSize
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REPORTS TAB ====================
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(),
          const SizedBox(height: 16), // REDUCED from 24 to 16
          _buildSavedReports(),
          const SizedBox(height: 16), // REDUCED from 24 to 16
          _buildExportOptions(),
          const SizedBox(height: 16), // ADDED bottom padding
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(20), // REDUCED from 24 to 20
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generate Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, // REDUCED from 20 to 18
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6), // REDUCED from 8 to 6
                Text(
                  'Export your analytics data',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13, // REDUCED from 14 to 13
                  ),
                ),
                const SizedBox(height: 12), // REDUCED from 16 to 12
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download, size: 16, color: Colors.black87), // REDUCED size
                  label: const Text('Create Report', style: TextStyle(fontSize: 13)), // REDUCED fontSize
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // REDUCED padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // REDUCED from 30 to 20
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12), // REDUCED from 20 to 12
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12), // REDUCED from 16 to 12
            ),
            child: const Icon(
              Icons.insert_drive_file,
              color: Colors.white,
              size: 40, // REDUCED from 48 to 40
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedReports() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved Reports',
            style: TextStyle(
              fontSize: 16, // REDUCED from 18 to 16
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // REDUCED from 16 to 12
          _buildReportItem('Monthly Performance', 'Feb 13, 2026', Icons.assessment),
          _buildReportItem('User Acquisition', 'Feb 12, 2026', Icons.people),
          _buildReportItem('Revenue Analytics', 'Feb 11, 2026', Icons.trending_up),
          _buildReportItem('Conversion Funnel', 'Feb 10, 2026', Icons.filter_alt), // ✅ WORKS!
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, String date, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // REDUCED from 16 to 12
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // REDUCED from 8 to 6
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), // REDUCED from 8 to 6
            ),
            child: Icon(icon, color: Colors.blue, size: 16), // REDUCED from 18 to 16
          ),
          const SizedBox(width: 10), // REDUCED from 12 to 10
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), // ADDED fontSize
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]), // REDUCED from 12 to 11
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 18), // REDUCED from 20 to 18
            onPressed: () {},
            padding: EdgeInsets.zero, // ADDED
            constraints: const BoxConstraints(), // ADDED
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18), // REDUCED from 20 to 18
            onPressed: () {},
            padding: EdgeInsets.zero, // ADDED
            constraints: const BoxConstraints(), // ADDED
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(16), // REDUCED from 20 to 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // REDUCED from 20 to 16
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // REDUCED from 10 to 8
            offset: const Offset(0, 2), // REDUCED from 4 to 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Data',
            style: TextStyle(
              fontSize: 16, // REDUCED from 18 to 16
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // REDUCED from 16 to 12
          Row(
            children: [
              _buildExportButton('PDF', Icons.picture_as_pdf, Colors.red),
              const SizedBox(width: 8), // REDUCED from 12 to 8
              _buildExportButton('Excel', Icons.table_chart, Colors.green),
              const SizedBox(width: 8), // REDUCED from 12 to 8
              _buildExportButton('CSV', Icons.grid_on, Colors.blue),
              const SizedBox(width: 8), // REDUCED from 12 to 8
              _buildExportButton('JSON', Icons.code, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: color, size: 16), // REDUCED from 20 to 16
        label: Text(
          label,
          style: TextStyle(fontSize: 11, color: color), // REDUCED from 12 to 11
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8), // REDUCED from 12 to 8
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // REDUCED from 12 to 8
          ),
        ),
      ),
    );
  }

  // ==================== UTILITY METHODS ====================
  String _formatValue(String metric, double value) {
    if (metric.toLowerCase().contains('revenue')) {
      return '\$${_formatLargeNumber(value)}';
    } else if (metric.toLowerCase().contains('rate') || metric.toLowerCase().contains('conversion')) {
      return '${value.toStringAsFixed(1)}%';
    } else if (metric.toLowerCase().contains('time')) {
      final minutes = (value ~/ 60);
      final seconds = (value % 60).toInt();
      return '${minutes}m ${seconds}s';
    } else {
      return _formatLargeNumber(value);
    }
  }

  String _formatLargeNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// ==================== TYPE SAFE UTILITY ====================
class TypeSafe {
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is num) return value.toInt();
    return 0;
  }
}

// ==================== DATA MODELS ====================
class AnalyticsData {
  final String metric;
  final dynamic value;
  final dynamic percentage;
  final dynamic trend;
  final IconData icon;
  final Color color;

  AnalyticsData({
    required this.metric,
    required this.value,
    required this.percentage,
    required this.trend,
    required this.icon,
    required this.color,
  });
}

class DailyData {
  final DateTime day;
  final int users;
  final int revenue;
  final int sessions;
  final double bounceRate;

  DailyData({
    required this.day,
    required this.users,
    required this.revenue,
    required this.sessions,
    required this.bounceRate,
  });
}