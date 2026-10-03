import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/controllers/visit_controller.dart';
import 'package:tax_hrm/models/visit/party_list_model.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';

class CreateVisitScreen extends StatefulWidget {
  const CreateVisitScreen({super.key});

  @override
  State<CreateVisitScreen> createState() => _CreateVisitScreenState();
}

class _CreateVisitScreenState extends State<CreateVisitScreen> {
  final VisitController controller = Get.put(VisitController());

  @override
  void initState() {
    super.initState();
    controller.resetForm();
  }

  InputDecoration _commonInputDecoration(String hint, BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ColorConst.themeColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildLabel(String text, BuildContext context, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 2.0),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  void _showEmployeeSearchSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _EmployeeSearchSheet(
          employees: controller.employeesList,
          selectedEmployees: controller.selectedAssignTo,
          onSelected: (employee) {
            controller.selectedAssignTo.clear();
            controller.selectedAssignTo.add(employee);
            Navigator.pop(ctx);
          },
          isDark: isDark,
        );
      },
    );
  }

  void _showPartySearchSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _PartySearchSheet(
          parties: controller.partyList,
          selectedParty: controller.selectedParty.value,
          onSelected: (party) {
            controller.isNewParty.value = false;
            controller.selectedParty.value = party;
            Navigator.pop(ctx);
          },
          onAddNewParty: () {
            controller.isNewParty.value = true;
            Navigator.pop(ctx);
          },
          isDark: isDark,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    safeAreaBgAndTextColor(context, safeAreaBgColor: ColorConst.themeColor);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: AppBar(
        title: const Text('Create Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: ColorConst.themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: ColorConst.themeColor),
                const SizedBox(height: 16),
                const Text('Loading parties...', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Visit Name
                _buildLabel('Visit Name', context, isRequired: true),
                TextField(
                  controller: controller.visitNameController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                  decoration: _commonInputDecoration('Enter visit title / name', context),
                ),
                const SizedBox(height: 12),

              // Smooth Animated Tab Bar Header
              _buildLabel('Select Party Option', context, isRequired: true),
              Container(
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.isNewParty.value = false,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: !controller.isNewParty.value
                                ? ColorConst.themeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !controller.isNewParty.value
                                ? [
                                    BoxShadow(
                                      color: ColorConst.themeColor.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 16,
                                color: !controller.isNewParty.value
                                    ? Colors.white
                                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Existing Party',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !controller.isNewParty.value
                                      ? Colors.white
                                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.isNewParty.value = true,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: controller.isNewParty.value
                                ? ColorConst.themeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: controller.isNewParty.value
                                ? [
                                    BoxShadow(
                                      color: ColorConst.themeColor.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_business_rounded,
                                size: 16,
                                color: controller.isNewParty.value
                                    ? Colors.white
                                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+ New Party',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: controller.isNewParty.value
                                      ? Colors.white
                                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Animated CrossFade for Content Transition
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: !controller.isNewParty.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _showPartySearchSheet(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.business_rounded, color: ColorConst.themeColor, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                controller.selectedParty.value?.partyName ?? 'Select Party Name',
                                style: TextStyle(
                                  color: controller.selectedParty.value != null
                                      ? Theme.of(context).textTheme.bodyLarge?.color
                                      : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                  fontSize: 13.5,
                                  fontWeight: controller.selectedParty.value != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.search_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 18),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 22),
                          ],
                        ),
                      ),
                    ),
                    if (controller.selectedParty.value?.partyAddress != null && controller.selectedParty.value!.partyAddress!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.grey.shade500, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                controller.selectedParty.value!.partyAddress!,
                                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Party Name', context, isRequired: true),
                    TextField(
                      controller: controller.newPartyNameController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13.5),
                      decoration: _commonInputDecoration('Enter new party name', context),
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Mobile Number', context, isRequired: true),
                    TextField(
                      controller: controller.newPartyMobileController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13.5),
                      decoration: _commonInputDecoration('Enter mobile number', context),
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Address 1', context),
                    TextField(
                      controller: controller.newPartyAdd1Controller,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13.5),
                      decoration: _commonInputDecoration('Enter address line 1', context),
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Address 2', context),
                    TextField(
                      controller: controller.newPartyAdd2Controller,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13.5),
                      decoration: _commonInputDecoration('Enter address line 2 (optional)', context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

                // Visit Time
                _buildLabel('Visit Date & Time', context, isRequired: true),
                InkWell(
                  onTap: () => controller.selectDateTime(context, controller.selectedVisitTime),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: ColorConst.themeColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.selectedVisitTime.value != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(controller.selectedVisitTime.value!)
                                : 'Select Visit Date & Time',
                            style: TextStyle(
                              color: controller.selectedVisitTime.value != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
                              fontSize: 13.5,
                              fontWeight: controller.selectedVisitTime.value != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.access_time_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Assign To (Admin only)
                if (curentUser != null && curentUser['Role'] == 'Admin') ...[
                  _buildLabel('Assign To Employee', context, isRequired: true),
                  InkWell(
                    onTap: () => _showEmployeeSearchSheet(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_rounded, color: ColorConst.themeColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Obx(() {
                              if (controller.selectedAssignTo.isEmpty) {
                                return Text(
                                  'Select Employee',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    fontSize: 13.5,
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: controller.selectedAssignTo.map((emp) {
                                  String empName = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
                                  if (empName.isEmpty) empName = 'Employee #${emp.id}';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ColorConst.themeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: ColorConst.themeColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person, size: 14, color: ColorConst.themeColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          empName,
                                          style: TextStyle(
                                            color: ColorConst.themeColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }),
                          ),
                          Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Remarks
                _buildLabel('Remarks / Notes', context),
                TextField(
                  controller: controller.remarksController,
                  maxLines: 3,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13.5),
                  decoration: _commonInputDecoration('Enter visit remarks or notes (optional)...', context),
                ),
                const SizedBox(height: 12),
                // Attached Documents
                _buildLabel('Attached Documents (Max 3)', context),
                Obx(() {
                  bool isDark = Theme.of(context).brightness == Brightness.dark;
                  int maxDisplay = 3;
                  List<dynamic> allDocs = controller.attachedDocuments;
                  List<dynamic> displayDocs = allDocs.take(maxDisplay).toList();

                  return LayoutBuilder(
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
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
                                        image: ['jpg', 'jpeg', 'png', 'gif'].contains(displayDocs[i].path.split('.').last.toLowerCase())
                                            ? DecorationImage(image: FileImage(displayDocs[i]), fit: BoxFit.cover)
                                            : null,
                                      ),
                                      child: !['jpg', 'jpeg', 'png', 'gif'].contains(displayDocs[i].path.split('.').last.toLowerCase())
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    ['mp4', 'mov'].contains(displayDocs[i].path.split('.').last.toLowerCase()) ? Icons.play_circle_fill_rounded : Icons.insert_drive_file_rounded,
                                                    color: ['mp4', 'mov'].contains(displayDocs[i].path.split('.').last.toLowerCase()) ? Colors.purple.shade400 : Colors.blue.shade400,
                                                    size: 32,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(displayDocs[i].path.split('.').last.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                                ],
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: GestureDetector(
                                        onTap: () => controller.attachedDocuments.remove(displayDocs[i]),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                          child: const Icon(Icons.cancel, color: Colors.red, size: 22),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < 2 || displayDocs.length < 3) SizedBox(width: spacing),
                            ],
                            if (displayDocs.length < 3)
                              Expanded(
                                child: InkWell(
                                  onTap: () => controller.pickAttachment(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ColorConst.themeColor.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: ColorConst.themeColor.withOpacity(0.25), width: 1.5, style: BorderStyle.solid),
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
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          );
      }),
      bottomNavigationBar: Obx(() => Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConst.themeColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: controller.isSubmitting.value ? null : () => controller.submitVisit(context),
            child: controller.isSubmitting.value
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CREATE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ),
      )),
    );
  }
}

// Searchable Party Bottom Sheet
class _PartySearchSheet extends StatefulWidget {
  final List<PartyListModel> parties;
  final PartyListModel? selectedParty;
  final ValueChanged<PartyListModel> onSelected;
  final VoidCallback onAddNewParty;
  final bool isDark;

  const _PartySearchSheet({
    required this.parties,
    required this.selectedParty,
    required this.onSelected,
    required this.onAddNewParty,
    required this.isDark,
  });

  @override
  State<_PartySearchSheet> createState() => _PartySearchSheetState();
}

class _PartySearchSheetState extends State<_PartySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredParties = widget.parties.where((party) {
      final name = (party.partyName ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Handle Bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Party',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              autofocus: true,
              style: TextStyle(fontSize: 13.5, color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search party by name...',
                hintStyle: TextStyle(fontSize: 13, color: widget.isDark ? Colors.grey[400] : Colors.grey[500]),
                prefixIcon: Icon(Icons.search, size: 20, color: ColorConst.themeColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: widget.isDark ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Filtered Party List
            Expanded(
              child: filteredParties.isEmpty
                  ? const Center(
                      child: Text('No parties found', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  : ListView.separated(
                      itemCount: filteredParties.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                      itemBuilder: (context, index) {
                        final party = filteredParties[index];
                        final isSelected = widget.selectedParty?.partyId == party.partyId;

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isSelected
                                ? ColorConst.themeColor
                                : ColorConst.themeColor.withOpacity(0.1),
                            child: Icon(
                              Icons.business_rounded,
                              size: 16,
                              color: isSelected ? Colors.white : ColorConst.themeColor,
                            ),
                          ),
                          title: Text(
                            party.partyName ?? 'Unknown Party',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13.5,
                              color: isSelected ? ColorConst.themeColor : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: ColorConst.themeColor, size: 20)
                              : null,
                          onTap: () => widget.onSelected(party),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),

            // Add Other / New Party Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConst.themeColor,
                  side: BorderSide(color: ColorConst.themeColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: widget.onAddNewParty,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text(
                  '+ Add Other / New Party',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeSearchSheet extends StatefulWidget {
  final List<Employeelists> employees;
  final RxList<Employeelists> selectedEmployees;
  final ValueChanged<Employeelists> onSelected;
  final bool isDark;

  const _EmployeeSearchSheet({
    required this.employees,
    required this.selectedEmployees,
    required this.onSelected,
    required this.isDark,
  });

  @override
  State<_EmployeeSearchSheet> createState() => _EmployeeSearchSheetState();
}

class _EmployeeSearchSheetState extends State<_EmployeeSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = widget.employees.where((emp) {
      final name = ('${emp.firstName ?? ''} ${emp.lastName ?? ''}').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Handle Bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Employee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              autofocus: true,
              style: TextStyle(fontSize: 13.5, color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search employee by name...',
                hintStyle: TextStyle(fontSize: 13, color: widget.isDark ? Colors.grey[400] : Colors.grey[500]),
                prefixIcon: Icon(Icons.search, size: 20, color: ColorConst.themeColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: widget.isDark ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Filtered Employee List
            Expanded(
              child: filteredEmployees.isEmpty
                  ? const Center(
                      child: Text('No employees found', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  : ListView.separated(
                      itemCount: filteredEmployees.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                      itemBuilder: (context, index) {
                        final emp = filteredEmployees[index];
                        return Obx(() {
                          final isSelected = widget.selectedEmployees.contains(emp);
                          String empName = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
                          
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: isSelected
                                  ? ColorConst.themeColor
                                  : ColorConst.themeColor.withOpacity(0.1),
                              child: Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: isSelected ? Colors.white : ColorConst.themeColor,
                              ),
                            ),
                            title: Text(
                              empName.isNotEmpty ? empName : 'Employee #${emp.id}',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13.5,
                                color: isSelected ? ColorConst.themeColor : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: ColorConst.themeColor, size: 20)
                                : null,
                            onTap: () => widget.onSelected(emp),
                          );
                        });
                      },
                    ),
            ),
            // Done button removed since it auto-closes on single selection
          ],
        ),
      ),
    );
  }
}
