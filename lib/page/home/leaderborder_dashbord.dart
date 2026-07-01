// leaderboard_detail_page.dart
// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_underscores, use_super_parameters

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/leaderborder_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/models/top_hrm_model.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/widigets/appbars.dart';

class LeaderboardDetailPage extends StatefulWidget {
  final DateTime initialMonth;
  final List<HrmTopListReport>? initialRecords;

  const LeaderboardDetailPage({
    Key? key,
    required this.initialMonth,
    this.initialRecords,
  }) : super(key: key);

  @override
  State<LeaderboardDetailPage> createState() => _LeaderboardDetailPageState();
}

class _LeaderboardDetailPageState extends State<LeaderboardDetailPage> {
  @override
  void initState() {
    super.initState();
    
    // Use addPostFrameCallback to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leaderProvider = Provider.of<LeaderborderProvider>(context, listen: false);
      
      // Check if we need to load data
      if (widget.initialRecords == null || widget.initialRecords!.isEmpty) {
        // Load data for the selected month
        leaderProvider.getTopLeaderboard(
          month: widget.initialMonth.month,
          year: widget.initialMonth.year,
        );
      } else {
        // Data is already provided, just process it
        leaderProvider.processExistingData(widget.initialRecords!, widget.initialMonth);
      }
    });
  }
  

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final leaderProvider = Provider.of<LeaderborderProvider>(context);
    

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: showCustomeAppBar(
        'Leaderboard',
        size,
        titleColors: ColorConst.appbarTextColor,
        iconsOntap: () => backScreen(context),
      ),
      body: leaderProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: ColorConst.themeColor))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildMonthSelector(size, leaderProvider)),
                if (leaderProvider.allRecords.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(size, leaderProvider.selectedMonth),
                  )
                else ...[
                  SliverToBoxAdapter(child: _buildStatsHeader(size, leaderProvider)),
                  SliverToBoxAdapter(child: _buildChartSection(size, leaderProvider)),
                  SliverToBoxAdapter(child: _buildPodiumCards(size, leaderProvider)),
                  if (leaderProvider.others.isNotEmpty)
                    SliverToBoxAdapter(child: _buildOthersSection(size, leaderProvider)),
                ],
              ],
            ),
    );
  }

  Widget _buildMonthSelector(Size size, LeaderborderProvider provider) {
    final isCurrentMonth = provider.selectedMonth.month == DateTime.now().month &&
        provider.selectedMonth.year == DateTime.now().year;

    return Container(
      margin: EdgeInsets.fromLTRB(size.width * 0.04, size.height * 0.015, size.width * 0.04, 0),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _monthBtn(
            Icons.chevron_left,
            ColorConst.themeColor,
            () => provider.previousLeaderboardMonth(),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.005),
            decoration: BoxDecoration(
              color: ColorConst.themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('MMMM yyyy').format(provider.selectedMonth),
              style: TextStyle(fontSize: size.width * 0.04, fontWeight: FontWeight.w600, color: ColorConst.textHeadingColor),
            ),
          ),
          _monthBtn(
            Icons.chevron_right,
            isCurrentMonth ? Colors.grey.shade300 : ColorConst.themeColor,
            isCurrentMonth ? null : () => provider.nextLeaderboardMonth(),
          ),
        ],
      ),
    );
  }

  Widget _monthBtn(IconData icon, Color color, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(Size size, LeaderborderProvider provider) {
    final allRecords = provider.allRecords;
    if (allRecords.isEmpty) return const SizedBox.shrink();

    int totalMin = 0, maxMin = 0;
    String topName = '';
    for (var r in allRecords) {
      final m = _toMinutes(r.netWorkingHours ?? '0h 0m');
      totalMin += m;
      if (m > maxMin) {
        maxMin = m;
        topName = _formatName(r.empName ?? '');
      }
    }
    final avg = totalMin ~/ allRecords.length;

    return Container(
      margin: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorConst.themeColor, ColorConst.themeColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: ColorConst.themeColor.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(right: -24, top: -24, child: Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle))),
          Positioned(left: -16, bottom: -16, child: Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle))),
          Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip(size, '${allRecords.length}', 'Participants', Icons.people_outline),
                    _statChip(size, '${avg ~/ 60}h ${avg % 60}m', 'Avg Hours', Icons.access_time),
                    _statChip(size, '${maxMin ~/ 60}h ${maxMin % 60}m', 'Top Hours', Icons.emoji_events_outlined),
                  ],
                ),
                SizedBox(height: size.height * 0.012),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 8),
                      Text('Top Performer: $topName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(Size size, String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(size.width * 0.025),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1)),
          child: Icon(icon, color: Colors.white, size: size.width * 0.045),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildChartSection(Size size, LeaderborderProvider provider) {
    final allRecords = provider.allRecords;
    if (allRecords.isEmpty) return const SizedBox.shrink();

    final top5 = List<HrmTopListReport>.from(allRecords)
      ..sort((a, b) => (b.netWorkingMinutes ?? 0).compareTo(a.netWorkingMinutes ?? 0));
    final chartData = top5.take(5).toList();
    final maxMinutes = chartData.map((e) => e.netWorkingMinutes ?? 0).reduce((a, b) => a > b ? a : b);

    final barColors = [ColorConst.gold, ColorConst.silver, ColorConst.bronze, ColorConst.themeColor.withOpacity(0.75), ColorConst.themeColor.withOpacity(0.55)];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: EdgeInsets.all(size.width * 0.02), decoration: BoxDecoration(color: ColorConst.themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.bar_chart, size: size.width * 0.045, color: ColorConst.themeColor)),
              const SizedBox(width: 12),
              Text('Performance Overview', style: TextStyle(fontSize: size.width * 0.038, fontWeight: FontWeight.bold, color: ColorConst.textHeadingColor)),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(chartData.length, (index) {
            final emp = chartData[index];
            final minutes = emp.netWorkingMinutes ?? 0;
            final pct = maxMinutes > 0 ? minutes / maxMinutes : 0.0;
            final name = _formatName(emp.empName ?? '');
            final barColor = barColors[index];

            return Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.015),
              child: Row(
                children: [
                  Container(width: size.width * 0.08, height: size.width * 0.08, decoration: BoxDecoration(color: barColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: barColor.withOpacity(0.35), width: 1)), child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: size.width * 0.03, fontWeight: FontWeight.bold, color: barColor)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontSize: size.width * 0.033, fontWeight: FontWeight.w600, color: ColorConst.textHeadingColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: pct, backgroundColor: barColor.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(ColorConst.greenProgress), minHeight: 8)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(minutes ~/ 60 > 0 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m', style: TextStyle(fontSize: size.width * 0.028, fontWeight: FontWeight.w600, color: barColor)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPodiumCards(Size size, LeaderborderProvider provider) {
    final podiumData = [
      {'title': 'Gold Medalists', 'icon': '🥇', 'color': ColorConst.gold, 'light': ColorConst.goldLight, 'border': ColorConst.goldBorder, 'text': ColorConst.goldText, 'shadow': ColorConst.goldShadow, 'winners': provider.firstPlace},
      {'title': 'Silver Medalists', 'icon': '🥈', 'color': ColorConst.silver, 'light': ColorConst.silverLight, 'border': ColorConst.silverBorder, 'text': ColorConst.silverText, 'shadow': ColorConst.silverShadow, 'winners': provider.secondPlace},
      {'title': 'Bronze Medalists', 'icon': '🥉', 'color': ColorConst.bronze, 'light': ColorConst.bronzeLight, 'border': ColorConst.bronzeBorder, 'text': ColorConst.bronzeText, 'shadow': ColorConst.bronzeShadow, 'winners': provider.thirdPlace},
    ];

    return Column(
      children: podiumData.where((p) => (p['winners'] as List).isNotEmpty).map((podium) {
        final color = podium['color'] as Color;
        final light = podium['light'] as Color;
        final border = podium['border'] as Color;
        final text = podium['text'] as Color;
        final shadow = podium['shadow'] as Color;
        final winners = podium['winners'] as List<WinnerModels>;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.008),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: shadow, blurRadius: 14, offset: const Offset(0, 5))], border: Border.all(color: border, width: 1)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.012), color: light,
                  child: Row(
                    children: [
                      Text(podium['icon'].toString(), style: TextStyle(fontSize: size.width * 0.055)),
                      const SizedBox(width: 10),
                      Text(podium['title'].toString(), style: TextStyle(fontSize: size.width * 0.035, fontWeight: FontWeight.bold, color: text)),
                      const Spacer(),
                      Container(padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.004), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                        child: Text('${winners.length} ${winners.length == 1 ? 'Winner' : 'Winners'}', style: TextStyle(fontSize: size.width * 0.022, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                ...List.generate(winners.length, (index) {
                  final winner = winners[index];
                  final progress = (winner.netWorkingMinutes / (provider.firstPlace.isNotEmpty ? provider.firstPlace[0].netWorkingMinutes : 1)).clamp(0.0, 1.0);
                  return _buildWinnerCard(size, winner, progress, color, border);
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWinnerCard(Size size, WinnerModels winner, double progress, Color color, Color borderColor) {
    final initials = winner.name.split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.012),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.3)))),
      child: Row(
        children: [
          Container(width: size.width * 0.08, height: size.width * 0.08, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3), width: 1)),
            child: Center(child: Text('${winner.rank}', style: TextStyle(fontSize: size.width * 0.03, fontWeight: FontWeight.bold, color: color)))),
          const SizedBox(width: 14),
          Container(width: size.width * 0.11, height: size.width * 0.11, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Center(child: Text(initials.toUpperCase(), style: TextStyle(fontSize: size.width * 0.035, fontWeight: FontWeight.bold, color: Colors.white)))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(winner.name, style: TextStyle(fontSize: size.width * 0.035, fontWeight: FontWeight.w600, color: ColorConst.textHeadingColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(ColorConst.greenProgress), minHeight: 7))),
                    const SizedBox(width: 12),
                    Text(winner.hours, style: TextStyle(fontSize: size.width * 0.03, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: size.width * 0.024, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text('${winner.totalDays} days', style: TextStyle(fontSize: size.width * 0.024, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Icon(Icons.free_breakfast, size: size.width * 0.024, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(winner.totalBreakHours, style: TextStyle(fontSize: size.width * 0.024, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOthersSection(Size size, LeaderborderProvider provider) {
    final others = provider.others;
    if (others.isEmpty) return const SizedBox.shrink();

    final maxMinutes = others.map((e) => e.netWorkingMinutes).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: EdgeInsets.only(left: size.width * 0.04, right: size.width * 0.04, bottom: size.height * 0.03),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.014), decoration: BoxDecoration(color: ColorConst.othersHeader, border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),),
              child: Row(
                children: [
                  Container(padding: EdgeInsets.all(size.width * 0.01), decoration: BoxDecoration(color: ColorConst.othersAvatar, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.people_alt, size: size.width * 0.04, color: ColorConst.othersAvatarText)),
                  const SizedBox(width: 12),
                  Text('Other Participants', style: TextStyle(fontSize: size.width * 0.035, fontWeight: FontWeight.w700, color: ColorConst.othersHeaderText, letterSpacing: 0.3)),
                  const Spacer(),
                  Container(padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.005), decoration: BoxDecoration(gradient: LinearGradient(colors: [ColorConst.othersBadge, ColorConst.othersBadge.withOpacity(0.8)]), borderRadius: BorderRadius.circular(20)),
                    child: Text('${others.length} Participants', style: TextStyle(fontSize: size.width * 0.022, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Container(padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.012), color: Colors.grey.shade50,
              child: Row(
                children: [
                  SizedBox(width: size.width * 0.07), const SizedBox(width: 12), SizedBox(width: size.width * 0.09), const SizedBox(width: 12),
                  Expanded(child: Text('Employee Name', style: TextStyle(fontSize: size.width * 0.028, fontWeight: FontWeight.w600, color: Colors.grey.shade700, letterSpacing: 0.3))),
                  SizedBox(width: size.width * 0.12),
                  Text('Hours', style: TextStyle(fontSize: size.width * 0.028, fontWeight: FontWeight.w600, color: Colors.grey.shade700, letterSpacing: 0.3)),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: others.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) => _buildOtherRow(size, others[i], maxMinutes, i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherRow(Size size, WinnerModels winner, int maxMinutes, int index) {
    final initials = winner.name.split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
    final progress = maxMinutes > 0 ? (winner.netWorkingMinutes / maxMinutes).clamp(0.0, 1.0) : 0.0;
    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;

    return Container(
      color: rowColor,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.014),
      child: Row(
        children: [
          Container(width: size.width * 0.07, height: size.width * 0.07, decoration: BoxDecoration(gradient: LinearGradient(colors: [ColorConst.othersRankBg, ColorConst.othersRankBg.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))]),
            child: Center(child: Text('${winner.rank}', style: TextStyle(fontSize: size.width * 0.03, fontWeight: FontWeight.w800, color: ColorConst.othersRankText)))),
          const SizedBox(width: 12),
          Container(width: size.width * 0.09, height: size.width * 0.09, decoration: BoxDecoration(gradient: LinearGradient(colors: [ColorConst.othersAvatar, ColorConst.othersAvatar.withOpacity(0.7)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: ColorConst.othersAvatarText.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]),
            child: Center(child: Text(initials.toUpperCase(), style: TextStyle(fontSize: size.width * 0.032, fontWeight: FontWeight.w700, color: ColorConst.othersAvatarText)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(winner.name, style: TextStyle(fontSize: size.width * 0.035, fontWeight: FontWeight.w600, color: ColorConst.textHeadingColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(flex: 3, child: Container(height: 8, decoration: BoxDecoration(color: ColorConst.greenProgress.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(ColorConst.greenProgress), minHeight: 8)))),
                    const SizedBox(width: 12),
                    Expanded(flex: 1, child: Text(winner.hours, style: TextStyle(fontSize: size.width * 0.028, fontWeight: FontWeight.w700, color: ColorConst.greenProgress), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: size.width * 0.024, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text('${winner.totalDays} days', style: TextStyle(fontSize: size.width * 0.024, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    Container(width: 5, height: 5, margin: EdgeInsets.symmetric(horizontal: size.width * 0.02), decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                    Icon(Icons.free_breakfast, size: size.width * 0.024, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(winner.totalBreakHours, style: TextStyle(fontSize: size.width * 0.024, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Size size, DateTime selectedMonth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: EdgeInsets.all(size.width * 0.06), decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(Icons.emoji_events_outlined, size: size.width * 0.12, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 20),
          Text('No Data Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ColorConst.textHeadingColor)),
          const SizedBox(height: 8),
          Text('No records found for\n${DateFormat('MMMM yyyy').format(selectedMonth)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  int _toMinutes(String s) {
    if (s.isEmpty) return 0;
    int total = 0;
    final reg = RegExp(r'(\d+)h\s*(\d*)m?');
    for (final m in reg.allMatches(s)) {
      total += int.parse(m.group(1)!) * 60;
      if (m.group(2) != null && m.group(2)!.isNotEmpty) total += int.parse(m.group(2)!);
    }
    return total;
  }

  String _formatName(String name) => name.toLowerCase().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
}