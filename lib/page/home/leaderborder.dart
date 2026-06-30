// ignore_for_file: unnecessary_underscores

// ── Model ────────────────────────────────────────────────────────────────────
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/page/home/leaderborder_dashbord.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/navigation.dart';

class WinnerModel {
  final String name;
  final String hours;
  final int totaldays;
  final String? avatarUrl;
  final int rank;

  const WinnerModel({
    required this.name,
    required this.hours,
    required this.totaldays,
    this.avatarUrl,
    required this.rank,
  });

  String get initials {
    if (name == "" || name.isEmpty || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}

// ── Main Widget ──────────────────────────────────────────────────────────────
class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({super.key});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      homeProvider.getTopLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final homeProvider = Provider.of<HomeProvider>(context);

    return Container(
      margin: EdgeInsets.all(size.width * 0.03),
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.width * 0.05,
      ),
      decoration: BoxDecoration(
        color: ColorConst.white, // Matches the app's clean card design
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConst.textBorder.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConst.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: homeProvider.isLeaderboardLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorConst.themeColor,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(size, homeProvider),
                SizedBox(height: size.height * 0.025),
                if (homeProvider.setHrmTopRecord == null ||
                    homeProvider.setHrmTopRecord!.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: size.height * 0.04),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.leaderboard_rounded,
                            size: size.width * 0.12,
                            color: ColorConst.textgrey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No data available for ${homeProvider.getLeaderboardMonthName()}',
                            style: TextStyle(
                              color: ColorConst.textgrey.withOpacity(0.7),
                              fontSize: size.width * 0.038,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildPodiumSection(size, homeProvider),
              ],
            ),
    );
  }

  // ── Header with month navigation ─────────────────────────────────────────
  Widget _buildHeader(Size size, HomeProvider homeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: size.width * 0.046,
                fontWeight: FontWeight.bold,
                color: ColorConst.settingTextColors,
              ),
            ),
            const SizedBox(height: 6),
            // Month selector
            Container(
              decoration: BoxDecoration(
                color: ColorConst.greyOpicityColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await homeProvider.previousLeaderboardMonth();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: ColorConst.settingIconsColors.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Text(
                    homeProvider.getLeaderboardMonthName(),
                    style: TextStyle(
                      fontSize: size.width * 0.028,
                      color: ColorConst.settingTextColors,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await homeProvider.nextLeaderboardMonth();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: (homeProvider.leaderboardSelectedMonth.year ==
                                    DateTime.now().year &&
                                homeProvider.leaderboardSelectedMonth.month ==
                                    DateTime.now().month)
                            ? ColorConst.settingIconsColors.withOpacity(0.2)
                            : ColorConst.settingIconsColors.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // See All button
        GestureDetector(
          onTap: () {
            nextScreen(
              context,
              LeaderboardDetailPage(
                initialMonth: homeProvider.leaderboardSelectedMonth,
                initialRecords: homeProvider.setHrmTopRecord,
              ),
              onthenValue: (value) {},
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.035,
              vertical: size.height * 0.008,
            ),
            decoration: BoxDecoration(
              color: ColorConst.themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConst.themeColor.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    color: ColorConst.themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.032,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: size.width * 0.026,
                  color: ColorConst.themeColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Podium Section ───────────────────────────────────────────────────────
  Widget _buildPodiumSection(Size size, HomeProvider homeProvider) {
    // Get winners from provider
    final firstPlaceWinners = homeProvider.convertToWinnerModels(
        homeProvider.setHrmTopRecord, 1);
    final secondPlaceWinners = homeProvider.convertToWinnerModels(
        homeProvider.setHrmTopRecord, 2);
    final thirdPlaceWinners = homeProvider.convertToWinnerModels(
        homeProvider.setHrmTopRecord, 3);

    // Heights
    final double base = size.height * 0.01;
    final double h1 = base + size.height * 0.13; // 1st – tallest
    final double h2 = base + size.height * 0.095; // 2nd
    final double h3 = base + size.height * 0.075; // 3rd

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place – Theme Color Blue
        Expanded(
          child: _PodiumColumn(
            winners: secondPlaceWinners,
            rank: 2,
            rankColor: ColorConst.themeColor, // All columns use same theme color (#1864EC)
            podiumHeight: h2,
            isWinner: false,
          ),
        ),
        SizedBox(width: size.width * 0.03),
        // 1st Place – Theme Color Blue (Center, tallest)
        Expanded(
          child: _PodiumColumn(
            winners: firstPlaceWinners,
            rank: 1,
            rankColor: ColorConst.themeColor, // All columns use same theme color (#1864EC)
            podiumHeight: h1,
            isWinner: true,
          ),
        ),
        SizedBox(width: size.width * 0.03),
        // 3rd Place – Theme Color Blue
        Expanded(
          child: _PodiumColumn(
            winners: thirdPlaceWinners,
            rank: 3,
            rankColor: ColorConst.themeColor, // All columns use same theme color (#1864EC)
            podiumHeight: h3,
            isWinner: false,
          ),
        ),
      ],
    );
  }
}

// ── Single Podium Column ─────────────────────────────────────────────────────
class _PodiumColumn extends StatelessWidget {
  final List<WinnerModel> winners;
  final int rank;
  final Color rankColor;
  final double podiumHeight;
  final bool isWinner;

  const _PodiumColumn({
    required this.winners,
    required this.rank,
    required this.rankColor,
    required this.podiumHeight,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${winners.hashCode}_$rank'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (rank * 100)),
      curve: Curves.decelerate,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animValue)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatars
                _AvatarStack(
                  winners: winners,
                  rankColor: rankColor,
                  isWinner: isWinner,
                  size: size,
                ),

                const SizedBox(height: 10),

                // Podium Card
                Container(
                  width: double.infinity,
                  height: podiumHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rankColor.withOpacity(0.25),
                      width: isWinner ? 1.5 : 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        rankColor.withOpacity(0.08),
                        ColorConst.white,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConst.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: size.width * 0.075,
                      height: size.width * 0.075,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rankColor.withOpacity(0.08),
                        border: Border.all(
                          color: rankColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Avatar Stack ─────────────────────────────────────────────────────────────
class _AvatarStack extends StatelessWidget {
  final List<WinnerModel> winners;
  final Color rankColor;
  final bool isWinner;
  final Size size;

  const _AvatarStack({
    required this.winners,
    required this.rankColor,
    required this.isWinner,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    const int maxVisible = 3;
    final int visible = math.min(winners.length, maxVisible);
    final int extra = winners.length - maxVisible;

    final double avatarSize = isWinner ? size.width * 0.125 : size.width * 0.105;
    final double overlap = avatarSize * 0.35;

    // Total stack width
    final double stackWidth =
        avatarSize + (visible - 1) * (avatarSize - overlap);

    // Get hours for display
    final String displayHours = winners.isNotEmpty ? winners[0].hours : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: stackWidth,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < visible; i++)
                Positioned(
                  left: i * (avatarSize - overlap),
                  child: _buildSingleAvatar(
                    winner: winners[i],
                    size: avatarSize,
                    isLast: i == visible - 1,
                    extraCount: (i == visible - 1 && extra > 0) ? extra : 0,
                    index: i,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildNameAndHoursLabel(displayHours),
      ],
    );
  }

  Widget _buildSingleAvatar({
    required WinnerModel winner,
    required double size,
    required bool isLast,
    required int extraCount,
    required int index,
  }) {
    final List<Color> bgPalette = [
      ColorConst.greyOpicityColor,
      ColorConst.white,
    ];
    final Color bg = bgPalette[index % bgPalette.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(
          color: rankColor,
          width: isWinner ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConst.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          children: [
            winner.avatarUrl != null
                ? Image.network(
                    winner.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _initialsWidget(winner, size),
                  )
                : _initialsWidget(winner, size),
            if (isLast && extraCount > 0)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Text(
                    '+$extraCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget(WinnerModel w, double size) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rankColor.withOpacity(0.12),
            rankColor.withOpacity(0.35),
          ],
        ),
      ),
      child: Text(
        w.initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: ColorConst.settingTextColors,
        ),
      ),
    );
  }

  Widget _buildNameAndHoursLabel(String hours) {
    if (winners.isEmpty) {
      return const SizedBox.shrink();
    }

    String namesLabel;
    if (winners.length == 1) {
      namesLabel = winners[0].name.split(' ')[0];
    } else if (winners.length == 2) {
      namesLabel =
          '${winners[0].name.split(' ')[0]} & ${winners[1].name.split(' ')[0]}';
    } else {
      namesLabel =
          '${winners[0].name.split(' ')[0]} +${winners.length - 1}';
    }

    return Column(
      children: [
        Text(
          namesLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width * 0.028,
            fontWeight: FontWeight.bold,
            color: ColorConst.settingTextColors,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            hours,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.width * 0.022,
              fontWeight: FontWeight.bold,
              color: rankColor,
            ),
          ),
        ),
      ],
    );
  }
}