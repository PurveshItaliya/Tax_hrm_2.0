import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tax_hrm/api/companiapi.dart';
import 'package:tax_hrm/api/notification_api.dart';
import 'package:tax_hrm/models/company/getallcompany.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/empprovider.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _branchIdController = TextEditingController();
  
  // States
  String? _selectedScreen;
  DateTime? _scheduledDateTime;
  bool _isSending = false;
  
  // Dropdown Screen Options
  final List<Map<String, String>> _screenOptions = [
    {'value': 'attendance', 'label': 'Attendance Page'},
    {'value': 'leave', 'label': 'Leave Page'},
    {'value': 'home', 'label': 'Home Page'},
    {'value': 'setting', 'label': 'Setting Page'},
    {'value': 'profile', 'label': 'Profile Page'},
    {'value': 'salary_payslip', 'label': 'Payslip Page'},
    {'value': 'holidays', 'label': 'Holidays Page'},
    {'value': 'notes', 'label': 'Notes Page'},
    {'value': 'document', 'label': 'Documents Page'},
  ];

  // Topics Multi-selection state
  final Set<String> _selectedPredefinedTopics = {};
  final Set<int> _selectedCompanyIds = {};
  final Set<int> _selectedEmployeeIds = {};
  
  List<GetCompanyData> _companies = [];
  bool _isLoadingCompanies = false;
  String _companySearchQuery = '';
  String _employeeSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingCompanies = true;
    });

    // 1. Fetch companies
    try {
      final companies = await CompanyDataApis().getCompanyDataList();
      if (companies != null && companies is List<GetCompanyData>) {
        setState(() {
          _companies = companies;
        });
      }
    } catch (e) {
      print('[AdminNotifications] Error fetching companies: $e');
    } finally {
      setState(() {
        _isLoadingCompanies = false;
      });
    }

    // 2. Fetch employees
    try {
      final employeeProvider = Provider.of<EmployeMastServices>(context, listen: false);
      await employeeProvider.getemployee();
    } catch (e) {
      print('[AdminNotifications] Error fetching employees: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    _branchIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConst.themeColor,
              onPrimary: Colors.white,
              onSurface: ColorConst.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDateTime ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _sanitizeTopic(String topic) {
    return topic.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Build target topics list
    final List<String> targetTopics = [];
    
    // Add predefined topics
    targetTopics.addAll(_selectedPredefinedTopics);
    
    // Add company topics
    for (final companyId in _selectedCompanyIds) {
      targetTopics.add('company_$companyId');
    }
    
    // Add branch topics
    if (_branchIdController.text.trim().isNotEmpty) {
      final branches = _branchIdController.text.split(',');
      for (final branch in branches) {
        if (branch.trim().isNotEmpty) {
          targetTopics.add('branch_${branch.trim()}');
        }
      }
    }
    
    // Add individual user topics
    final employees = allManinEmplyeList;
    for (final empId in _selectedEmployeeIds) {
      final emp = employees.firstWhere((e) => e.id == empId);
      final uName = emp.userName ?? emp.username ?? 'user';
      targetTopics.add(_sanitizeTopic('user_${empId}_$uName'));
    }

    if (targetTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one targeting topic!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final success = await NotificationApi().sendNotification(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      screen: _selectedScreen,
      scheduleTime: _scheduledDateTime?.toUtc().toIso8601String(),
      topics: targetTopics,
    );

    setState(() {
      _isSending = false;
    });

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: ColorConst.present, size: 28),
              const SizedBox(width: 10),
              const Text('Success'),
            ],
          ),
          content: Text(_scheduledDateTime != null
              ? 'Notification scheduled successfully!'
              : 'Notification sent successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetForm();
              },
              child: Text('OK', style: TextStyle(color: ColorConst.themeColor)),
            )
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: ColorConst.red, size: 28),
              const SizedBox(width: 10),
              const Text('Error'),
            ],
          ),
          content: const Text('Failed to send push notification. Please check if backend server is running.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: TextStyle(color: ColorConst.themeColor)),
            )
          ],
        ),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _messageController.clear();
    _imageUrlController.clear();
    _branchIdController.clear();
    setState(() {
      _selectedScreen = null;
      _scheduledDateTime = null;
      _selectedPredefinedTopics.clear();
      _selectedCompanyIds.clear();
      _selectedEmployeeIds.clear();
      _companySearchQuery = '';
      _employeeSearchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final employees = allManinEmplyeList.where((emp) {
      final name = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.toLowerCase();
      final username = (emp.userName ?? emp.username ?? '').toLowerCase();
      final q = _employeeSearchQuery.toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();

    final filteredCompanies = _companies.where((c) {
      final name = (c.companyName ?? '').toLowerCase();
      final q = _companySearchQuery.toLowerCase();
      return name.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: ColorConst.scaffoldColor,
      appBar: AppBar(
        title: Text(
          notificationString,
          style: TextStyle(
            color: ColorConst.appBarTitleColor,
            fontFamily: fontInterBoldString,
            fontSize: 20,
          ),
        ),
        backgroundColor: ColorConst.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: ColorConst.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: ColorConst.themeColor),
              onPressed: _resetForm,
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Compose Notification Form Card
                _buildFormSection(),
                const SizedBox(height: 16),
                
                // 2. Targeting Topics Card
                _buildTargetingSection(filteredCompanies, employees),
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorConst.themeColor, ColorConst.darkGreenColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConst.themeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Send Push Notification',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: fontInterMediumString,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ColorConst.textBorder.withOpacity(0.5)),
      ),
      color: ColorConst.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_note, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Compose Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontInterSemiBoldString,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Office Holiday Announcement',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            
            // Message
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message Body *',
                hintText: 'Type notification content here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.message_outlined),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Message body is required' : null,
            ),
            const SizedBox(height: 16),
            
            // Image URL
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL (Optional)',
                hintText: 'https://example.com/banner.png',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),
            
            // Deep Link / Screen Dropdown
            DropdownButtonFormField<String>(
              value: _selectedScreen,
              decoration: InputDecoration(
                labelText: 'Deep Link Screen (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.link),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None / Default')),
                ..._screenOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt['value'],
                    child: Text(opt['label']!),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedScreen = val;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Scheduling
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorConst.textBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _scheduledDateTime == null
                          ? 'Send Immediately'
                          : 'Scheduled: ${DateFormat('yyyy-MM-dd HH:mm').format(_scheduledDateTime!)}',
                      style: TextStyle(
                        fontFamily: fontInterMediumString,
                        color: _scheduledDateTime == null ? ColorConst.textgrey : ColorConst.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectDateTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConst.themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                  label: const Text('Schedule', style: TextStyle(color: Colors.white)),
                ),
                if (_scheduledDateTime != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _scheduledDateTime = null;
                      });
                    },
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetingSection(List<GetCompanyData> filteredCompanies, List<Employeelists> employees) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ColorConst.textBorder.withOpacity(0.5)),
      ),
      color: ColorConst.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.track_changes, color: Colors.redAccent),
                SizedBox(width: 8),
                Text(
                  'Select Targets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontInterSemiBoldString,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // 1. Roles Checkbox row
            const Text(
              'User Roles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: fontInterMediumString,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRoleFilterChip('all', 'All Users'),
                _buildRoleFilterChip('all_admin', 'Admins'),
                _buildRoleFilterChip('all_subadmin', 'Sub Admins'),
                _buildRoleFilterChip('all_user', 'Regular Users'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 2. Company Multi-Select
            const Text(
              'Company-wise Targeting',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: fontInterMediumString,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                setState(() {
                  _companySearchQuery = val;
                });
              },
            ),
            const SizedBox(height: 8),
            if (_isLoadingCompanies)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                maxHeight: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: ColorConst.textBorder.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredCompanies.length,
                  itemBuilder: (ctx, idx) {
                    final company = filteredCompanies[idx];
                    final cId = company.companyId;
                    if (cId == null) return const SizedBox();
                    final isSelected = _selectedCompanyIds.contains(cId);
                    return CheckboxListTile(
                      title: Text(company.companyName ?? 'Company ID: $cId'),
                      value: isSelected,
                      dense: true,
                      activeColor: ColorConst.themeColor,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCompanyIds.add(cId);
                          } else {
                            _selectedCompanyIds.remove(cId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              
            const SizedBox(height: 20),
            
            // 3. Branch Targeting Text field
            const Text(
              'Branch-wise Targeting',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: fontInterMediumString,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _branchIdController,
              decoration: InputDecoration(
                hintText: 'Enter Branch IDs (comma-separated, e.g. 1, 2)',
                prefixIcon: const Icon(Icons.account_tree_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 4. Individual Employees Search & Select
            const Text(
              'Individual User Targeting',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: fontInterMediumString,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search employees by name...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                setState(() {
                  _employeeSearchQuery = val;
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              maxHeight: 180,
              decoration: BoxDecoration(
                border: Border.all(color: ColorConst.textBorder.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: employees.length,
                itemBuilder: (ctx, idx) {
                  final emp = employees[idx];
                  final empId = emp.id;
                  if (empId == null) return const SizedBox();
                  final isSelected = _selectedEmployeeIds.contains(empId);
                  final name = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
                  return CheckboxListTile(
                    title: Text(name.isNotEmpty ? name : (emp.userName ?? emp.username ?? 'User ID: $empId')),
                    subtitle: Text('Role: ${emp.role ?? 'User'} | Code: ${emp.userName ?? emp.username ?? ''}'),
                    value: isSelected,
                    dense: true,
                    activeColor: ColorConst.themeColor,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedEmployeeIds.add(empId);
                        } else {
                          _selectedEmployeeIds.remove(empId);
                        }
                      });
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

  Widget _buildRoleFilterChip(String topic, String label) {
    final isSelected = _selectedPredefinedTopics.contains(topic);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: ColorConst.themeColor.withOpacity(0.15),
      checkmarkColor: ColorConst.themeColor,
      backgroundColor: ColorConst.scaffoldColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? ColorConst.themeColor : ColorConst.textBorder,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedPredefinedTopics.add(topic);
          } else {
            _selectedPredefinedTopics.remove(topic);
          }
        });
      },
    );
  }
}
