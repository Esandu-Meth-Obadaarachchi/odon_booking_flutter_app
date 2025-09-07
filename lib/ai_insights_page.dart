import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/ai_insights_service.dart';

class AiInsightsPage extends StatefulWidget {
  final DateTime selectedMonth;
  final double totalRevenue;
  final double totalExpenses;
  final double totalSalaries;
  final double totalProfit;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> salaries;

  const AiInsightsPage({
    Key? key,
    required this.selectedMonth,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalSalaries,
    required this.totalProfit,
    required this.bookings,
    required this.expenses,
    required this.salaries,
  }) : super(key: key);

  @override
  _AiInsightsPageState createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage>
    with TickerProviderStateMixin {
  final AiInsightsService _aiService = AiInsightsService();
  Map<String, dynamic>? _insights;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _generateInsights();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateInsights() async {
    try {
      final insights = await _aiService.generateBusinessInsights(
        selectedMonth: widget.selectedMonth,
        totalRevenue: widget.totalRevenue,
        totalExpenses: widget.totalExpenses,
        totalSalaries: widget.totalSalaries,
        totalProfit: widget.totalProfit,
        bookings: widget.bookings ?? [],
        expenses: widget.expenses ?? [],
        salaries: widget.salaries ?? [],
      );

      setState(() {
        _insights = insights;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "🤖 AI Business Insights",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _generateInsights();
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
          ? _buildErrorView()
          : _buildInsightsView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                ),
              ),
              Icon(Icons.psychology, size: 40, color: Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "🧠 AI is analyzing your business data...",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Discovering insights that would take hours to find manually",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            "Oops! Something went wrong",
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: GoogleFonts.montserrat(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _generateInsights();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthOverview(),
            const SizedBox(height: 20),
            _buildKeyInsights(),
            const SizedBox(height: 20),
            _buildCriticalIssues(),
            const SizedBox(height: 20),
            _buildRevenueAnalysis(),
            const SizedBox(height: 20),
            _buildExpenseAnalysis(),
            const SizedBox(height: 20),
            _buildOperationalInsights(),
            const SizedBox(height: 20),
            _buildActionableRecommendations(),
            const SizedBox(height: 20),
            _buildPredictiveInsights(),
            const SizedBox(height: 20),
            _buildBenchmarkComparison(),

            const SizedBox(height: 20),
            _buildMealServiceAnalysis(),
            const SizedBox(height: 20),
            _buildRoomSalesAnalysis(),
            const SizedBox(height: 20),
            _buildExpenseOutliers(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthOverview() {
    final health = _insights!['overallHealth'] ?? 'Fair';
    final score = _insights!['profitabilityScore'] ?? 70;

    Color healthColor;
    IconData healthIcon;

    switch (health.toLowerCase()) {
      case 'excellent':
        healthColor = Colors.green;
        healthIcon = Icons.trending_up;
        break;
      case 'good':
        healthColor = Colors.blue;
        healthIcon = Icons.thumb_up;
        break;
      case 'fair':
        healthColor = Colors.orange;
        healthIcon = Icons.warning;
        break;
      default:
        healthColor = Colors.red;
        healthIcon = Icons.trending_down;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [healthColor.withOpacity(0.8), healthColor.withOpacity(0.6)],
        ),
        boxShadow: [
          BoxShadow(
            color: healthColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Business Health",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    health,
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(healthIcon, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    "$score/100",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInsights() {
    final insights = _insights!['keyInsights'] as List? ?? [];

    return _buildSection(
      title: "💡 Key Insights",
      child: Column(
        children: insights.map<Widget>((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),

            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.toString(),
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCriticalIssues() {
    final issues = _insights!['criticalIssues'] as List? ?? [];

    if (issues.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: "🚨 Critical Issues",
      child: Column(
        children: issues.map<Widget>((issue) {
          final urgency = issue['urgency'] ?? 'Medium';
          Color urgencyColor = urgency == 'High'
              ? Colors.red
              : urgency == 'Medium'
              ? Colors.orange
              : Colors.yellow[700]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),

            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: urgencyColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue['issue'].toString(),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgencyColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        urgency,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  issue['impact'].toString(),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueAnalysis() {
    final analysis = _insights!['revenueAnalysis'] as Map<String, dynamic>? ??
        {};

    return _buildSection(
      title: "💰 Revenue Analysis",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisCard(
            title: "Summary",
            content: analysis['summary']?.toString() ?? '',
            color: Colors.green,
            icon: Icons.assessment,
          ),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Strengths",
            analysis['strengths'] as List? ?? [],
            Colors.green,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Concerns",
            analysis['concerns'] as List? ?? [],
            Colors.orange,
            Icons.warning,
          ),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Opportunities",
            analysis['opportunities'] as List? ?? [],
            Colors.blue,
            Icons.lightbulb,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseAnalysis() {
    final analysis = _insights!['expenseAnalysis'] as Map<String, dynamic>? ??
        {};

    return _buildSection(
      title: "📊 Expense Analysis",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisCard(
            title: "Summary",
            content: analysis['summary']?.toString() ?? '',
            color: Colors.red,
            icon: Icons.receipt_long,
          ),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Highest Categories",
            analysis['highestCategories'] as List? ?? [],
            Colors.red,
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Inefficiencies",
            analysis['inefficiencies'] as List? ?? [],
            Colors.orange,
            Icons.error,
          ),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Optimization Tips",
            analysis['optimizationTips'] as List? ?? [],
            Colors.green,
            Icons.tips_and_updates,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalInsights() {
    final insights = _insights!['operationalInsights'] as List? ?? [];

    return _buildSection(
      title: "⚙️ Operational Insights",
      child: Column(
        children: insights.map<Widget>((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['metric'].toString(),
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Status: ${insight['status']}",
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Recommendation: ${insight['recommendation']}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionableRecommendations() {
    final recommendations = _insights!['actionableRecommendations'] as List? ??
        [];

    return _buildSection(
      title: "🎯 Actionable Recommendations",
      child: Column(
        children: recommendations.map<Widget>((rec) {
          final priority = rec['priority'] ?? 'Medium';
          Color priorityColor = priority == 'High'
              ? Colors.red
              : priority == 'Medium'
              ? Colors.orange
              : Colors.green;

          IconData categoryIcon;
          switch (rec['category']?.toLowerCase()) {
            case 'revenue':
              categoryIcon = Icons.monetization_on;
              break;
            case 'expenses':
              categoryIcon = Icons.receipt_long;
              break;
            case 'operations':
              categoryIcon = Icons.settings;
              break;
            case 'marketing':
              categoryIcon = Icons.campaign;
              break;
            default:
              categoryIcon = Icons.star;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(categoryIcon, color: priorityColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec['action'].toString(),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Expected Impact: ${rec['expectedImpact']}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Timeframe: ${rec['timeframe']}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPredictiveInsights() {
    final insights = _insights!['predictiveInsights'] as List? ?? [];

    return _buildSection(
      title: "🔮 Predictive Insights",
      child: Column(
        children: insights.map<Widget>((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),

            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.toString(),
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBenchmarkComparison() {
    final benchmark = _insights!['benchmarkComparison'] as Map<String,
        dynamic>? ?? {};

    return _buildSection(
      title: "📈 Industry Benchmark Comparison",
      child: Column(
        children: [
          _buildBenchmarkCard(
              "Profit Margin", benchmark['profitMargin']?.toString() ?? 'N/A'),
          const SizedBox(height: 12),
          _buildBenchmarkCard("Occupancy Rate",
              benchmark['occupancyRate']?.toString() ?? 'N/A'),
          const SizedBox(height: 12),
          _buildBenchmarkCard(
              "Revenue Per Room", benchmark['revpar']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required String content,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisLists(String title, List items, Color color,
      IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map<Widget>((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBenchmarkCard(String metric, String comparison) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart, color: Colors.teal[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.teal[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comparison,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealServiceAnalysis() {
    final analysis = _insights!['mealServiceAnalysis'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      title: "🍽️ Meal Service Analysis",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisCard(
            title: "Summary",
            content: analysis['summary']?.toString() ?? '',
            color: Colors.amber,
            icon: Icons.restaurant,
          ),
          const SizedBox(height: 12),
          _buildMealAnalysisCard("Breakfast", analysis['breakfastAnalysis']?.toString() ?? ''),
          const SizedBox(height: 8),
          _buildMealAnalysisCard("Lunch", analysis['lunchAnalysis']?.toString() ?? ''),
          const SizedBox(height: 8),
          _buildMealAnalysisCard("Dinner", analysis['dinnerAnalysis']?.toString() ?? ''),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Cost Optimization",
            analysis['costOptimization'] as List? ?? [],
            Colors.green,
            Icons.savings,
          ),
          if (analysis['staffingInsights']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildAnalysisCard(
              title: "Staffing Insights",
              content: analysis['staffingInsights']?.toString() ?? '',
              color: Colors.blue,
              icon: Icons.people,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealAnalysisCard(String mealType, String analysis) {
    IconData icon;
    Color color;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        icon = Icons.free_breakfast;
        color = Colors.orange;
        break;
      case 'lunch':
        icon = Icons.lunch_dining;
        color = Colors.green;
        break;
      case 'dinner':
        icon = Icons.dinner_dining;
        color = Colors.red;
        break;
      default:
        icon = Icons.restaurant;
        color = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealType,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  analysis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSalesAnalysis() {
    final analysis = _insights!['roomSalesAnalysis'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      title: "🏨 Room Sales Analysis",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisCard(
            title: "Summary",
            content: analysis['summary']?.toString() ?? '',
            color: Colors.purple,
            icon: Icons.hotel,
          ),
          const SizedBox(height: 12),
          _buildRoomTypeCard("Double Room", analysis['doubleRoomPerformance']?.toString() ?? '', Icons.bed),
          const SizedBox(height: 8),
          _buildRoomTypeCard("Triple Room", analysis['tripleRoomPerformance']?.toString() ?? '', Icons.king_bed),
          const SizedBox(height: 8),
          _buildRoomTypeCard("Family Room", analysis['familyRoomPerformance']?.toString() ?? '', Icons.family_restroom),
          const SizedBox(height: 8),
          _buildRoomTypeCard("Family Plus", analysis['familyPlusPerformance']?.toString() ?? '', Icons.groups),
          const SizedBox(height: 12),
          _buildAnalysisLists(
            "Recommendations",
            analysis['recommendations'] as List? ?? [],
            Colors.blue,
            Icons.lightbulb,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard(String roomType, String analysis, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomType,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                    fontSize: 14,
                  ),
                ),
                Text(
                  analysis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseOutliers() {
    final outliers = _insights!['expenseOutliers'] as List? ?? [];

    if (outliers.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: "💸 High-Impact Expenses",
      child: Column(
        children: outliers.map<Widget>((outlier) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        outlier['vendor'].toString(),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${outlier['percentageOfRevenue'] ?? outlier['percentage']}%",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Amount: LKR ${outlier['amount'].toString()}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Impact: ${outlier['impact']}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Recommendation: ${outlier['recommendation']}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}