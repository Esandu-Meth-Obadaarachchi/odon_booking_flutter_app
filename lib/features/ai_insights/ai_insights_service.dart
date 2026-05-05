import 'dart:convert';

class AiInsightsService {
  Future<Map<String, dynamic>> generateBusinessInsights({
    required DateTime selectedMonth,
    required double totalRevenue,
    required double totalExpenses,
    required double totalSalaries,
    required double totalProfit,
    required List<Map<String, dynamic>> bookings,
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> salaries,
  }) async {
    try {
      // --- Room type counts (case-insensitive, matches your list) ---
      final roomTypeSales = {
        'double': 0,
        'triple': 0,
        'family': 0,
        'family_plus': 0,
      };

      // --- Package counts (case-insensitive; maps your list: Full Board, Half Board, Room Only, BnB) ---
      final packageCounts = {
        'full_board': 0,
        'half_board': 0,
        'room_only': 0,
        'bnb': 0,
        'other': 0,
      };

      // guest estimation per room type
      final guestsPerType = {
        'double': 2,
        'triple': 3,
        'family': 4,
        'family_plus': 5,
      };

      int estimatedGuests = 0;
      int totalBookings = bookings.length;

      for (var booking in bookings) {
        final roomTypeRaw = (booking['roomType'] ?? '').toString().trim();
        final packageRaw = (booking['package'] ?? '').toString().trim();

        final roomType = roomTypeRaw.toLowerCase();
        final packageType = packageRaw.toLowerCase();

        if (roomType.contains('double')) {
          roomTypeSales['double'] = roomTypeSales['double']! + 1;
          estimatedGuests += guestsPerType['double']!;
        } else if (roomType.contains('triple')) {
          roomTypeSales['triple'] = roomTypeSales['triple']! + 1;
          estimatedGuests += guestsPerType['triple']!;
        } else if (roomType.contains('family plus') || roomType.contains('family_plus')) {
          roomTypeSales['family_plus'] = roomTypeSales['family_plus']! + 1;
          estimatedGuests += guestsPerType['family_plus']!;
        } else if (roomType.contains('family')) {
          // keep 'family plus' checked first — this else handles plain 'family'
          roomTypeSales['family'] = roomTypeSales['family']! + 1;
          estimatedGuests += guestsPerType['family']!;
        } else {
          // unknown room types are ignored for the standard counts (you may extend later)
        }

        // packages
        if (packageType.contains('full board') || packageType.contains('fb')) {
          packageCounts['full_board'] = packageCounts['full_board']! + 1;
        } else if (packageType.contains('half board') || packageType.contains('hb')) {
          packageCounts['half_board'] = packageCounts['half_board']! + 1;
        } else if (packageType.contains('room only') || packageType.contains('roomonly')) {
          packageCounts['room_only'] = packageCounts['room_only']! + 1;
        } else if (packageType.contains('bnb') || packageType.contains('bed and breakfast') || packageType.contains('bed & breakfast')) {
          packageCounts['bnb'] = packageCounts['bnb']! + 1;
        } else {
          packageCounts['other'] = packageCounts['other']! + 1;
        }
      }

      // Totals
      final totalRoomsSold = roomTypeSales.values.reduce((a, b) => a + b);
      final totalPackageBookings = packageCounts.values.reduce((a, b) => a + b);

      // Build meal service analysis strings (simple, data-driven)
      final breakfastServedEstimate =
          (packageCounts['bnb'] ?? 0) * 1 * 1 + // assume BnB -> breakfast for primary guest (we keep conservative)
              (packageCounts['half_board'] ?? 0) * 1 +
              (packageCounts['full_board'] ?? 0) * 1;
      // note: above is a conservative count — you can refine per-guest if you prefer

      final mealServiceSummary = {
        'summary':
        'Calculated meal package counts from bookings for ${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, "0")}. Estimated guests: $estimatedGuests.',
        'breakfastAnalysis':
        'Packages serving breakfast: BnB=${packageCounts['bnb']}, Half Board=${packageCounts['half_board']}, Full Board=${packageCounts['full_board']}. Estimated breakfasts (conservative): $breakfastServedEstimate.',
        'lunchAnalysis':
        'Packages serving lunch: Full Board=${packageCounts['full_board']}. Estimated lunches (conservative): ${packageCounts['full_board']}.',
        'dinnerAnalysis':
        'Packages serving dinner: Half Board=${packageCounts['half_board']}, Full Board=${packageCounts['full_board']}. Estimated dinners (conservative): ${ (packageCounts['half_board'] ?? 0) + (packageCounts['full_board'] ?? 0) }.',
        'costOptimization': <String>[],
        'staffingInsights': 'Chef and overtime not analyzed in this lightweight mode.'
      };

      // Room sales analysis fields as strings (UI expects these specific keys)
      // Room sales analysis fields as strings (UI expects these specific keys)
      final roomSalesAnalysis = {
        'summary':
        'Room sales summary for ${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, "0")}: total rooms sold = $totalRoomsSold across ${totalBookings} bookings.',

        'doubleRoomPerformance':
        '${roomTypeSales['double']} bookings sold as Double rooms (estimated guests ${(roomTypeSales['double'] ?? 0) * (guestsPerType['double'] ?? 0)}).',

        'tripleRoomPerformance':
        '${roomTypeSales['triple']} bookings sold as Triple rooms (estimated guests ${(roomTypeSales['triple'] ?? 0) * (guestsPerType['triple'] ?? 0)}).',

        'familyRoomPerformance':
        '${roomTypeSales['family']} bookings sold as Family rooms (estimated guests ${(roomTypeSales['family'] ?? 0) * (guestsPerType['family'] ?? 0)}).',

        'familyPlusPerformance':
        '${roomTypeSales['family_plus']} bookings sold as Family Plus rooms (estimated guests ${(roomTypeSales['family_plus'] ?? 0) * (guestsPerType['family_plus'] ?? 0)}).',

        'recommendations': <String>[
          'Consider upsell promotions for underperforming room types.',
          'If Family/Family Plus bookings are low, test family package promotions.'
        ],
      };
      // Minimal top-level fields so UI health/score sections show something
      final overallHealth = _deriveHealthFromProfitability(totalRevenue, totalProfit);

      final insights = {
        // Basic / required fields used by the UI
        'overallHealth': overallHealth['label'],
        'profitabilityScore': overallHealth['score'], // 0-100
        'keyInsights': <String>[
          'Room & package counts calculated locally (no AI).',
          'Estimated guests calculated from room types.',
        ],
        'criticalIssues': <Map<String, dynamic>>[],
        'revenueAnalysis': {
          'summary': 'Revenue summary not generated in offline mode.',
          'strengths': <String>[],
          'concerns': <String>[],
          'opportunities': <String>[],
        },
        'expenseAnalysis': {
          'summary': 'Expense summary not generated in offline mode.',
          'highestCategories': <String>[],
          'inefficiencies': <String>[],
          'optimizationTips': <String>[],
        },
        'operationalInsights': <Map<String, dynamic>>[],
        'mealServiceAnalysis': mealServiceSummary,
        'roomSalesAnalysis': roomSalesAnalysis,
        'expenseOutliers': <Map<String, dynamic>>[],
        'actionableRecommendations': <Map<String, dynamic>>[],
        'predictiveInsights': <String>[
          'No predictive model run in offline mode.',
          'Monitor month-to-month booking mix.'
        ],
        'benchmarkComparison': {
          'profitMargin': 'N/A',
          'occupancyRate': 'N/A',
          'revpar': 'N/A',
        },
        // Keep the original small summaries too (for backwards compatibility if desired)
        'roomSalesSummary': {
          'doubleRooms': roomTypeSales['double'],
          'tripleRooms': roomTypeSales['triple'],
          'familyRooms': roomTypeSales['family'],
          'familyPlusRooms': roomTypeSales['family_plus'],
          'totalRoomsSold': totalRoomsSold,
        },
        'mealPackageSummary': {
          'fullBoard': packageCounts['full_board'],
          'halfBoard': packageCounts['half_board'],
          'roomOnly': packageCounts['room_only'],
          'bnb': packageCounts['bnb'],
          'other': packageCounts['other'],
          'totalBookings': totalPackageBookings,
        },
      };

      return insights;
    } catch (e) {
      // Return a safe fallback that matches UI keys (so UI won't crash)
      return {
        'overallHealth': 'Fair',
        'profitabilityScore': 60,
        'keyInsights': ['Failed to compute details: ${e.toString()}'],
        'criticalIssues': [],
        'revenueAnalysis': {'summary': '', 'strengths': [], 'concerns': [], 'opportunities': []},
        'expenseAnalysis': {'summary': '', 'highestCategories': [], 'inefficiencies': [], 'optimizationTips': []},
        'operationalInsights': [],
        'mealServiceAnalysis': {
          'summary': 'Unavailable due to error.',
          'breakfastAnalysis': '',
          'lunchAnalysis': '',
          'dinnerAnalysis': '',
          'costOptimization': [],
          'staffingInsights': ''
        },
        'roomSalesAnalysis': {
          'summary': 'Unavailable due to error.',
          'doubleRoomPerformance': '',
          'tripleRoomPerformance': '',
          'familyRoomPerformance': '',
          'familyPlusPerformance': '',
          'recommendations': []
        },
        'expenseOutliers': [],
        'actionableRecommendations': [],
        'predictiveInsights': [],
        'benchmarkComparison': {'profitMargin': 'N/A', 'occupancyRate': 'N/A', 'revpar': 'N/A'},
        'roomSalesSummary': {'doubleRooms': 0, 'tripleRooms': 0, 'familyRooms': 0, 'familyPlusRooms': 0, 'totalRoomsSold': 0},
        'mealPackageSummary': {'fullBoard': 0, 'halfBoard': 0, 'roomOnly': 0, 'bnb': 0, 'other': 0, 'totalBookings': 0},
      };
    }
  }

