import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';

class CallHistoryScreen extends StatefulWidget {
  final SupabaseService supabaseService;

  const CallHistoryScreen({
    Key? key,
    required this.supabaseService,
  }) : super(key: key);

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _recentCalls = [];
  Map<String, dynamic> _filterStats = {};
  Map<String, dynamic> _callQualityStats = {};
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final calls = await widget.supabaseService.getRecentCallHistory(
        since: _startDate,
      );
      final stats = await widget.supabaseService.getUserFilterStats(
        since: _startDate,
      );
      final quality = await widget.supabaseService.getDetailedCallQualityStats(
        _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      );
      
      setState(() {
        _recentCalls = calls;
        _filterStats = stats;
        _callQualityStats = quality;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/call_history_${DateTime.now().millisecondsSinceEpoch}.csv');
      
      final csvData = [
        ['Call ID', 'Date', 'Duration', 'Participants', 'Filters Used', 'Call Quality'],
        ..._recentCalls.map((call) => [
          call['id'],
          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(call['started_at'])),
          _formatDuration(call['duration_sec'] ?? 0),
          '${call['user_a']['display_name']} → ${call['user_b']['display_name']}',
          (call['filters'] as List).map((f) => f['filter_name']).join(', '),
          call['peer_used_turn'] ? 'TURN' : 'Direct',
        ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredCalls() {
    return _recentCalls.where((call) {
      final date = DateTime.parse(call['started_at']);
      if (_startDate != null && date.isBefore(_startDate!)) return false;
      if (_endDate != null && date.isAfter(_endDate!)) return false;
      
      final searchLower = _searchQuery.toLowerCase();
      final userA = call['user_a']['display_name'].toString().toLowerCase();
      final userB = call['user_b']['display_name'].toString().toLowerCase();
      if (_searchQuery.isNotEmpty && !userA.contains(searchLower) && !userB.contains(searchLower)) {
        return false;
      }

      if (_selectedCategories.isNotEmpty) {
        final filters = (call['filters'] as List).map((f) => f['filter_name'].toString()).toList();
        if (!_selectedCategories.any((category) => filters.contains(category))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recent Calls'),
            Tab(text: 'Filter Stats'),
            Tab(text: 'Call Quality'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search calls...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecentCallsTab(),
                      _buildFilterStatsTab(),
                      _buildCallQualityTab(),
                      _buildAnalyticsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRecentCallsTab() {
    final filteredCalls = _getFilteredCalls();
    
    if (filteredCalls.isEmpty) {
      return const Center(child: Text('No recent calls'));
    }

    return ListView.builder(
      itemCount: filteredCalls.length,
      itemBuilder: (context, index) {
        final call = filteredCalls[index];
        final userA = call['user_a'];
        final userB = call['user_b'];
        final filters = call['filters'] as List;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userA['avatar_url'] ?? ''),
              child: userA['avatar_url'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text('${userA['display_name']} → ${userB['display_name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeago.format(DateTime.parse(call['started_at']))),
                if (call['duration_sec'] != null)
                  Text('Duration: ${_formatDuration(call['duration_sec'])}'),
                if (filters.isNotEmpty)
                  Text('Filters used: ${filters.length}'),
              ],
            ),
            trailing: Icon(
              call['peer_used_turn'] ? Icons.sync : Icons.signal_cellular_alt,
              color: call['peer_used_turn'] ? Colors.orange : Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterStatsTab() {
    final filters = _filterStats['filters'] as List? ?? [];
    
    if (filters.isEmpty) {
      return const Center(child: Text('No filter usage data'));
    }

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PieChart(
              PieChartData(
                sections: filters.map((filter) {
                  final count = filter['count'] as int;
                  final total = filters.fold<int>(0, (sum, f) => sum + (f['count'] as int));
                  final percentage = count / total;
                  
                  return PieChartSectionData(
                    value: percentage,
                    title: '${(percentage * 100).toStringAsFixed(1)}%',
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView.builder(
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.filter_alt),
                  title: Text(filter['filter_name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Used ${filter['count']} times'),
                      if (filter['sum'] != null)
                        Text('Total duration: ${_formatDuration(filter['sum'])}'),
                      if (filter['count_case'] != null)
                        Text('Effects triggered: ${filter['count_case']}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCallQualityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(2.6, 2),
                      const FlSpot(4.9, 5),
                      const FlSpot(6.8, 3.1),
                      const FlSpot(8, 4),
                      const FlSpot(9.5, 3),
                      const FlSpot(11, 4),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Average Latency',
            '${_callQualityStats['avg']?.toStringAsFixed(1) ?? 0} ms',
            Icons.speed,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Packet Loss',
            '${_callQualityStats['avg_1']?.toStringAsFixed(2) ?? 0}%',
            Icons.wifi_off,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Frame Drop Rate',
            '${_callQualityStats['avg_2']?.toStringAsFixed(2) ?? 0}%',
            Icons.videocam_off,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Calls',
            '${_callQualityStats['count'] ?? 0}',
            Icons.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 8,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 12,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 6,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Call Duration',
            _formatDuration(_recentCalls.fold<int>(0, (sum, call) => sum + (call['duration_sec'] ?? 0))),
            Icons.timer,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Average Call Duration',
            _formatDuration(_recentCalls.isEmpty ? 0 : _recentCalls.fold<int>(0, (sum, call) => sum + (call['duration_sec'] ?? 0)) ~/ _recentCalls.length),
            Icons.timer_outlined,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Filters Used',
            '${_recentCalls.fold<int>(0, (sum, call) => sum + (call['filters'] as List).length)}',
            Icons.filter_alt,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 