import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tution/providers/student_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tution/models/student.dart';
import 'package:tution/models/payment.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  List<MapEntry<String, int>> _standardCounts = [];
  List<MapEntry<String, int>> _schoolCounts = [];
  late TabController _tabController;
  String? _selectedSchool;
  String? _selectedStandard;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
    _loadStandardAndSchoolDistribution();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analytics =
          await Provider.of<StudentProvider>(context, listen: false)
              .getFeesAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  Future<void> _loadStandardAndSchoolDistribution() async {
    final students =
        Provider.of<StudentProvider>(context, listen: false).students;
    final Map<String, int> standardMap = {};
    final Map<String, int> schoolMap = {};
    for (var student in students) {
      final standard = (student.standard ?? 'Unknown').trim();
      final school = (student.schoolName ?? 'Unknown').trim();
      standardMap[standard] = (standardMap[standard] ?? 0) + 1;
      schoolMap[school] = (schoolMap[school] ?? 0) + 1;
    }
    setState(() {
      _standardCounts = standardMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      _schoolCounts = schoolMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Distribution'),
            Tab(text: 'Trends'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Data',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Report',
            onPressed: _downloadAnalyticsReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('No data available'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildDistributionTab(),
                    _buildTrendsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterInfo(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildCollectionChart(),
          const SizedBox(height: 24),
          _buildTopPerformers(),
          const SizedBox(height: 24),
          _buildPendingPayments(),
        ],
      ),
    );
  }

  Widget _buildDistributionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterInfo(),
          const SizedBox(height: 24),
          _buildStandardBarChart(),
          const SizedBox(height: 24),
          _buildSchoolBarChart(),
          const SizedBox(height: 24),
          _buildPaymentModeDistribution(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterInfo(),
          const SizedBox(height: 24),
          _buildMonthlyCollectionTrend(),
          const SizedBox(height: 24),
          _buildPaymentModeTrend(),
          const SizedBox(height: 24),
          _buildStudentGrowthTrend(),
        ],
      ),
    );
  }

  Widget _buildFilterInfo() {
    if (_selectedSchool == null && _selectedStandard == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 20),
            const SizedBox(width: 8),
            Text(
              'Filtered by: ${_selectedSchool ?? 'All Schools'} - ${_selectedStandard ?? 'All Classes'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSchool = null;
                  _selectedStandard = null;
                });
                _loadAnalytics();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fee Collection Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Fees',
                '₹${_analytics!['totalFees'].toStringAsFixed(2)}',
                Colors.blue,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Collected',
                '₹${_analytics!['totalCollected'].toStringAsFixed(2)}',
                Colors.green,
                Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Pending',
                '₹${_analytics!['totalPending'].toStringAsFixed(2)}',
                Colors.orange,
                Icons.pending_actions,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Collection %',
                '${_analytics!['collectionPercentage'].toStringAsFixed(1)}%',
                Colors.purple,
                Icons.percent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fee Collection Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: _analytics!['totalCollected'].toDouble(),
                      title:
                          'Collected\n${_analytics!['collectionPercentage'].toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: _analytics!['totalPending'].toDouble(),
                      title:
                          'Pending\n${(100 - _analytics!['collectionPercentage']).toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    final students =
        Provider.of<StudentProvider>(context, listen: false).students;
    final sortedStudents = List<Student>.from(students)
      ..sort((a, b) => b.feesSubmitted.compareTo(a.feesSubmitted));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedStudents.take(5).length,
              itemBuilder: (context, index) {
                final student = sortedStudents[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: Text('${student.standard} - ${student.schoolName}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${student.feesSubmitted.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${student.feesPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: student.feesPercentage == 100
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPayments() {
    final students =
        Provider.of<StudentProvider>(context, listen: false).students;
    final pendingStudents = students.where((s) => s.remainingFees > 0).toList()
      ..sort((a, b) => b.remainingFees.compareTo(a.remainingFees));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Payments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingStudents.take(5).length,
              itemBuilder: (context, index) {
                final student = pendingStudents[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: Text('${student.standard} - ${student.schoolName}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${student.remainingFees.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '${student.feesPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardBarChart() {
    if (_standardCounts.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxCount = _standardCounts
        .map((e) => e.value)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Distribution by Standard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxCount + 1).toDouble(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _standardCounts.length)
                            return const SizedBox.shrink();
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(_standardCounts[idx].key,
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < _standardCounts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _standardCounts[i].value.toDouble(),
                            color: Colors.blueAccent,
                            width: 32,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolBarChart() {
    if (_schoolCounts.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxCount =
        _schoolCounts.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Distribution by School',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: (_schoolCounts.length * 36.0).clamp(200, 500),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: (maxCount + 1).toDouble(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _schoolCounts.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(_schoolCounts[idx].key,
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 100,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _schoolCounts.length)
                            return const SizedBox.shrink();
                          return Text(_schoolCounts[idx].value.toString(),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < _schoolCounts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _schoolCounts[i].value.toDouble(),
                            color: Colors.deepPurpleAccent,
                            width: 32,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentModeDistribution() {
    final students =
        Provider.of<StudentProvider>(context, listen: false).students;
    final paymentModes = <String, int>{};
    for (var student in students) {
      // Get payment mode from the most recent payment
      final mode = 'Cash'; // Default to Cash if no payment mode is available
      paymentModes[mode] = (paymentModes[mode] ?? 0) + 1;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Mode Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: paymentModes.entries.map((entry) {
                    return PieChartSectionData(
                      color: _getRandomColor(entry.key),
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCollectionTrend() {
    final students =
        Provider.of<StudentProvider>(context, listen: false).students;
    final monthlyData = <DateTime, double>{};
    final now = DateTime.now();

    // Initialize last 6 months
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      monthlyData[date] = 0;
    }

    // Aggregate payments by month
    for (var student in students) {
      // Add logic to aggregate payments by month
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Collection Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date =
                              monthlyData.keys.elementAt(value.toInt());
                          return Text(
                            DateFormat('MMM').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData.entries.map((entry) {
                        return FlSpot(
                          monthlyData.keys
                              .toList()
                              .indexOf(entry.key)
                              .toDouble(),
                          entry.value,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentModeTrend() {
    // Similar to monthly collection trend but for payment modes
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Mode Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Add payment mode trend chart
          ],
        ),
      ),
    );
  }

  Widget _buildStudentGrowthTrend() {
    // Show student growth over time
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Growth Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Add student growth trend chart
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final schools = studentProvider.students
        .map((s) => s.schoolName)
        .toSet()
        .toList()
      ..sort();
    final standards = studentProvider.students
        .map((s) => s.standard)
        .toSet()
        .toList()
      ..sort();

    final selectedSchool = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select School'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: schools.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Schools'),
                  onTap: () => Navigator.pop(context, null),
                );
              }
              return ListTile(
                title: Text(schools[index - 1]),
                onTap: () => Navigator.pop(context, schools[index - 1]),
              );
            },
          ),
        ),
      ),
    );

    if (selectedSchool == null) return;

    final selectedStandard = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Class'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: standards.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Classes'),
                  onTap: () => Navigator.pop(context, null),
                );
              }
              return ListTile(
                title: Text(standards[index - 1]),
                onTap: () => Navigator.pop(context, standards[index - 1]),
              );
            },
          ),
        ),
      ),
    );

    if (selectedStandard == null) return;

    setState(() {
      _selectedSchool = selectedSchool;
      _selectedStandard = selectedStandard;
    });
    _loadAnalytics();
  }

  Future<void> _downloadAnalyticsReport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Analytics Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            'Generated on: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          if (_selectedSchool != null || _selectedStandard != null)
            pw.Text(
              'Filtered by: ${_selectedSchool ?? 'All Schools'} - ${_selectedStandard ?? 'All Classes'}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Fee Collection Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Fees', '₹${_analytics!['totalFees'].toStringAsFixed(2)}'],
              [
                'Collected',
                '₹${_analytics!['totalCollected'].toStringAsFixed(2)}'
              ],
              ['Pending', '₹${_analytics!['totalPending'].toStringAsFixed(2)}'],
              [
                'Collection %',
                '${_analytics!['collectionPercentage'].toStringAsFixed(1)}%'
              ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Student Distribution',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Table.fromTextArray(
            headers: ['Standard', 'Count'],
            data: _standardCounts
                .map((e) => [e.key, e.value.toString()])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['School', 'Count'],
            data:
                _schoolCounts.map((e) => [e.key, e.value.toString()]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Color _getRandomColor(String seed) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[seed.hashCode % colors.length];
  }
}