  // small heuristic to produce a health label & score
  static Map<String, dynamic> _deriveHealthFromProfitability(double revenue, double profit) {
    if (revenue <= 0) {
      return {'label': 'Poor', 'score': 40};
    }
    final margin = (profit / revenue) * 100;
    if (margin >= 20) return {'label': 'Excellent', 'score': 90};
    if (margin >= 10) return {'label': 'Good', 'score': 75};
    if (margin >= 3) return {'label': 'Fair', 'score': 60};
    return {'label': 'Poor', 'score': 45};
  }
}


//v1
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class AiInsightsService {
//   static const String _geminiApiKey = 'AIzaSyBV9XpOU9ndyZFLuGfwMr6b3kx3Cst2NSo';
//   static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
//
//   Future<Map<String, dynamic>> generateBusinessInsights({
//     required DateTime selectedMonth,
//     required double totalRevenue,
//     required double totalExpenses,
//     required double totalSalaries,
//     required double totalProfit,
//     required List<Map<String, dynamic>> bookings,
//     required List<Map<String, dynamic>> expenses,
//     required List<Map<String, dynamic>> salaries,
//   }) async {
//
//     try {
//       print('🤖 Starting AI analysis...');
//       print('Data: Revenue=$totalRevenue, Expenses=$totalExpenses, Salaries=$totalSalaries');
//       print('Lists - Bookings: ${bookings?.length ?? 0}, Expenses: ${expenses?.length ?? 0}, Salaries: ${salaries?.length ?? 0}');
//
//       final prompt = _buildComprehensivePrompt(
//         selectedMonth: selectedMonth,
//         totalRevenue: totalRevenue,
//         totalExpenses: totalExpenses,
//         totalSalaries: totalSalaries,
//         totalProfit: totalProfit,
//         bookings: bookings,
//         expenses: expenses,
//         salaries: salaries,
//       );
//
//       print('🤖 Sending request to Gemini API...');
//
//       final response = await http.post(
//         Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode({
//           'contents': [
//             {
//               'parts': [
//                 {'text': prompt}
//               ]
//             }
//           ],
//           'generationConfig': {
//             'temperature': 0.7,
//             'topK': 40,
//             'topP': 0.95,
//             'maxOutputTokens': 2048,
//           }
//         }),
//       );
//
//       print('🤖 API Response Status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         print('🤖 Full API Response: $data'); // Debug: See full response structure
//
//         // Check if response has the expected structure
//         if (data != null &&
//             data['candidates'] != null &&
//             data['candidates'] is List &&
//             data['candidates'].isNotEmpty &&
//             data['candidates'][0] != null &&
//             data['candidates'][0]['content'] != null &&
//             data['candidates'][0]['content']['parts'] != null &&
//             data['candidates'][0]['content']['parts'] is List &&
//             data['candidates'][0]['content']['parts'].isNotEmpty) {
//
//           final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
//           print('🤖 Generated text preview: ${generatedText.substring(0, generatedText.length > 200 ? 200 : generatedText.length)}...');
//           return _parseInsightsResponse(generatedText);
//
//         } else if (data != null &&
//             data['candidates'] != null &&
//             data['candidates'] is List &&
//             data['candidates'].isNotEmpty &&
//             data['candidates'][0] != null &&
//             data['candidates'][0]['parts'] != null) {
//
//           // Alternative structure (older API format)
//           final generatedText = data['candidates'][0]['parts'][0]['text'];
//           print('🤖 Generated text preview: ${generatedText.substring(0, generatedText.length > 200 ? 200 : generatedText.length)}...');
//           return _parseInsightsResponse(generatedText);
//
//         } else {
//           print('🤖 Unexpected response structure');
//           print('🤖 Available keys: ${data?.keys?.toList()}');
//           if (data?['candidates'] != null) {
//             print('🤖 Candidates structure: ${data['candidates']}');
//           }
//           throw Exception('Unexpected API response structure');
//         }
//       } else {
//         print('🤖 API Error: ${response.body}');
//         throw Exception('Failed to generate insights: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       print('🤖 Error in generateBusinessInsights: $e');
//       throw Exception('Error generating insights: $e');
//     }
//   }
// }
//
// String _buildComprehensivePrompt({
//   required DateTime selectedMonth,
//   required double totalRevenue,
//   required double totalExpenses,
//   required double totalSalaries,
//   required double totalProfit,
//   required List<Map<String, dynamic>> bookings,
//   required List<Map<String, dynamic>> expenses,
//   required List<Map<String, dynamic>> salaries,
// }) {
//   // Calculate detailed metrics
//   final profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
//   final avgBookingValue = bookings.isNotEmpty ? totalRevenue / bookings.length : 0;
//   final occupancyDays = bookings.length;
//
//   // Expense categorization
//   Map<String, double> expensesByCategory = {};
//   for (var expense in expenses) {
//     String category = expense['category'] ?? 'Other';
//     double amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
//     expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount;
//   }
//
//   // Room type analysis with guest count
//   Map<String, int> roomTypeBookings = {};
//   Map<String, double> roomTypeRevenue = {};
//   Map<String, int> roomTypeSales = {'double': 0, 'triple': 0, 'family': 0, 'family_plus': 0};
//
//   for (var booking in bookings) {
//     String roomType = booking['roomType'] ?? 'Unknown';
//     double total = double.tryParse(booking['total'].toString()) ?? 0.0;
//
//     roomTypeBookings[roomType] = (roomTypeBookings[roomType] ?? 0) + 1;
//     roomTypeRevenue[roomType] = (roomTypeRevenue[roomType] ?? 0) + total;
//
//     // Count room sales by type
//     String roomTypeLower = roomType.toLowerCase();
//     if (roomTypeLower.contains('double')) {
//       roomTypeSales['double'] = roomTypeSales['double']! + 1;
//     } else if (roomTypeLower.contains('triple')) {
//       roomTypeSales['triple'] = roomTypeSales['triple']! + 1;
//     } else if (roomTypeLower.contains('family plus')) {
//       roomTypeSales['family_plus'] = roomTypeSales['family_plus']! + 1;
//     } else if (roomTypeLower.contains('family')) {
//       roomTypeSales['family'] = roomTypeSales['family']! + 1;
//     }
//   }
//
//   // Meal analysis with corrected package types and guest calculations
//   Map<String, int> mealCounts = {'breakfast': 0, 'lunch': 0, 'dinner': 0};
//   double totalFoodExpenses = 0;
//   double chefSalary = 0;
//   double overtimePayments = 0;
//
//   for (var booking in bookings) {
//     String packageType = (booking['package'] ?? '').toLowerCase();
//     String roomType = (booking['roomType'] ?? '').toLowerCase();
//
//     // Calculate number of guests based on room type
//     int guests = 1; // default
//     if (roomType.contains('double')) {
//       guests = 2;
//     } else if (roomType.contains('triple')) {
//       guests = 3;
//     } else if (roomType.contains('family plus')) {
//       guests = 5;
//     } else if (roomType.contains('family')) {
//       guests = 4;
//     }
//
//     // Calculate meals based on package type
//     if (packageType.contains('bed and breakfast') || packageType.contains('bnb')) {
//       mealCounts['breakfast'] = mealCounts['breakfast']! + guests;
//     } else if (packageType.contains('half board') || packageType.contains('hb')) {
//       mealCounts['breakfast'] = mealCounts['breakfast']! + guests;
//       mealCounts['dinner'] = mealCounts['dinner']! + guests;
//     } else if (packageType.contains('Full Board') || packageType.contains('full board')) {
//       mealCounts['breakfast'] = mealCounts['breakfast']! + guests;
//       mealCounts['lunch'] = mealCounts['lunch']! + guests;
//       mealCounts['dinner'] = mealCounts['dinner']! + guests;
//     }
//   }
//
//   // Calculate food-related expenses
//   for (var expense in expenses) {
//     String category = (expense['category'] ?? '').toLowerCase();
//     String description = (expense['description'] ?? '').toLowerCase();
//     double amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
//
//     if (category.contains('food') || category.contains('kitchen') || category.contains('meal') ||
//         description.contains('food') || description.contains('grocery') || description.contains('kitchen')) {
//       totalFoodExpenses += amount;
//     }
//     if (description.contains('overtime') || description.contains('ot')) {
//       overtimePayments += amount;
//     }
//   }
//
//   // Calculate chef salary
//   for (var salary in salaries) {
//     String position = (salary['position'] ?? '').toLowerCase();
//     String name = (salary['employeeName'] ?? '').toLowerCase();
//     if (position.contains('chef') || name.contains('sujeeewa')) {
//       chefSalary += double.tryParse(salary['amount'].toString()) ?? 0.0;
//     }
//   }
//
//   // Identify expense outliers
//   List<Map<String, dynamic>> expenseOutliers = [];
//   double avgExpense = totalExpenses / (expenses.isNotEmpty ? expenses.length : 1);
//   double revenueThreshold = totalRevenue * 0.08; // 8% of revenue threshold
//
//   for (var expense in expenses) {
//     double amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
//     String vendor = expense['vendor'] ?? expense['description'] ?? 'Unknown';
//     String category = expense['category'] ?? 'Other';
//
//     if (amount > revenueThreshold && amount > 5000) { // Above threshold and significant amount
//       expenseOutliers.add({
//         'vendor': vendor,
//         'amount': amount,
//         'category': category,
//         'percentage': ((amount / totalRevenue) * 100).toStringAsFixed(1)
//       });
//     }
//   }
//   expenseOutliers.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
//
//   return '''
// You are an expert hospitality business analyst with 20+ years of experience in hotel revenue management, cost optimization, and profitability analysis. Analyze the following hotel business data for ${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')} and provide comprehensive, actionable insights.
//
// BUSINESS PERFORMANCE OVERVIEW:
// - Total Revenue: LKR $totalRevenue
// - Total Expenses: LKR $totalExpenses
// - Total Salaries: LKR $totalSalaries
// - Net Profit: LKR $totalProfit
// - Profit Margin: ${profitMargin.toStringAsFixed(2)}%
// - Number of Bookings: ${bookings.length}
// - Average Booking Value: LKR ${avgBookingValue.toStringAsFixed(2)}
// - Occupancy Days: $occupancyDays
//
// ROOM SALES BREAKDOWN:
// - Double Rooms Sold: ${roomTypeSales['double']} rooms
// - Triple Rooms Sold: ${roomTypeSales['triple']} rooms
// - Family Rooms Sold: ${roomTypeSales['family']} rooms
// - Family Plus Rooms Sold: ${roomTypeSales['family_plus']} rooms
//
// DETAILED EXPENSE BREAKDOWN BY CATEGORY:
// ${expensesByCategory.entries.map((e) => "- ${e.key}: LKR ${e.value.toStringAsFixed(2)}").join('\n')}
//
// ROOM TYPE PERFORMANCE:
// ${roomTypeBookings.entries.map((e) {
//     String roomType = e.key;
//     int bookings = e.value;
//     double revenue = roomTypeRevenue[roomType] ?? 0;
//     double avgValue = bookings > 0 ? revenue / bookings : 0;
//     return "- $roomType: $bookings bookings, LKR ${revenue.toStringAsFixed(2)} revenue, LKR ${avgValue.toStringAsFixed(2)} avg/booking";
//   }).join('\n')}
//
// MEAL SERVICE ANALYSIS:
// - Breakfast served to: ${mealCounts['breakfast']} guests
// - Lunch served to: ${mealCounts['lunch']} guests
// - Dinner served to: ${mealCounts['dinner']} guests
// - Total food expenses: LKR ${totalFoodExpenses.toStringAsFixed(2)}
// - Sujeeewa salary: LKR ${chefSalary.toStringAsFixed(2)}
// - Overtime payments: LKR ${overtimePayments.toStringAsFixed(2)}
// - Total meal operation cost: LKR ${(totalFoodExpenses + chefSalary + overtimePayments).toStringAsFixed(2)}
//
// SALARY STRUCTURE:
// ${salaries.map((s) => "- ${s['employeeName']}: ${s['salaryType']} - LKR ${s['amount']}").join('\n')}
//
// EXPENSE OUTLIERS (High-impact expenses):
// ${expenseOutliers.map((outlier) => "- ${outlier['vendor']}: LKR ${(outlier['amount'] as double).toStringAsFixed(2)} (${outlier['percentage']}% of revenue) - ${outlier['category']}").join('\n')}
//
// PROVIDE A COMPREHENSIVE ANALYSIS IN THIS EXACT JSON FORMAT:
//
// {
//   "overallHealth": "Excellent|Good|Fair|Poor",
//   "profitabilityScore": 85,
//   "keyInsights": [
//     "Brief insight 1 about performance",
//     "Brief insight 2 about trends",
//     "Brief insight 3 about opportunities"
//   ],
//   "criticalIssues": [
//     {
//       "issue": "Main problem identified",
//       "impact": "Financial/operational impact",
//       "urgency": "High|Medium|Low"
//     }
//   ],
//   "revenueAnalysis": {
//     "summary": "Overall revenue performance assessment",
//     "strengths": ["Revenue strength 1", "Revenue strength 2"],
//     "concerns": ["Revenue concern 1", "Revenue concern 2"],
//     "opportunities": ["Revenue opportunity 1", "Revenue opportunity 2"]
//   },
//   "expenseAnalysis": {
//     "summary": "Overall expense efficiency assessment",
//     "highestCategories": ["Category with highest spend", "Second highest"],
//     "inefficiencies": ["Expense inefficiency 1", "Expense inefficiency 2"],
//     "optimizationTips": ["Expense reduction tip 1", "Expense reduction tip 2"]
//   },
//   "operationalInsights": [
//     {
//       "metric": "Occupancy Rate",
//       "status": "Above/Below/At Industry Average",
//       "recommendation": "Specific actionable advice"
//     },
//     {
//       "metric": "Average Daily Rate",
//       "status": "Analysis of pricing strategy",
//       "recommendation": "Pricing optimization advice"
//     }
//   ],
//   "mealServiceAnalysis": {
//     "summary": "Overall meal service cost efficiency assessment with cost per meal analysis",
//     "breakfastAnalysis": "Cost per breakfast served and efficiency with total guests served",
//     "lunchAnalysis": "Cost per lunch served and efficiency with total guests served",
//     "dinnerAnalysis": "Cost per dinner served including overtime costs with total guests served",
//     "costOptimization": ["Meal cost reduction tip 1", "Meal cost reduction tip 2"],
//     "staffingInsights": "Analysis of chef salary and overtime patterns for meal service"
//   },
//   "roomSalesAnalysis": {
//     "summary": "Analysis of room type sales performance and revenue distribution",
//     "doubleRoomPerformance": "Analysis of ${roomTypeSales['double']} double room sales",
//     "tripleRoomPerformance": "Analysis of ${roomTypeSales['triple']} triple room sales",
//     "familyRoomPerformance": "Analysis of ${roomTypeSales['family']} family room sales",
//     "familyPlusPerformance": "Analysis of ${roomTypeSales['family_plus']} family plus room sales",
//     "recommendations": ["Room sales optimization tip 1", "Room sales optimization tip 2"]
//   },
//   "expenseOutliers": [
//     {
//       "vendor": "Vendor name with high expense",
//       "amount": 76000,
//       "category": "Expense category",
//       "percentageOfRevenue": "8.5%",
//       "impact": "Analysis of why this expense is concerning compared to revenue level",
//       "recommendation": "Specific action to address this expense"
//     }
//   ],
//   "actionableRecommendations": [
//     {
//       "priority": "High|Medium|Low",
//       "category": "Revenue|Expenses|Operations|Marketing",
//       "action": "Specific action to take",
//       "expectedImpact": "Estimated financial/operational improvement",
//       "timeframe": "Implementation timeline"
//     }
//   ],
//   "predictiveInsights": [
//     "Forward-looking insight about next month",
//     "Seasonal trend prediction",
//     "Market opportunity prediction"
//   ],
//   "benchmarkComparison": {
//     "profitMargin": "How your margin compares to hotel industry standards",
//     "occupancyRate": "Occupancy performance vs industry average",
//     "revpar": "Revenue per available room analysis"
//   }
// }
//
// ANALYSIS REQUIREMENTS:
// 1. Identify subtle patterns that humans might miss in 5+ minutes of analysis
// 2. Provide specific, actionable recommendations with estimated ROI
// 3. Consider seasonal hospitality trends and market dynamics
// 4. Analyze expense efficiency and suggest cost optimization strategies
// 5. Evaluate pricing strategy and revenue optimization opportunities
// 6. Assess operational efficiency and staff productivity including meal service costs
// 7. Identify potential risks and growth opportunities
// 8. Compare performance against industry benchmarks
// 9. Provide forward-looking predictions based on current data
// 10. Suggest immediate actions (1-7 days), short-term (1-3 months), and long-term strategies
// 11. Analyze meal service efficiency and cost per guest for each meal type
// 12. Evaluate room type sales performance and suggest optimization strategies
// 13. Flag high-impact expenses that consume significant revenue percentage
//
// Make insights data-driven, specific, and immediately implementable. Focus on insights that would take a human analyst hours to discover through manual analysis.
// ''';
// }
//
// Map<String, dynamic> _parseInsightsResponse(String response) {
//   try {
//     // Clean the response to extract JSON
//     String cleanResponse = response;
//
//     // Find JSON content between ```json and ``` or just the JSON object
//     if (response.contains('```json')) {
//       final startIndex = response.indexOf('```json') + 7;
//       final endIndex = response.lastIndexOf('```');
//       cleanResponse = response.substring(startIndex, endIndex).trim();
//     } else if (response.contains('{')) {
//       // Extract JSON object from the response
//       final startIndex = response.indexOf('{');
//       final endIndex = response.lastIndexOf('}') + 1;
//       cleanResponse = response.substring(startIndex, endIndex);
//     }
//
//     return jsonDecode(cleanResponse);
//   } catch (e) {
//     // Fallback response if parsing fails
//     return {
//       "overallHealth": "Fair",
//       "profitabilityScore": 70,
//       "keyInsights": [
//         "Data analysis completed successfully",
//         "Multiple optimization opportunities identified",
//         "Detailed recommendations generated"
//       ],
//       "criticalIssues": [
//         {
//           "issue": "Unable to parse detailed analysis",
//           "impact": "Limited insight delivery",
//           "urgency": "Medium"
//         }
//       ],
//       "revenueAnalysis": {
//         "summary": "Revenue data processed and analyzed",
//         "strengths": ["Consistent booking patterns"],
//         "concerns": ["Analysis parsing limitations"],
//         "opportunities": ["Enhanced data processing"]
//       },
//       "expenseAnalysis": {
//         "summary": "Expense data reviewed",
//         "highestCategories": ["Operations", "Staff"],
//         "inefficiencies": ["Data processing improvements needed"],
//         "optimizationTips": ["Implement better analytics"]
//       },
//       "operationalInsights": [
//         {
//           "metric": "Data Processing",
//           "status": "Needs Improvement",
//           "recommendation": "Enhance analysis capabilities"
//         }
//       ],
//       "actionableRecommendations": [
//         {
//           "priority": "High",
//           "category": "Operations",
//           "action": "Review and optimize data analysis system",
//           "expectedImpact": "Better insights delivery",
//           "timeframe": "1-2 weeks"
//         }
//       ],
//       "predictiveInsights": [
//         "Continued monitoring recommended",
//         "Data quality improvements needed"
//       ],
//       "benchmarkComparison": {
//         "profitMargin": "Analysis in progress",
//         "occupancyRate": "Evaluation pending",
//         "revpar": "Calculation needed"
//       }
//     };
//   }
// }