// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(' ', ''),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        _showCopySnackBar('Could not launch phone dialer. Number copied to clipboard!', phoneNumber);
      }
    }
  }

  Future<void> _openWebsite(String urlString) async {
    final Uri url = Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showCopySnackBar('Could not open browser. Website copied to clipboard!', urlString);
      }
    }
  }

  Future<void> _openLocationMap(String address) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    final Uri geoUrl = Uri.parse('geo:0,0?q=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else {
        if (mounted) {
          _showCopySnackBar('Could not open maps. Address copied to clipboard!', address);
        }
      }
    } catch (e) {
      if (mounted) {
        _showCopySnackBar('Could not open maps. Address copied to clipboard!', address);
      }
    }
  }

  void _showCopySnackBar(String message, String copyText) {
    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: ColorConst.themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNumberActionSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Number to Call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : ColorConst.black,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call_rounded, color: ColorConst.themeColor, size: 22),
                  ),
                  title: Text(
                    '95100 56789',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : ColorConst.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _makePhoneCall('9510056789');
                  },
                ),
                Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call_rounded, color: ColorConst.themeColor, size: 22),
                  ),
                  title: Text(
                    '95101 56789',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : ColorConst.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _makePhoneCall('9510156789');
                  },
                ),
                Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.copy_rounded, color: ColorConst.themeColor, size: 22),
                  ),
                  title: Text(
                    'Copy Both Numbers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : ColorConst.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCopySnackBar('Numbers copied to clipboard!', '95100 56789 / 95101 56789');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDark = ColorConst.isDark;

    return WillPopScope(
      onWillPop: () async {
        safeAreaBgAndTextColor(
          context,
          safeAreaBgColor: ColorConst.themeColor,
          safeAreaBrightness: Brightness.light,
        );
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: ColorConst.themeColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              safeAreaBgAndTextColor(
                context,
                safeAreaBgColor: ColorConst.themeColor,
                safeAreaBrightness: Brightness.light,
              );
              Navigator.pop(context);
            },
          ),
          title: Text(
            contactUsString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Top Header Illustration Area matching the reference design
                _buildTopHeaderIllustration(size, isDark),
                
                const SizedBox(height: 20),

                // Contact Cards Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // 1. Contact Number Card
                      _buildContactCard(
                        isDark: isDark,
                        badgeColor: ColorConst.themeColor,
                        icon: Icons.phone_rounded,
                        title: 'Contact Number',
                        value: '95100 56789  /  95101 56789',
                        onTap: () => _showNumberActionSheet(context, isDark),
                        onLongPress: () => _showCopySnackBar('Contact numbers copied to clipboard!', '95100 56789 / 95101 56789'),
                      ),

                      const SizedBox(height: 14),

                      // 2. Website Card
                      _buildContactCard(
                        isDark: isDark,
                        badgeColor: ColorConst.themeColor,
                        icon: Icons.language_rounded,
                        title: 'Website',
                        value: 'www.i-tax.in',
                        onTap: () => _openWebsite('www.i-tax.in'),
                        onLongPress: () => _showCopySnackBar('Website copied to clipboard!', 'www.i-tax.in'),
                      ),

                      const SizedBox(height: 14),

                      // 3. Location Card
                      _buildContactCard(
                        isDark: isDark,
                        badgeColor: ColorConst.themeColor,
                        icon: Icons.location_on_rounded,
                        title: 'Location',
                        value: '601-602, SUBH SQUARE, opp. Modh Patni wadi, Lal Darwaja, Surat, Gujarat 395003',
                        onTap: () => _openLocationMap('601-602, SUBH SQUARE, opp. Modh Patni wadi, Lal Darwaja, Surat, Gujarat 395003'),
                        onLongPress: () => _showCopySnackBar('Address copied to clipboard!', '601-602, SUBH SQUARE, opp. Modh Patni wadi, Lal Darwaja, Surat, Gujarat 395003'),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Contact Card Builder matching exact reference design ──
  Widget _buildContactCard({
    required bool isDark,
    required Color badgeColor,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Icon Badge
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFA9A9A9) : const Color(0xFF8D8D8D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header Illustration Area matching reference image ──
  Widget _buildTopHeaderIllustration(Size size, bool isDark) {
    return Container(
      width: double.infinity,
      height: size.height * 0.35,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? ColorConst.themeColor.withOpacity(0.15) : ColorConst.themeColor.withOpacity(0.08),
      ),
      child: Center(
        child: Image.asset(
          isDark ? 'assets/images/contact_us_dark.png' : 'assets/images/contact_us_light.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.support_agent_rounded,
              size: size.height * 0.18,
              color: ColorConst.themeColor,
            );
          },
        ),
      ),
    );
  }
}
