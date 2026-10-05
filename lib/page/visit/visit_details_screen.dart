import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/api/visit_api.dart';
import 'package:tax_hrm/models/visit/visit_detail_model.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
class VisitDetailsScreen extends StatefulWidget {
  final String visitUkeyId;
  final String companyId;

  const VisitDetailsScreen({
    super.key,
    required this.visitUkeyId,
    required this.companyId,
  });

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  final VisitApis _visitApis = VisitApis();
  bool _isLoading = true;
  bool _isDeleting = false;
  VisitDetailModel? _visitData;
  String? _errorMessage;
  late String _visitorAddress = locatingString;

  @override
  void initState() {
    super.initState();
    _fetchVisitDetails();
  }

  Future<void> _fetchVisitDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      var response = await _visitApis.getVisitById(widget.companyId, widget.visitUkeyId);
      if (mounted) {
        setState(() {
          _visitData = response;
          _isLoading = false;
        });
        _fetchAddress();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAddress() async {
    if (_visitData?.imgLatitude != null && _visitData?.imgLogitude != null) {
      try {
        double lat = double.parse(_visitData!.imgLatitude!);
        double lng = double.parse(_visitData!.imgLogitude!);
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          if (mounted) {
            setState(() {
              _visitorAddress = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}'.replaceAll(RegExp(r',\s*,'), ',').replaceAll(RegExp(r'^,\s*|\s*,\s*$'), '');
              if (_visitorAddress.isEmpty) _visitorAddress = addressNotFullyFoundString;
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => _visitorAddress = '');
      }
    } else {
      if (mounted) setState(() => _visitorAddress = '');
    }
  }

  Future<void> _deleteVisit() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(deleteVisitString),
          ],
        ),
        content: Text(deleteVisitConfirmString),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelString),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(deleteString),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() { _isDeleting = true; });
    try {
      await _visitApis.deleteVisit(widget.visitUkeyId);
      showtoastmessage(visitDeletedSuccessString);
      if (mounted) Navigator.pop(context, true); // Return true to refresh list
    } catch (e) {
      showtoastmessage(failedToDeleteVisitString);
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  Future<void> _addAttachment() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(addAttachmentString, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
              title: Text(cameraString),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (photo != null) _uploadDocument(photo.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.purple),
              title: Text(galleryString),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) _uploadDocument(image.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.orange),
              title: Text(documentFileString),
              onTap: () async {
                Navigator.pop(ctx);
                FilePickerResult? result = await FilePicker.pickFiles();
                if (result != null && result.files.single.path != null) {
                  _uploadDocument(result.files.single.path!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(String path) async {
    setState(() => _isLoading = true);
    try {
      await _visitApis.createTaskFileUpload(
        filename: [path],
        cguid: widget.visitUkeyId,
        companyId: widget.companyId,
        partyId: _visitData?.partyId?.toString() ?? '0',
        category: 'VisitDoc',
      );
      showtoastmessage(documentUploadedSuccessString);
      _fetchVisitDetails();
    } catch (e) {
      showtoastmessage(uploadFailedString);
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate == 'null') return naString;
    try {
      DateTime parsed = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    } catch (_) {
      return rawDate.replaceFirst('T', '  ');
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'complete':
      case 'completed':
        return const Color(0xFF00C853);
      case 'in progress':
      case 'inprogress':
        return const Color(0xFFFF9100);
      case 'pending':
        return const Color(0xFF2962FF);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'complete':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'in progress':
      case 'inprogress':
        return Icons.timelapse_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(viewImageString, style: const TextStyle(color: Colors.white, fontSize: 17)),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: imageUrl,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                      SizedBox(height: 12),
                      Text(unableToLoadImageString, style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchDocumentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showtoastmessage(couldNotOpenDocumentString);
      }
    } catch (e) {
      showtoastmessage(errorOpeningDocumentString);
    }
  }

  String _formatStartEndTime(String? startStr, String? endStr, String? schedStr) {
    if (startStr == null || startStr.isEmpty || startStr == 'null') return naString;
    try {
      DateTime start = DateTime.parse(startStr);
      DateTime? end = (endStr != null && endStr.isNotEmpty && endStr != 'null') ? DateTime.parse(endStr) : null;
      DateTime? sched = (schedStr != null && schedStr.isNotEmpty && schedStr != 'null') ? DateTime.parse(schedStr) : null;

      bool showStartDate = true;
      if (sched != null && start.year == sched.year && start.month == sched.month && start.day == sched.day) {
        showStartDate = false;
      }
      
      String startText = showStartDate ? DateFormat('dd MMM, hh:mm a').format(start) : DateFormat('hh:mm a').format(start);
      
      if (end == null) {
        return startText;
      }
      
      bool showEndDate = true;
      if (end.year == start.year && end.month == start.month && end.day == start.day) {
        showEndDate = false;
      }
      
      String endText = showEndDate ? DateFormat('dd MMM, hh:mm a').format(end) : DateFormat('hh:mm a').format(end);
      
      return '$startText  -  $endText';
    } catch (_) {
      return '${startStr.replaceAll('T', ' ')}  -  ${endStr?.replaceAll('T', ' ') ?? ''}';
    }
  }

  String _calculateDuration(String? start, String? end) {
    if (start == null || end == null || start.isEmpty || end.isEmpty || start == 'null' || end == 'null') return '';
    try {
      DateTime s = DateTime.parse(start);
      DateTime e = DateTime.parse(end);
      Duration d = e.difference(s);
      int h = d.inHours;
      int m = d.inMinutes.remainder(60);
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    } catch (_) {
      return '';
    }
  }

  Widget _buildCleanRow(String label, String value) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text(':', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 24),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: ColorConst.themeColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String? status = _visitData?.visitStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _visitData?.visitName ?? visitDetailString,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorConst.themeColor.withOpacity(0.1),
                border: Border.all(color: ColorConst.themeColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status?.toUpperCase() ?? pendingUpperString,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$scheduledDateString${_formatDate(_visitData?.visitTime)}',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ],
    );
  }

  void _showAllDocsSheet(List<VisitDocument> allDocs) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(allDocumentsString, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _addAttachment();
                    },
                    icon: Icon(Icons.add, color: ColorConst.themeColor, size: 18),
                    label: Text(addNewString, style: TextStyle(color: ColorConst.themeColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: allDocs.length,
                itemBuilder: (c, i) {
                  var doc = allDocs[i];
                  String ext = doc.fileName?.split('.').last.toLowerCase() ?? '';
                  String url = doc.documentUrl ?? '';
                  String name = doc.originalFileName ?? doc.fileName ?? '$documentTextString${i + 1}';
                  bool isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
                  bool isVideo = ['mp4', 'mov'].contains(ext);
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: isImage
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: 40, height: 40, fit: BoxFit.cover))
                        : Icon(isVideo ? Icons.play_circle_fill_rounded : Icons.insert_drive_file_rounded, size: 40, color: Colors.grey),
                    title: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    onTap: () {
                      if (isImage) _openFullScreenImage(context, url);
                      else if (isVideo) Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenVideoPlayer(videoUrl: url)));
                      else _launchDocumentUrl(url);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(BuildContext context, VisitDocument doc, bool isLastAndMore, List<VisitDocument> allDocs, int maxDisplay) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String ext = doc.fileName?.split('.').last.toLowerCase() ?? '';
    String url = doc.documentUrl ?? '';
    bool isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
    bool isVideo = ['mp4', 'mov'].contains(ext);
    
    return GestureDetector(
      onTap: () {
        if (isLastAndMore) {
          _showAllDocsSheet(allDocs);
        } else {
          if (isImage) _openFullScreenImage(context, url);
          else if (isVideo) Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenVideoPlayer(videoUrl: url)));
          else _launchDocumentUrl(url);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
          image: isImage ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!isImage)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isVideo ? Icons.play_circle_fill_rounded : Icons.insert_drive_file_rounded, color: isVideo ? Colors.purple.shade400 : Colors.blue.shade400, size: 32),
                  const SizedBox(height: 6),
                  Text(ext.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ],
              ),
            if (isLastAndMore)
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(11)),
                child: Center(child: Text('+${allDocs.length - maxDisplay}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: _addAttachment,
      child: Container(
        decoration: BoxDecoration(
          color: ColorConst.themeColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConst.themeColor.withOpacity(0.25), width: 1, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: ColorConst.themeColor, size: 30),
            const SizedBox(height: 6),
            Text('Add File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConst.themeColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsGrid(BuildContext context) {
    List<VisitDocument> allDocs = [];
    if (_visitData?.documents != null && _visitData!.documents!.isNotEmpty) {
      for (var doc in _visitData!.documents!) {
        String? docUrl = doc.documentUrl;
        if ((docUrl == null || docUrl.isEmpty) && doc.fileName != null) {
           docUrl = '${apibaseurl}CRM/CompanyData/Uploads/${widget.companyId}/${doc.fileName}';
        }
        allDocs.add(VisitDocument(fileName: doc.fileName, originalFileName: doc.originalFileName, documentUrl: docUrl));
      }
    }
    
    int maxDisplay = 3;
    bool hasMore = allDocs.length > maxDisplay;
    List<VisitDocument> displayDocs = allDocs.take(maxDisplay).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(attachmentsString),
        LayoutBuilder(
          builder: (context, constraints) {
            double spacing = 12;
            double itemWidth = (constraints.maxWidth - (2 * spacing)) / 3;
            double rowHeight = itemWidth;

            return SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  for (int i = 0; i < displayDocs.length; i++) ...[
                    SizedBox(
                      width: itemWidth,
                      child: _buildDocItem(context, displayDocs[i], i == maxDisplay - 1 && hasMore, allDocs, maxDisplay),
                    ),
                    if (i < 2 || displayDocs.length < 3) SizedBox(width: spacing),
                  ],
                  if (displayDocs.length < 3)
                    Expanded(
                      child: _buildAddButton(context),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddRemarkDialog() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    TextEditingController remarkController = TextEditingController(text: _visitData?.remarks ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          ((_visitData?.remarks ?? '').trim().isEmpty) ? addRemarkString : editRemarkString,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: TextField(
          controller: remarkController,
          maxLines: 4,
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: enterRemarkHintString,
            hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ColorConst.themeColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelString, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConst.themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateRemark(remarkController.text.trim());
            },
            child: Text(saveString, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRemark(String newRemark) async {
    if (_visitData == null) return;
    
    setState(() => _isLoading = true);
    try {
      developer.log('--- Start _updateRemark ---', name: 'VisitDetails');
      Map<String, dynamic> updateData = _visitData!.toJson();
      developer.log('Base _visitData toJson: $updateData', name: 'VisitDetails');
      
      Map<String, dynamic> payload = {
        "CompanyId": updateData['CompanyId'] ?? widget.companyId,
        "VisitUkeyId": updateData['VisitUkeyId'],
        "VisitName": updateData['VisitName'],
        "VisitTime": updateData['VisitTime'],
        "StartTime": updateData['StartTime'],
        "EndTime": updateData['EndTime'],
        "VisitStatus": updateData['VisitStatus'],
        "ImgLogitude": updateData['ImgLogitude'],
        "ImgLatitude": updateData['ImgLatitude'],
        "Remarks": newRemark,
        "VisitAssignTo": updateData['VisitAssignTo'],
        "PartyId": updateData['PartyId'] ?? 0,
        "PartyName": updateData['PartyName'],
      };

      developer.log('Payload being sent for remark update: $payload', name: 'VisitDetails');
      await VisitApis().createUpdateVisit(payload, flag: 'U');
      
      developer.log('Remark update successful!', name: 'VisitDetails');
      showtoastmessage(remarkSavedSuccessString);
      await _fetchVisitDetails();
    } catch (e, stackTrace) {
      developer.log('Exception in _updateRemark: $e', name: 'VisitDetails', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      showtoastmessage('$failedToSaveRemarkString$e');
    }
  }

  Widget _buildVisitorPunchClean(BuildContext context) {
    if (_visitData?.fileName == null || _visitData!.fileName!.isEmpty) return const SizedBox.shrink();
    String imageUrl = '${apibaseurl}CRM/CompanyData/Uploads/${widget.companyId}/${_visitData!.fileName}';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openFullScreenImage(context, imageUrl),
            child: Hero(
              tag: imageUrl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(width:70,height:70,color:Colors.grey.shade300)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visitorPunchString, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                if (_visitorAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: ColorConst.themeColor),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_visitorAddress, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    safeAreaBgAndTextColor(context, safeAreaBgColor: ColorConst.themeColor);
    
    bool hasStartTime = _visitData?.startTime != null && _visitData!.startTime!.isNotEmpty && _visitData!.startTime != 'null';
    bool hasEndTime = _visitData?.endTime != null && _visitData!.endTime!.isNotEmpty && _visitData!.endTime != 'null';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(visitDetailsString, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: ColorConst.themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (!_isLoading && _visitData != null && curentUser != null && (curentUser['Role'] == 'Admin' || curentUser['role'] == 'Admin'))
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: 'Delete Visit',
              onPressed: _isDeleting ? null : _deleteVisit,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: ColorConst.themeColor))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(failedToLoadVisitDetailsString, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const SizedBox(height: 6),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: ColorConst.themeColor, foregroundColor: Colors.white),
                          onPressed: _fetchVisitDetails,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(retryString),
                        ),
                      ],
                    ),
                  ),
                )
              : _visitData == null
                  ? Center(child: Text(noDetailsFoundString, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))
                  : RefreshIndicator(
                      onRefresh: _fetchVisitDetails,
                      color: ColorConst.themeColor,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        children: [
                          _buildHeader(context),
                          
                          _buildVisitorPunchClean(context),
                          
                          _buildSectionTitle(partyInformationString),
                          _buildCleanRow(nameString, _visitData?.partyName ?? naString),
                          if ((_visitData?.mobile1 != null && _visitData!.mobile1!.isNotEmpty) || (_visitData?.mobile2 != null && _visitData!.mobile2!.isNotEmpty))
                            _buildCleanRow(mobileNoString, [
                              if (_visitData?.mobile1 != null && _visitData!.mobile1!.isNotEmpty) _visitData?.mobile1,
                              if (_visitData?.mobile2 != null && _visitData!.mobile2!.isNotEmpty) _visitData?.mobile2
                            ].join(', ')),
                          if (_visitData?.partyAddress != null && _visitData!.partyAddress!.trim().isNotEmpty && _visitData!.partyAddress!.toLowerCase() != 'null')
                            _buildCleanRow(addressString, _visitData!.partyAddress!),
                          
                          _buildSectionTitle(visitorDetailsString),
                          _buildCleanRow(assignedToString, _visitData?.assigntoName ?? naString),
                          
                          if (hasStartTime || hasEndTime) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(timeString, style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Text(':', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatStartEndTime(_visitData?.startTime, _visitData?.endTime, _visitData?.visitTime),
                                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                                        ),
                                        if (_calculateDuration(_visitData?.startTime, _visitData?.endTime).isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '$durationTextString${_calculateDuration(_visitData?.startTime, _visitData?.endTime)}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade600),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          InkWell(
                            onTap: _showAddRemarkDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ((_visitData?.remarks ?? '').toString().trim().isNotEmpty)
                                        ? _buildCleanRow(remarksString, _visitData!.remarks!)
                                        : Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Text(noRemarksAddedString, style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 13.5)),
                                          ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      ((_visitData?.remarks ?? '').toString().trim().isNotEmpty) ? Icons.edit_note_rounded : Icons.add_comment_rounded,
                                      color: ColorConst.themeColor,
                                      size: 22,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: ((_visitData?.remarks ?? '').toString().trim().isNotEmpty) ? editRemarkString : addRemarkString,
                                    onPressed: _showAddRemarkDialog,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          _buildDocumentsGrid(context),
                        ],
                      ),
                    ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const FullScreenVideoPlayer({super.key, required this.videoUrl});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(viewVideoString, style: const TextStyle(color: Colors.white, fontSize: 17)),
      ),
      body: Center(
        child: _hasError
            ? Text(errorLoadingVideoString, style: const TextStyle(color: Colors.white))
            : _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        VideoProgressIndicator(_controller, allowScrubbing: true),
                        Center(
                          child: IconButton(
                            icon: Icon(
                              _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.white.withOpacity(0.7),
                              size: 64,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying ? _controller.pause() : _controller.play();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
