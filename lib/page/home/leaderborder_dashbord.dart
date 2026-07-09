// leaderboard_detail_page.dart
// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_underscores, use_super_parameters

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/leaderborder_provider.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/theme_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/models/top_hrm_model.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    Provider.of<ThemeProvider>(context);
    
    final locale = languageProvider.currentLanguage;

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: showCustomeAppBar(
        leaderboardString,
        size,
        titleColors: ColorConst.appbarTextColor,
        iconsOntap: () => backScreen(context),
      ),
      body: leaderProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: ColorConst.themeColor))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildMonthSelector(size, leaderProvider, locale)),
                if (leaderProvider.allRecords.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(size, leaderProvider.selectedMonth, locale),
                  )
                else ...[
                  SliverToBoxAdapter(child: _buildStatsHeader(size, leaderProvider)),
                  SliverToBoxAdapter(child: _buildVisualPodium(size, leaderProvider)),
                  SliverToBoxAdapter(child: _buildChartSection(size, leaderProvider)),
                  if (leaderProvider.others.isNotEmpty)
                    SliverToBoxAdapter(child: _buildOthersSection(size, leaderProvider)),
                ],
              ],
            ),
    );
  }

  Widget _buildMonthSelector(Size size, LeaderborderProvider provider, String locale) {
    final isCurrentMonth = provider.selectedMonth.month == DateTime.now().month &&
        provider.selectedMonth.year == DateTime.now().year;

    return Container(
      margin: EdgeInsets.fromLTRB(size.width * 0.04, size.height * 0.015, size.width * 0.04, 0),
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.008),
      decoration: BoxDecoration(
        color: ColorConst.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorConst.textBorder.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _monthBtn(
            Icons.arrow_back_ios_new_rounded,
            ColorConst.themeColor,
            () => provider.previousLeaderboardMonth(),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy', locale).format(provider.selectedMonth),
                style: TextStyle(
                  fontSize: size.width * 0.042, 
                  fontWeight: FontWeight.bold, 
                  color: ColorConst.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          _monthBtn(
            Icons.arrow_forward_ios_rounded,
            isCurrentMonth ? ColorConst.textBorder : ColorConst.themeColor,
            isCurrentMonth ? null : () => provider.nextLeaderboardMonth(),
          ),
        ],
      ),
    );
  }

  Widget _monthBtn(IconData icon, Color color, VoidCallback? onTap) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnabled ? color.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: isEnabled ? color : ColorConst.textgrey.withOpacity(0.4), size: 16),
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.015),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  size,
                  participantsString,
                  '${allRecords.length}',
                  Icons.people_outline,
                  ColorConst.themeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernStatCard(
                  size,
                  avgHoursString,
                  '${avg ~/ 60}${LanguageProvider.translate("h", "h")} ${avg % 60}${LanguageProvider.translate("m", "m")}',
                  Icons.schedule_rounded,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: ColorConst.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ColorConst.textBorder.withOpacity(0.5), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConst.gold.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.stars_rounded, color: ColorConst.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topPerformerString,
                        style: TextStyle(color: ColorConst.textgrey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topName,
                        style: TextStyle(color: ColorConst.black, fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${maxMin ~/ 60}${LanguageProvider.translate("h", "h")} ${maxMin % 60}${LanguageProvider.translate("m", "m")}',
                  style: TextStyle(color: ColorConst.goldText, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(Size size, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConst.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConst.textBorder.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: ColorConst.textgrey, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: ColorConst.black, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPodium(Size size, LeaderborderProvider provider) {
    final first = provider.firstPlace.isNotEmpty ? provider.firstPlace.first : null;
    final second = provider.secondPlace.isNotEmpty ? provider.secondPlace.first : null;
    final third = provider.thirdPlace.isNotEmpty ? provider.thirdPlace.first : null;

    if (first == null && second == null && third == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: ColorConst.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorConst.textBorder.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(
            topPerformerString,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorConst.black, letterSpacing: 0.3),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2nd Place Column
              Expanded(
                child: second != null
                    ? _podiumCol(size, second, ColorConst.silver, ColorConst.silverLight, 75, '🥈')
                    : const SizedBox.shrink(),
              ),
              // 1st Place Column
              Expanded(
                child: first != null
                    ? _podiumCol(size, first, ColorConst.gold, ColorConst.goldLight, 105, '👑')
                    : const SizedBox.shrink(),
              ),
              // 3rd Place Column
              Expanded(
                child: third != null
                    ? _podiumCol(size, third, ColorConst.bronze, ColorConst.bronzeLight, 60, '🥉')
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumCol(Size size, WinnerModels winner, Color themeCol, Color bgCol, double height, String badge) {
    final initials = winner.name.split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge icon (crown or medal)
        Text(badge, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        // Avatar circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeCol,
            boxShadow: [
              BoxShadow(
                color: themeCol.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Name
        Text(
          _formatName(winner.name),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConst.black),
        ),
        const SizedBox(height: 4),
        // Hours text
        Text(
          winner.hours,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: themeCol),
        ),
        const SizedBox(height: 8),
        // Physical podium block
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(color: themeCol.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${winner.rank}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: themeCol),
              ),
              const SizedBox(height: 2),
              Text(
                '${winner.totalDays}D',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ColorConst.textgrey),
              ),
            ],
          ),
        ),
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

    final barColors = [
      ColorConst.gold, 
      ColorConst.silver, 
      ColorConst.bronze, 
      ColorConst.themeColor.withOpacity(0.75), 
      ColorConst.themeColor.withOpacity(0.55)
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.01),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: ColorConst.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: ColorConst.textBorder.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), 
                decoration: BoxDecoration(color: ColorConst.themeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), 
                child: Icon(Icons.bar_chart_rounded, size: 20, color: ColorConst.themeColor),
              ),
              const SizedBox(width: 12),
              Text(performanceOverviewString, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ColorConst.black)),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(chartData.length, (index) {
            final emp = chartData[index];
            final minutes = emp.netWorkingMinutes ?? 0;
            final pct = maxMinutes > 0 ? minutes / maxMinutes : 0.0;
            final name = _formatName(emp.empName ?? '');
            final barColor = barColors[index];

            return Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.018),
              child: Row(
                children: [
                  Container(
                    width: 32, 
                    height: 32, 
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(10), 
                    ), 
                    child: Center(
                      child: Text(
                        '${index + 1}', 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: barColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ColorConst.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10), 
                          child: LinearProgressIndicator(
                            value: pct, 
                            backgroundColor: ColorConst.isDark ? Colors.white.withOpacity(0.05) : barColor.withOpacity(0.08), 
                            valueColor: AlwaysStoppedAnimation<Color>(barColor), 
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    minutes ~/ 60 > 0 ? '${minutes ~/ 60}${LanguageProvider.translate("h", "h")} ${minutes % 60}${LanguageProvider.translate("m", "m")}' : '$minutes${LanguageProvider.translate("m", "m")}', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor),
                  ),
                ],
              ),
            );
          }),
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
      decoration: BoxDecoration(
        color: ColorConst.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: ColorConst.textBorder.withOpacity(0.5), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.016), 
              decoration: BoxDecoration(
                color: ColorConst.othersHeader, 
                border: Border(bottom: BorderSide(color: ColorConst.textBorder.withOpacity(0.5), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), 
                    decoration: BoxDecoration(color: ColorConst.othersAvatar, borderRadius: BorderRadius.circular(10)), 
                    child: Icon(Icons.people_alt_rounded, size: 16, color: ColorConst.othersAvatarText),
                  ),
                  const SizedBox(width: 12),
                  Text(otherParticipantsString, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ColorConst.othersHeaderText, letterSpacing: 0.3)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                    decoration: BoxDecoration(
                      color: ColorConst.othersBadge.withOpacity(0.12), 
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${others.length} $participantsString', 
                      style: TextStyle(fontSize: 11, color: ColorConst.othersBadge, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: others.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: ColorConst.textBorder.withOpacity(0.5)),
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
    final rowColor = index % 2 == 0 ? ColorConst.white : ColorConst.greyOpicityColor;

    return Container(
      color: rowColor,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: size.height * 0.016),
      child: Row(
        children: [
          Container(
            width: 28, 
            height: 28, 
            decoration: BoxDecoration(
              color: ColorConst.othersRankBg, 
              borderRadius: BorderRadius.circular(8), 
            ),
            child: Center(
              child: Text(
                '${winner.rank}', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConst.othersRankText),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36, 
            height: 36, 
            decoration: BoxDecoration(
              color: ColorConst.othersAvatar, 
              shape: BoxShape.circle, 
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(), 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConst.othersAvatarText),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(winner.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ColorConst.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 3, 
                      child: Container(
                        height: 6, 
                        decoration: BoxDecoration(
                          color: ColorConst.isDark ? Colors.white.withOpacity(0.05) : ColorConst.themeColor.withOpacity(0.08), 
                          borderRadius: BorderRadius.circular(3),
                        ), 
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3), 
                          child: LinearProgressIndicator(
                            value: progress, 
                            backgroundColor: Colors.transparent, 
                            valueColor: AlwaysStoppedAnimation<Color>(ColorConst.themeColor), 
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1, 
                      child: Text(
                        winner.hours, 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConst.themeColor), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: ColorConst.textgrey),
                    const SizedBox(width: 4),
                    Text('${winner.totalDays} $daysString', style: TextStyle(fontSize: 11, color: ColorConst.textgrey, fontWeight: FontWeight.w500)),
                    Container(width: 4, height: 4, margin: EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: ColorConst.textgrey.withOpacity(0.5), shape: BoxShape.circle)),
                    Icon(Icons.coffee_rounded, size: 12, color: ColorConst.textgrey),
                    const SizedBox(width: 4),
                    Text(winner.totalBreakHours, style: TextStyle(fontSize: 11, color: ColorConst.textgrey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Size size, DateTime selectedMonth, String locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24), 
            decoration: BoxDecoration(color: ColorConst.greyOpicityColor, shape: BoxShape.circle), 
            child: Icon(Icons.emoji_events_outlined, size: 48, color: ColorConst.textgrey.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          Text(noDataAvailableString, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ColorConst.black)),
          const SizedBox(height: 8),
          Text(
            '$noRecordsFoundForString\n${DateFormat('MMMM yyyy', locale).format(selectedMonth)}', 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 13, color: ColorConst.textgrey),
          ),
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