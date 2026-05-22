import 'dart:convert';
import 'package:http/http.dart' as http;

/// Generates a full, owner-facing business analysis for the profit page.
///
/// Hard numbers (revenue, occupancy, guests, meals served, cost per meal,
/// expense outliers) are computed locally in Dart so they are always accurate.
/// Gemini is then used to interpret those numbers — flag what is too high,
/// surface hidden problems, and suggest concrete profit-maximising moves.
///
/// If the network/API fails the service falls back to a fully data-driven
/// offline analysis built from the same computed metrics, so the owner still
/// sees real insight instead of empty placeholders.
class AiInsightsService {
  static const String _geminiApiKey = 'AIzaSyAV0JeIGdcTSkGU5mRvGVjFt248jRTzWpk';
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  // Room 4 is the manager's room (blocked) — 11 of 12 rooms are sellable.
  static const int _sellableRooms = 11;

  Future<Map<String, dynamic>> generateBusinessInsights({
    required DateTime selectedMonth,
    required double totalRevenue,
    required double totalExpenses,
    required double totalSalaries,
    required double totalProfit,
    required List<Map<String, dynamic>> bookings,
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> salaries,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final metrics = _computeMetrics(
      selectedMonth: selectedMonth,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      totalSalaries: totalSalaries,
      totalProfit: totalProfit,
      bookings: bookings,
      expenses: expenses,
      salaries: salaries,
    );

    try {
      final prompt = _buildPrompt(metrics);
      final text = await _callGemini(prompt);
      final parsed = _extractJson(text);
      if (parsed != null) {
        return _mergeWithMetrics(parsed, metrics);
      }
      return _offlineFallback(metrics,
          note: 'AI returned no parseable analysis — showing computed figures.');
    } catch (e) {
      return _offlineFallback(metrics,
          note: 'AI service unavailable ($e) — showing computed figures.');
    }
  }

  // ───────────────────────────── Metrics ──────────────────────────────────

  Map<String, dynamic> _computeMetrics({
    required DateTime selectedMonth,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
    required double totalRevenue,
    required double totalExpenses,
    required double totalSalaries,
    required double totalProfit,
    required List<Map<String, dynamic>> bookings,
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> salaries,
  }) {
    final start = rangeStart ?? DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = rangeEnd ?? DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final days = end.difference(start).inDays + 1;

    final roomTypeCounts = {'double': 0, 'triple': 0, 'family': 0, 'familyPlus': 0};
    final packageCounts = {
      'fullBoard': 0,
      'halfBoard': 0,
      'roomOnly': 0,
      'bnb': 0,
      'dinnerOnly': 0,
      'other': 0,
    };

    int roomsSold = 0, roomNightsSold = 0, totalGuests = 0, guestNights = 0;
    int driverRooms = 0;
    double breakfasts = 0, lunches = 0, dinners = 0;

    for (final b in bookings) {
      final nights = _nights(b);
      final pkg = (b['package'] ?? '').toString().toLowerCase();
      final mealStart = (b['mealStart'] ?? '').toString().toLowerCase();
      if (b['needDriver'] == true) driverRooms++;

      final rooms = b['rooms'];
      int bookingGuests = 0;
      int bookingRooms = 0;

      if (rooms is List && rooms.isNotEmpty) {
        for (final r in rooms) {
          bookingRooms++;
          final rt = (r is Map ? (r['roomType'] ?? '') : '').toString();
          int pax = 0;
          if (r is Map && r['pax'] != null) {
            pax = int.tryParse(r['pax'].toString()) ?? 0;
          }
          if (pax <= 0) pax = _guestsForType(rt);
          bookingGuests += pax;
          _bucketRoomType(roomTypeCounts, rt);
        }
      } else {
        // Legacy single-room booking
        bookingRooms = 1;
        final rt = (b['roomType'] ?? '').toString();
        bookingGuests = _guestsForType(rt);
        _bucketRoomType(roomTypeCounts, rt);
      }

      roomsSold += bookingRooms;
      roomNightsSold += bookingRooms * nights;
      totalGuests += bookingGuests;
      guestNights += bookingGuests * nights;
      _bucketPackage(packageCounts, pkg);

      // Meals per guest over the whole stay (mirrors home-screen meal logic).
      double b1 = 0, l1 = 0, d1 = 0;
      if (pkg.contains('full board')) {
        b1 = nights.toDouble();
        l1 = (nights - 1) + (mealStart.contains('lunch') ? 1 : 0);
        d1 = nights.toDouble();
      } else if (pkg.contains('half board')) {
        b1 = nights.toDouble();
        d1 = nights.toDouble();
      } else if (pkg.contains('bnb') || pkg.contains('bed')) {
        b1 = nights.toDouble();
      } else if (pkg.contains('dinner only')) {
        d1 = nights.toDouble();
      }
      breakfasts += b1 * bookingGuests;
      lunches += l1 * bookingGuests;
      dinners += d1 * bookingGuests;
    }

    // Expenses
    final expensesByCategory = <String, double>{};
    final expenseItems = <Map<String, dynamic>>[];
    double foodCost = 0, overtimeExpense = 0;
    for (final e in expenses) {
      final amt = double.tryParse((e['amount'] ?? '').toString()) ?? 0;
      final cat = (e['category'] ?? 'Other').toString().trim().isEmpty
          ? 'Other'
          : (e['category']).toString().trim();
      final name = (e['expenseName'] ?? e['description'] ?? 'Unnamed').toString();
      expensesByCategory[cat] = (expensesByCategory[cat] ?? 0) + amt;
      expenseItems.add({'name': name, 'amount': amt, 'category': cat});
      final lc = '$cat $name'.toLowerCase();
      if (lc.contains('food') ||
          lc.contains('kitchen') ||
          lc.contains('grocery') ||
          lc.contains('vegetable') ||
          lc.contains('meat') ||
          lc.contains('fish') ||
          lc.contains('provision')) {
        foodCost += amt;
      }
      if (lc.contains('overtime')) overtimeExpense += amt;
    }
    expenseItems.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    final topExpenses = expenseItems.take(12).toList();

    // High-impact outliers: any single expense ≥ 5% of revenue.
    final outlierThreshold = totalRevenue * 0.05;
    final outliers = <Map<String, dynamic>>[];
    for (final it in expenseItems) {
      final amt = it['amount'] as double;
      if (amt >= outlierThreshold && amt >= 3000) {
        outliers.add({
          'vendor': it['name'],
          'amount': amt.round(),
          'category': it['category'],
          'percentageOfRevenue': totalRevenue > 0
              ? (amt / totalRevenue * 100).toStringAsFixed(1)
              : '0',
        });
      }
      if (outliers.length >= 6) break;
    }

    // Salaries
    final salaryList = <Map<String, dynamic>>[];
    double chefCost = 0, overtimeSalary = 0;
    for (final s in salaries) {
      final amt = double.tryParse((s['amount'] ?? '').toString()) ?? 0;
      final name = (s['employeeName'] ?? 'Unknown').toString();
      final type = (s['salaryType'] ?? '').toString();
      salaryList.add({'name': name, 'type': type, 'amount': amt.round()});
      final lc = '$name $type'.toLowerCase();
      if (lc.contains('chef') || lc.contains('cook') || lc.contains('kitchen')) {
        chefCost += amt;
      }
      if (type.toUpperCase() == 'OT' || lc.contains('overtime')) {
        overtimeSalary += amt;
      }
    }

    // Derived KPIs
    final totalMeals = breakfasts + lunches + dinners;
    final profitMargin = totalRevenue > 0 ? totalProfit / totalRevenue * 100 : 0.0;
    final availableRoomNights = _sellableRooms * days;
    final occupancyRate = availableRoomNights > 0
        ? roomNightsSold / availableRoomNights * 100
        : 0.0;
    final adr = roomNightsSold > 0 ? totalRevenue / roomNightsSold : 0.0;
    final revpar = availableRoomNights > 0 ? totalRevenue / availableRoomNights : 0.0;
    final avgBookingValue =
        bookings.isNotEmpty ? totalRevenue / bookings.length : 0.0;
    final revenuePerGuest = totalGuests > 0 ? totalRevenue / totalGuests : 0.0;

    // Cost per meal — food cost split with breakfast lighter than lunch/dinner.
    const bw = 0.5, lw = 1.0, dw = 1.25;
    final weighted = bw * breakfasts + lw * lunches + dw * dinners;
    final unit = weighted > 0 ? foodCost / weighted : 0.0;

    return {
      'periodLabel':
          '${_dmy(start)} to ${_dmy(end)}',
      'days': days,
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'totalSalaries': totalSalaries,
      'totalProfit': totalProfit,
      'totalCost': totalExpenses + totalSalaries,
      'profitMargin': profitMargin,
      'bookingsCount': bookings.length,
      'roomsSold': roomsSold,
      'roomNightsSold': roomNightsSold,
      'availableRoomNights': availableRoomNights,
      'occupancyRate': occupancyRate,
      'adr': adr,
      'revpar': revpar,
      'avgBookingValue': avgBookingValue,
      'totalGuests': totalGuests,
      'guestNights': guestNights,
      'revenuePerGuest': revenuePerGuest,
      'roomTypeCounts': roomTypeCounts,
      'packageCounts': packageCounts,
      'breakfasts': breakfasts.round(),
      'lunches': lunches.round(),
      'dinners': dinners.round(),
      'totalMeals': totalMeals.round(),
      'foodCost': foodCost,
      'costPerMealBlended': totalMeals > 0 ? foodCost / totalMeals : 0.0,
      'costPerBreakfast': unit * bw,
      'costPerLunch': unit * lw,
      'costPerDinner': unit * dw,
      'expensesByCategory': expensesByCategory,
      'topExpenses': topExpenses,
      'expenseOutliers': outliers,
      'salaryList': salaryList,
      'chefCost': chefCost,
      'overtimeSalary': overtimeSalary,
      'overtimeExpense': overtimeExpense,
      'driverRooms': driverRooms,
      'sellableRooms': _sellableRooms,
    };
  }

  // ───────────────────────────── Prompt ───────────────────────────────────

  String _buildPrompt(Map<String, dynamic> m) {
    final rt = m['roomTypeCounts'] as Map<String, int>;
    final pc = m['packageCounts'] as Map<String, int>;
    final byCat = (m['expensesByCategory'] as Map<String, double>).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExpenses = (m['totalExpenses'] as num).toDouble();

    final catText = byCat.isEmpty
        ? '- (no expenses recorded)'
        : byCat
            .map((e) =>
                '- ${e.key}: ${_money(e.value)} (${_pct(totalExpenses > 0 ? e.value / totalExpenses * 100 : 0)} of expenses)')
            .join('\n');

    final topText = (m['topExpenses'] as List).isEmpty
        ? '- (none)'
        : (m['topExpenses'] as List)
            .map((e) =>
                '- ${e['name']}: ${_money(e['amount'])} [${e['category']}]')
            .join('\n');

    final outlierText = (m['expenseOutliers'] as List).isEmpty
        ? '- (no single expense exceeds 5% of revenue)'
        : (m['expenseOutliers'] as List)
            .map((o) =>
                '- ${o['vendor']}: ${_money(o['amount'])} = ${o['percentageOfRevenue']}% of revenue [${o['category']}]')
            .join('\n');

    final salaryText = (m['salaryList'] as List).isEmpty
        ? '- (no salaries recorded)'
        : (m['salaryList'] as List)
            .take(20)
            .map((s) => '- ${s['name']} (${s['type']}): ${_money(s['amount'])}')
            .join('\n');

    return '''
You are a senior hospitality business analyst and profit-optimisation consultant with 20+ years running boutique hotels. Analyse the data below for ODON Hotel (a small hotel in Sri Lanka, 11 sellable rooms). Your single goal: help the owner MAXIMISE PROFIT. Be sharp, specific and quantitative — every claim must cite a number from the data.

=== PERIOD: ${m['periodLabel']} (${m['days']} days) ===

FINANCIAL SUMMARY
- Total Revenue: ${_money(m['totalRevenue'])}
- Total Expenses (non-salary): ${_money(m['totalExpenses'])}
- Total Salaries: ${_money(m['totalSalaries'])}
- Total Operating Cost: ${_money(m['totalCost'])}
- Net Profit: ${_money(m['totalProfit'])}
- Profit Margin: ${_pct(m['profitMargin'])}

OCCUPANCY & DEMAND (11 sellable rooms; room 4 is the blocked manager's room)
- Bookings: ${m['bookingsCount']}
- Rooms sold: ${m['roomsSold']}  |  Room-nights sold: ${m['roomNightsSold']} of ${m['availableRoomNights']} available
- Occupancy rate: ${_pct(m['occupancyRate'])}
- ADR (avg revenue per room-night): ${_money(m['adr'])}
- RevPAR (revenue per available room): ${_money(m['revpar'])}
- Average booking value: ${_money(m['avgBookingValue'])}
- Driver rooms required: ${m['driverRooms']}

GUESTS
- Total guests served: ${m['totalGuests']}
- Guest-nights: ${m['guestNights']}
- Revenue per guest: ${_money(m['revenuePerGuest'])}

ROOM TYPE MIX (rooms sold)
- Double: ${rt['double']}  |  Triple: ${rt['triple']}  |  Family: ${rt['family']}  |  Family Plus: ${rt['familyPlus']}

PACKAGE MIX (bookings)
- Full Board: ${pc['fullBoard']}  |  Half Board: ${pc['halfBoard']}  |  BnB: ${pc['bnb']}  |  Room Only: ${pc['roomOnly']}  |  Dinner Only: ${pc['dinnerOnly']}  |  Other: ${pc['other']}

MEALS SERVED (computed from package, guests, nights & first arrival meal)
- Breakfasts: ${m['breakfasts']}  |  Lunches: ${m['lunches']}  |  Dinners: ${m['dinners']}  |  TOTAL MEALS: ${m['totalMeals']}
- Total food / kitchen cost: ${_money(m['foodCost'])}
- Blended cost per meal: ${_money(m['costPerMealBlended'])}
- Estimated cost per breakfast: ${_money(m['costPerBreakfast'])}
- Estimated cost per lunch: ${_money(m['costPerLunch'])}
- Estimated cost per dinner: ${_money(m['costPerDinner'])}
  (per-meal costs split the food bill with weighting breakfast 0.5 : lunch 1.0 : dinner 1.25 — keep these numbers, explain what they mean)
- Kitchen/chef salary: ${_money(m['chefCost'])}  |  Overtime paid (salaries): ${_money(m['overtimeSalary'])}  |  Overtime in expenses: ${_money(m['overtimeExpense'])}

EXPENSE BREAKDOWN BY CATEGORY
$catText

TOP INDIVIDUAL EXPENSES
$topText

HIGH-IMPACT EXPENSES (each ≥ 5% of revenue)
$outlierText

SALARIES PAID
$salaryText

=== ANALYSIS REQUIREMENTS ===
1. Be specific and quantitative — cite the numbers above. No vague filler.
2. Surface HIDDEN problems the owner would miss by glancing at totals: e.g. low occupancy masked by a high ADR, a category quietly inflating, meal cost per guest too high versus what the package sells for, overtime creep, idle weekday capacity, a profitable room type being under-sold.
3. For every expense you flag as too high, state WHY (as % of revenue, or vs. a sensible benchmark) and give a concrete fix with an estimated LKR saving.
4. Cost per meal: judge whether breakfast/lunch/dinner cost is healthy. Hotel food cost should typically be 28-38% of the meal's selling price — call out anything that looks rich or thin.
5. Give concrete profit-maximising moves across pricing, package mix, occupancy and cost control — each with an estimated LKR impact and a timeframe.
6. Benchmarks: small Sri Lankan hotels typically run 55-70% occupancy and 15-25% net margin — compare honestly.
7. Use ONLY the numbers provided. Never invent data. If something cannot be assessed, say so plainly.
8. "operationalInsights" MUST include at least these metrics: Occupancy Rate, Average Daily Rate (ADR), RevPAR, Guests Served, and Meals Served.

Return ONLY a JSON object (no markdown, no commentary) with EXACTLY this structure and keys:
{
  "overallHealth": "Excellent|Good|Fair|Poor",
  "profitabilityScore": 0,
  "keyInsights": ["short punchy insight with numbers", "..."],
  "criticalIssues": [{"issue": "...", "impact": "...", "urgency": "High|Medium|Low"}],
  "revenueAnalysis": {"summary": "...", "strengths": ["..."], "concerns": ["..."], "opportunities": ["..."]},
  "expenseAnalysis": {"summary": "...", "highestCategories": ["Category - LKR amount - why it matters"], "inefficiencies": ["..."], "optimizationTips": ["concrete tip with LKR saving"]},
  "operationalInsights": [{"metric": "Occupancy Rate", "status": "...", "recommendation": "..."}],
  "mealServiceAnalysis": {"summary": "include total meals & blended cost per meal", "breakfastAnalysis": "cost per breakfast + verdict", "lunchAnalysis": "cost per lunch + verdict", "dinnerAnalysis": "cost per dinner + verdict", "costOptimization": ["..."], "staffingInsights": "chef salary & overtime vs meals served"},
  "roomSalesAnalysis": {"summary": "...", "doubleRoomPerformance": "...", "tripleRoomPerformance": "...", "familyRoomPerformance": "...", "familyPlusPerformance": "...", "recommendations": ["..."]},
  "expenseOutliers": [{"vendor": "...", "amount": 0, "category": "...", "percentageOfRevenue": "0.0", "impact": "...", "recommendation": "..."}],
  "actionableRecommendations": [{"priority": "High|Medium|Low", "category": "Revenue|Expenses|Operations|Marketing", "action": "...", "expectedImpact": "estimated LKR impact", "timeframe": "..."}],
  "predictiveInsights": ["forward-looking insight", "..."],
  "benchmarkComparison": {"profitMargin": "your % vs 15-25% benchmark", "occupancyRate": "your % vs 55-70% benchmark", "revpar": "interpretation"}
}
''';
  }

  // ───────────────────────────── Gemini call ──────────────────────────────

  Future<String> _callGemini(String prompt) async {
    final res = await http.post(
      Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.65,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 16384,
          'response_mime_type': 'application/json',
          // Disable "thinking" so the whole token budget goes to the answer.
          'thinkingConfig': {'thinkingBudget': 0},
        }
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Gemini API ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    final candidates = data['candidates'];
    if (candidates == null || candidates.isEmpty) {
      throw Exception('no candidates returned');
    }
    final cand = candidates[0];
    final parts = cand['content']?['parts'];
    if (parts == null || parts.isEmpty) {
      throw Exception('empty response (finishReason: ${cand['finishReason']})');
    }
    return parts[0]['text'].toString();
  }

  Map<String, dynamic>? _extractJson(String text) {
    try {
      var t = text.trim().replaceAll('```json', '').replaceAll('```', '').trim();
      final s = t.indexOf('{');
      final e = t.lastIndexOf('}');
      if (s == -1 || e == -1 || e <= s) return null;
      final decoded = jsonDecode(t.substring(s, e + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────────── Merge / fallback ─────────────────────────

  Map<String, dynamic> _mergeWithMetrics(
      Map<String, dynamic> ai, Map<String, dynamic> m) {
    final r = Map<String, dynamic>.from(ai);
    final health = _health(m);

    r.putIfAbsent('overallHealth', () => health['label']);
    r.putIfAbsent('profitabilityScore', () => health['score']);
    r.putIfAbsent('keyInsights', () => <dynamic>[]);
    r.putIfAbsent('criticalIssues', () => <dynamic>[]);
    r.putIfAbsent('revenueAnalysis', () => <String, dynamic>{});
    r.putIfAbsent('expenseAnalysis', () => <String, dynamic>{});
    r.putIfAbsent('operationalInsights', () => <dynamic>[]);
    r.putIfAbsent('mealServiceAnalysis', () => <String, dynamic>{});
    r.putIfAbsent('roomSalesAnalysis', () => <String, dynamic>{});
    r.putIfAbsent('actionableRecommendations', () => <dynamic>[]);
    r.putIfAbsent('predictiveInsights', () => <dynamic>[]);
    r.putIfAbsent('benchmarkComparison', () => <String, dynamic>{});

    // If the model returned no outliers, use the locally-computed ones so the
    // owner still sees the real high-impact expenses.
    final aiOut = r['expenseOutliers'];
    if (aiOut is! List || aiOut.isEmpty) {
      r['expenseOutliers'] = _localOutliers(m);
    }
    return r;
  }

  List<Map<String, dynamic>> _localOutliers(Map<String, dynamic> m) {
    return (m['expenseOutliers'] as List).map<Map<String, dynamic>>((o) {
      return {
        'vendor': o['vendor'],
        'amount': o['amount'],
        'category': o['category'],
        'percentageOfRevenue': o['percentageOfRevenue'],
        'impact':
            'Consumes ${o['percentageOfRevenue']}% of total revenue — a large single draw on profit.',
        'recommendation':
            'Review this ${o['category']} expense: get competing quotes, negotiate the rate, or reduce frequency.',
      };
    }).toList();
  }

  /// Fully data-driven analysis used when the AI call fails. Not placeholder
  /// text — it reports the real computed figures and obvious conclusions.
  Map<String, dynamic> _offlineFallback(Map<String, dynamic> m,
      {required String note}) {
    final health = _health(m);
    final margin = (m['profitMargin'] as num).toDouble();
    final occ = (m['occupancyRate'] as num).toDouble();
    final byCat = (m['expensesByCategory'] as Map<String, double>).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final rt = m['roomTypeCounts'] as Map<String, int>;

    return {
      'overallHealth': health['label'],
      'profitabilityScore': health['score'],
      'keyInsights': [
        note,
        'Net profit ${_money(m['totalProfit'])} on ${_money(m['totalRevenue'])} revenue — margin ${_pct(margin)}.',
        'Occupancy ${_pct(occ)} (${m['roomNightsSold']}/${m['availableRoomNights']} room-nights). ${m['totalGuests']} guests served.',
        '${m['totalMeals']} meals served — blended cost ${_money(m['costPerMealBlended'])} per meal.',
      ],
      'criticalIssues': [
        if (margin < 10)
          {
            'issue': 'Thin profit margin (${_pct(margin)})',
            'impact':
                'Below the 15-25% healthy range for small hotels — little buffer against a slow month.',
            'urgency': margin < 3 ? 'High' : 'Medium',
          },
        if (occ < 55)
          {
            'issue': 'Low occupancy (${_pct(occ)})',
            'impact':
                '${m['availableRoomNights'] - m['roomNightsSold']} room-nights went unsold — pure lost revenue.',
            'urgency': occ < 35 ? 'High' : 'Medium',
          },
      ],
      'revenueAnalysis': {
        'summary':
            'Revenue ${_money(m['totalRevenue'])} from ${m['bookingsCount']} bookings. ADR ${_money(m['adr'])}, RevPAR ${_money(m['revpar'])}, avg booking ${_money(m['avgBookingValue'])}.',
        'strengths': [
          if (margin >= 15) 'Healthy margin of ${_pct(margin)}.',
          if ((m['adr'] as num) > 0) 'ADR holding at ${_money(m['adr'])}.',
        ],
        'concerns': [
          if (occ < 55) 'Occupancy ${_pct(occ)} leaves rooms empty.',
          if (margin < 15) 'Margin ${_pct(margin)} below benchmark.',
        ],
        'opportunities': [
          'Lifting occupancy to 65% would add roughly ${_money((0.65 * (m['availableRoomNights'] as int) - (m['roomNightsSold'] as int)).clamp(0, double.infinity) * (m['adr'] as num))} at current ADR.',
        ],
      },
      'expenseAnalysis': {
        'summary':
            'Expenses ${_money(m['totalExpenses'])} + salaries ${_money(m['totalSalaries'])} = ${_money(m['totalCost'])} total cost.',
        'highestCategories': byCat
            .take(4)
            .map((e) => '${e.key}: ${_money(e.value)}')
            .toList(),
        'inefficiencies': [
          if ((m['overtimeSalary'] as num) + (m['overtimeExpense'] as num) > 0)
            'Overtime totals ${_money((m['overtimeSalary'] as num) + (m['overtimeExpense'] as num))} — check if rostering can absorb it.',
        ],
        'optimizationTips': [
          'Renegotiate the largest category (${byCat.isNotEmpty ? byCat.first.key : "n/a"}).',
          'Track food cost as a % of meal package price each month.',
        ],
      },
      'operationalInsights': [
        {
          'metric': 'Occupancy Rate',
          'status': '${_pct(occ)} (benchmark 55-70%)',
          'recommendation': occ < 55
              ? 'Push weekday and last-minute deals to fill idle rooms.'
              : 'Healthy — protect rate, avoid over-discounting.',
        },
        {
          'metric': 'Average Daily Rate (ADR)',
          'status': _money(m['adr']),
          'recommendation':
              'Test a small rate rise on high-demand dates; watch booking pace.',
        },
        {
          'metric': 'RevPAR',
          'status': _money(m['revpar']),
          'recommendation': 'Grows with either occupancy or ADR — target the weaker one.',
        },
        {
          'metric': 'Guests Served',
          'status': '${m['totalGuests']} guests, ${m['guestNights']} guest-nights',
          'recommendation': 'Revenue per guest ${_money(m['revenuePerGuest'])}.',
        },
        {
          'metric': 'Meals Served',
          'status': '${m['totalMeals']} meals (B:${m['breakfasts']} L:${m['lunches']} D:${m['dinners']})',
          'recommendation':
              'Blended cost ${_money(m['costPerMealBlended'])}/meal — keep food cost 28-38% of package price.',
        },
      ],
      'mealServiceAnalysis': {
        'summary':
            '${m['totalMeals']} meals served for ${_money(m['foodCost'])} food cost — blended ${_money(m['costPerMealBlended'])} per meal.',
        'breakfastAnalysis':
            '${m['breakfasts']} breakfasts, est. ${_money(m['costPerBreakfast'])} each.',
        'lunchAnalysis':
            '${m['lunches']} lunches, est. ${_money(m['costPerLunch'])} each.',
        'dinnerAnalysis':
            '${m['dinners']} dinners, est. ${_money(m['costPerDinner'])} each.',
        'costOptimization': [
          'Buy high-volume produce wholesale / weekly to cut unit cost.',
          'Standardise portion sizes to control per-meal cost.',
        ],
        'staffingInsights':
            'Kitchen/chef salary ${_money(m['chefCost'])}, overtime ${_money(m['overtimeSalary'])} — compare against ${m['totalMeals']} meals served.',
      },
      'roomSalesAnalysis': {
        'summary':
            '${m['roomsSold']} rooms sold across ${m['bookingsCount']} bookings.',
        'doubleRoomPerformance': '${rt['double']} double rooms sold.',
        'tripleRoomPerformance': '${rt['triple']} triple rooms sold.',
        'familyRoomPerformance': '${rt['family']} family rooms sold.',
        'familyPlusPerformance': '${rt['familyPlus']} family plus rooms sold.',
        'recommendations': [
          'Promote the lowest-selling room type with a targeted package.',
          'Upsell doubles to triples with the extra-bed option.',
        ],
      },
      'expenseOutliers': _localOutliers(m),
      'actionableRecommendations': [
        if (occ < 60)
          {
            'priority': 'High',
            'category': 'Revenue',
            'action': 'Run a weekday / last-minute discount to lift occupancy.',
            'expectedImpact':
                'Each extra 5% occupancy ≈ ${_money(0.05 * (m['availableRoomNights'] as int) * (m['adr'] as num))}.',
            'timeframe': '1-2 weeks',
          },
        {
          'priority': 'Medium',
          'category': 'Expenses',
          'action': 'Renegotiate or re-quote the top expense categories.',
          'expectedImpact': 'A 10% cut ≈ ${_money(0.10 * (m['totalExpenses'] as num))}.',
          'timeframe': '1 month',
        },
      ],
      'predictiveInsights': [
        'Track occupancy and ADR month-on-month to catch demand shifts early.',
        'If food cost % keeps rising, package prices will need review.',
      ],
      'benchmarkComparison': {
        'profitMargin': '${_pct(margin)} vs 15-25% benchmark',
        'occupancyRate': '${_pct(occ)} vs 55-70% benchmark',
        'revpar': '${_money(m['revpar'])} per available room',
      },
    };
  }

  // ───────────────────────────── Helpers ──────────────────────────────────

  Map<String, dynamic> _health(Map<String, dynamic> m) {
    final margin = (m['profitMargin'] as num).toDouble();
    final occ = (m['occupancyRate'] as num).toDouble();
    double score = (margin / 25 * 60).clamp(0, 60).toDouble();
    score += (occ / 70 * 40).clamp(0, 40).toDouble();
    final s = score.round().clamp(0, 100);
    String label;
    if (s >= 80) {
      label = 'Excellent';
    } else if (s >= 62) {
      label = 'Good';
    } else if (s >= 45) {
      label = 'Fair';
    } else {
      label = 'Poor';
    }
    return {'label': label, 'score': s};
  }

  int _nights(Map b) {
    final n = int.tryParse((b['num_of_nights'] ?? '').toString());
    if (n != null && n > 0) return n;
    try {
      final ci = DateTime.parse(b['checkIn'].toString());
      final co = DateTime.parse(b['checkOut'].toString());
      final d = co.difference(ci).inDays;
      return d > 0 ? d : 1;
    } catch (_) {
      return 1;
    }
  }

  int _guestsForType(String? type) {
    final s = (type ?? '').toLowerCase();
    if (s.contains('family plus') || s.contains('family_plus')) return 5;
    if (s.contains('family')) return 4;
    if (s.contains('triple')) return 3;
    if (s.contains('double')) return 2;
    return 2;
  }

  void _bucketRoomType(Map<String, int> m, String type) {
    final s = type.toLowerCase();
    if (s.contains('family plus') || s.contains('family_plus')) {
      m['familyPlus'] = m['familyPlus']! + 1;
    } else if (s.contains('family')) {
      m['family'] = m['family']! + 1;
    } else if (s.contains('triple')) {
      m['triple'] = m['triple']! + 1;
    } else if (s.contains('double')) {
      m['double'] = m['double']! + 1;
    }
  }

  void _bucketPackage(Map<String, int> m, String pkg) {
    if (pkg.contains('full board')) {
      m['fullBoard'] = m['fullBoard']! + 1;
    } else if (pkg.contains('half board')) {
      m['halfBoard'] = m['halfBoard']! + 1;
    } else if (pkg.contains('dinner only')) {
      m['dinnerOnly'] = m['dinnerOnly']! + 1;
    } else if (pkg.contains('room only')) {
      m['roomOnly'] = m['roomOnly']! + 1;
    } else if (pkg.contains('bnb') || pkg.contains('bed')) {
      m['bnb'] = m['bnb']! + 1;
    } else {
      m['other'] = m['other']! + 1;
    }
  }

  String _money(dynamic v) {
    final n = (v is num) ? v : double.tryParse(v.toString()) ?? 0;
    final neg = n < 0;
    final s = n.abs().round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${neg ? '-' : ''}LKR ${buf.toString()}';
  }

  String _pct(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return '${n.toStringAsFixed(1)}%';
  }

  String _dmy(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
