import 'dart:io';
import 'package:tax_hrm/provider/language_provider.dart';

// All font Weight Common String
const String fontInterBoldString = "InterBold";
const String fontInterMediumString = "InterMedium";
const String fontInterRegularString = "InterRegular";
const String fontInterSemiBoldString = "InterSemiBold";

// All Common Title String
String get appNameString => LanguageProvider.translate("appNameString", "TAX HRM 2.0");

final String rateLinkUrl = Platform.isIOS 
  ? 'https://apps.apple.com/us/app/tax-hrm-2-0/id6781143175'
  : 'https://play.google.com/store/apps/details?id=com.hrmnewapp.taxhrm&hl=en_IN';

const String privacyPolicyUrl = "https://taxcrm.taxfile.co.in/taxhrm-privacy";
const String teramsCondiUrl = "https://taxcrm.taxfile.co.in/taxhrm-condition";

// inter net String
String get ooopsString => LanguageProvider.translate("ooopsString", "Oops!");
String get internetDecString => LanguageProvider.translate("internetDecString", "No Internet Connection found \n Check your Connection");
String get tryAgainString => LanguageProvider.translate("tryAgainString", "Try Again");

// welcome String
String get welcomeTitle1String => LanguageProvider.translate("welcomeTitle1String", "I’m an Employee");
String get welcomeTitle2String => LanguageProvider.translate("welcomeTitle2String", "Owner / Admin Access");
String get welcomeDec1String => LanguageProvider.translate("welcomeDec1String", "Sign in to access your workplace tools and resources.");
String get welcomeDec2String => LanguageProvider.translate("welcomeDec2String", "Create your organization and manage your team efficiently.");
String get welcomeTaxHrmString => LanguageProvider.translate("welcomeTaxHrmString", "Welcome to TAXHRM");
String get welcomeDecString => LanguageProvider.translate("welcomeDecString", "Let’s begin by choosing what you want to explore today.");

// user login String
String get loginString => LanguageProvider.translate("loginString", "Login");
String get loginTitleString => LanguageProvider.translate("loginTitleString", "Simpy Enter your Username & Password");
String get userNameString => LanguageProvider.translate("userNameString", "Username");
String get passwordString => LanguageProvider.translate("passwordString", "Password");
String get filedrequiredString => LanguageProvider.translate("filedrequiredString", "Filed is Required");
String get donthaveAccString => LanguageProvider.translate("donthaveAccString", "Don’t have an account? ");
String get regiNowString => LanguageProvider.translate("regiNowString", "Registration Now");
String get forgotPasswordString => LanguageProvider.translate("forgotPasswordString", "Forgot Password?");

// user otp string
String get sendOtpString => LanguageProvider.translate("sendOtpString", "Send OTP");
String get verifyString => LanguageProvider.translate("verifyString", "Verify");
String get backString => LanguageProvider.translate("backString", "Back");
String get verificationCodeString => LanguageProvider.translate("verificationCodeString", "Verification Code");
String get otpTitlesString => LanguageProvider.translate("otpTitlesString", "Choose how you want to receive your 6-digit verification code.");
String get verifyOtpSendString => LanguageProvider.translate("verifyOtpSendString", "A verification code has been sent to your registered ");  
String get mobileString => LanguageProvider.translate("mobileString", "Mobile");
String get emailString => LanguageProvider.translate("emailString", "E-mail");

// Bottom Bar Titles
String get homeString => LanguageProvider.translate("Home", "Home");
String get attendanceString => LanguageProvider.translate("Attendance", "Attendance");
String get leaveString => LanguageProvider.translate("Leave", "Leave");
String get settingString => LanguageProvider.translate("Setting", "Setting");

// Admin appbar labels
String get adminLeavePage => LanguageProvider.translate("adminLeavePage", "Leave Request");
String get adminPayrollSummary => LanguageProvider.translate("adminPayrollSummary", "Payroll Summary");
String get employeeMaster => LanguageProvider.translate("employeeMaster", "Employee Master");
String get employeeAddEdit => LanguageProvider.translate("employeeAddEdit", "Employee Details");
String get addEmployee => LanguageProvider.translate("addEmployee", "Add Employee");

// home Screen options Title
String get salarySlipString => LanguageProvider.translate("Salary Slip", "Salary Slip");
String get holidayString => LanguageProvider.translate("Holidays", "Holidays");
String get noteString => LanguageProvider.translate("Notes", "Notes");
String get documentString => LanguageProvider.translate("Document", "Document");
String get roleRightsString => LanguageProvider.translate("Role Rights", "Role Rights");
String get addDocumentString => LanguageProvider.translate("Add Document", "Add Document");
String get timeLineString => LanguageProvider.translate("Time Line", "Time Line");
String get timeLineViewString => LanguageProvider.translate("Time Line View", "Time Line View");
String get paySlipString => LanguageProvider.translate("Pay Slip", "Pay Slip");
String get payrollMasterString => LanguageProvider.translate("Payroll Master", "Payroll Master");
String get payrollSummeryString => LanguageProvider.translate("Payroll Summery", "Payroll Summery");
String get leaveMasterString => LanguageProvider.translate("Leave Master", "Leave Master");
String get shiftMasterString => LanguageProvider.translate("Shift Master", "Shift Master");
String get shiftGroupMasterString => LanguageProvider.translate("Shift Group Master", "Shift Group Master");
String get shiftTimingString => LanguageProvider.translate("Shift Timing", "Shift Timing");
String get departmentString => LanguageProvider.translate("Department", "Department");
String get eventString => LanguageProvider.translate("Event", "Event");
String get recuritmentString => LanguageProvider.translate("Recuritment", "Recuritment");
String get addDeduString => LanguageProvider.translate("Addition Deduction", "Addition Deduction");
String get employeeMasterTitleString => LanguageProvider.translate("Employee", "Employee");

// Selfie Punch Screen Title
String get punchString => LanguageProvider.translate("Punch", "Punch");
String get punchOutString => LanguageProvider.translate("Punch Out", "Punch Out");
String get punchInString => LanguageProvider.translate("Punch In", "Punch In");
String get checkOutString => LanguageProvider.translate("Check Out", "Check Out");
String get punchInTimeString => LanguageProvider.translate("Punch In Time", "Punch In Time");
String get punchOutTimeString => LanguageProvider.translate("Punch Out Time", "Punch Out Time");

// leave screen title
String get balanceString => LanguageProvider.translate("Balance", "Balance");
String get applyNewLeaveString => LanguageProvider.translate("Apply New Leave", "Apply New Leave");
String get applyLeaveString => LanguageProvider.translate("Apply Leave", "Apply Leave");
String get paidLeaveString => LanguageProvider.translate("Paid Leave", "Paid Leave");
String get leaveUsedString => LanguageProvider.translate("Leave Used", "Leave Used");

// add leave apply 
String get leaveStartDateString => LanguageProvider.translate("Leave Start Date", "Leave Start Date");
String get leaveEndDateString => LanguageProvider.translate("Leave End Date", "Leave End Date");
String get enterReasonString => LanguageProvider.translate("Enter Reason", "Enter Reason");
String get leaveDurationString => LanguageProvider.translate("Leave Duration", "Leave Duration");
String get selectLeaveTypeString => LanguageProvider.translate("Select Leave Type", "Select Leave Type");
String get selectLeaveStatusString => LanguageProvider.translate("Select Leave Status", "Select Leave Status");

// holiday screen titles
String get noHolidaysAddedString => LanguageProvider.translate("No Holidays Added!", "No Holidays Added!");
String get addNewHolidayString => LanguageProvider.translate("Add New Holiday", "Add New Holiday");
String get holidayTypeString => LanguageProvider.translate("Holiday Type", "Holiday Type");
String get descriptionString => LanguageProvider.translate("Description", "Description");
String get enterDescriptionString => LanguageProvider.translate("Enter Description", "Enter Description");
String get titleString => LanguageProvider.translate("Title", "Title");
String get enterTitleString => LanguageProvider.translate("Enter Title", "Enter Title");
String get paidHolidayString => LanguageProvider.translate("Paid Holiday", "Paid Holiday");
String get unpaidHolidayString => LanguageProvider.translate("UnPaid Holiday", "UnPaid Holiday");
String get daterErrorSrtring => LanguageProvider.translate("Please select at least one date", "Please select at least one date");

// Note screen titles
String get addNewNoteString => LanguageProvider.translate("Add New Note", "Add New Note");
String get noNoteAddedString => LanguageProvider.translate("No Note Added!", "No Note Added!");
String get searchNotesString => LanguageProvider.translate("Search Notes", "Search Notes");
String get submitString => LanguageProvider.translate("Submit", "Submit");
String get enterNoteString => LanguageProvider.translate("Enter Note", "Enter Note");
String get tapToUploadPhotoString => LanguageProvider.translate("Tap to Upload Photo", "Tap to Upload Photo");
String get addNoteString => LanguageProvider.translate("Add Note", "Add Note");

// Document Screen titles
String get addFileString => LanguageProvider.translate("Add File", "Add File");
String get uploadFileString => LanguageProvider.translate("Uplaod File", "Uplaod File");

// setting screen title
String get logoutString => LanguageProvider.translate("Logout", "Logout");
String get dragAnddropString => LanguageProvider.translate("Drag and drop your file here", "Drag and drop your file here");
String get orString => LanguageProvider.translate("OR", "OR");
String get browseFileString => LanguageProvider.translate("Browse Files", "Browse Files");

// Salary Slip Screen Design
String get earningString => LanguageProvider.translate("Earning", "Earning");
String get deductionString => LanguageProvider.translate("Deduction", "Deduction");
String get basicSalaryString => LanguageProvider.translate("Basic Salary", "Basic Salary");
String get pfString => LanguageProvider.translate("PF", "PF");
String get esicString => LanguageProvider.translate("ESIC", "ESIC");
String get convenienceString => LanguageProvider.translate("Convenience", "Convenience");
String get hraString => LanguageProvider.translate("HRA", "HRA");
String get payoutAmtString => LanguageProvider.translate("Payout Amount", "Payout Amount");
String get downloadSlipString => LanguageProvider.translate("Download Slip", "Download Slip");
String get viewSlipString => LanguageProvider.translate("View Slip", "View Slip");
String get personalInfoString => LanguageProvider.translate("Personal info", "Personal info");
String get whatsNewString => LanguageProvider.translate("What’s New", "What’s New");
String get shareString => LanguageProvider.translate("Share", "Share");
String get rateString => LanguageProvider.translate("Rate Us", "Rate Us");     
String get exitString => LanguageProvider.translate("Exit", "Exit");

// user profile title
String get departmentNameString => LanguageProvider.translate("Department Name", "Department Name");
String get departmentYourNameString => LanguageProvider.translate("Department Your Name", "Department Your Name");
String get positionString => LanguageProvider.translate("Position", "Position");
String get enterYourPositionString => LanguageProvider.translate("Enter Your Position", "Enter Your Position");  
String get enterYourUsernameString => LanguageProvider.translate("Enter Your Username", "Enter Your Username");
String get enterYourPasswordString => LanguageProvider.translate("Enter Your Password", "Enter Your Password");
String get firstNameString => LanguageProvider.translate("First Name", "First Name");
String get enterYourFirstNameString => LanguageProvider.translate("Enter Your First Name", "Enter Your First Name");  
String get lastNameString => LanguageProvider.translate("Last Name", "Last Name");
String get enterYourLastNameString => LanguageProvider.translate("Enter Your Last Name", "Enter Your Last Name");
String get emailUserString => LanguageProvider.translate("Email", "Email");
String get enterYourEmailString => LanguageProvider.translate("Enter Your Email", "Enter Your Email");
String get mobile1String => LanguageProvider.translate("Mobile 1", "Mobile 1");
String get enterYourMobile1String => LanguageProvider.translate("Enter Your Mobile 1", "Enter Your Mobile 1");
String get mobile2String => LanguageProvider.translate("Mobile 2", "Mobile 2");
String get enterYourMobile2String => LanguageProvider.translate("Enter Your Mobile 2", "Enter Your Mobile 2");
String get officeString => LanguageProvider.translate("Office", "Office");
String get enterOfficeString => LanguageProvider.translate("Enter Office", "Enter Office");
String get workTypeString => LanguageProvider.translate("Work Type", "Work Type");
String get enterWorkTypeString => LanguageProvider.translate("Enter Work Type", "Enter Work Type");
String get registrationFirmTypString => LanguageProvider.translate("Registration Firm Type", "Registration Firm Type");
String get enterYourRegistrationFirmTypString => LanguageProvider.translate("Enter Registration Firm Type", "Enter Registration Firm Type");  
String get saveString => LanguageProvider.translate("Save", "Save");
String get enterDepartmentNameString => LanguageProvider.translate("Enter Department Name", "Enter Department Name");  

// ------------------- Admin Side Title String -------------------\\
String get selectPackageString => LanguageProvider.translate("Select Your Package", "Select Your Package");
String get cancelString => LanguageProvider.translate("Cancel", "Cancel");
String get nextString => LanguageProvider.translate("Next", "Next");
String get updateDataString => LanguageProvider.translate("Update Data", "Update Data");
String get regFirmTypeString => LanguageProvider.translate("Registration Firm Type", "Registration Firm Type");
String get companyNameString => LanguageProvider.translate("Company Name", "Company Name");
String get addressString => LanguageProvider.translate("Address", "Address");
String get enterYourString => LanguageProvider.translate("Enter Your", "Enter Your");
String get pleaseEnterString => LanguageProvider.translate("Please Enter", "Please Enter");

// Forgot Password Screen String
String get forgotPasswordStrng => LanguageProvider.translate("Forgot Password", "Forgot Password");
String get forgotSDescStrng => LanguageProvider.translate("Simpy Enter your Username & Password", "Simpy Enter your Username & Password");
String get confirmPasswordString => LanguageProvider.translate("Confirm Password", "Confirm Password");
String get waitString => LanguageProvider.translate("Wait", "Wait");

String get noEmployeeDataString => LanguageProvider.translate("No Employee Data Founds", "No Employee Data Founds");
String get dateofBirthString => LanguageProvider.translate("Date of Birth", "Date of Birth");
String get dateOfJoiningString => LanguageProvider.translate("Date Of Joining", "Date Of Joining");
String get selectDOBString => LanguageProvider.translate("Select DOB", "Select DOB");
String get selectDOJString => LanguageProvider.translate("Select DOJ", "Select DOJ");
String get validEmailAddString => LanguageProvider.translate("Please enter a valid email address", "Please enter a valid email address");
String get validMobileAddString => LanguageProvider.translate("Enter valid 10 digit mobile number", "Enter valid 10 digit mobile number");
String get validMobileString => LanguageProvider.translate("Please enter a valid mobile number", "Please enter a valid mobile number");

String get noTimeLineAddedString => LanguageProvider.translate("No TimeLine Added!", "No TimeLine Added!");
String get googleMapString => LanguageProvider.translate("Google Map", "Google Map");
String get addtoLocationTimeLineString => LanguageProvider.translate("Add to Location TimeLine", "Add to Location TimeLine");
String get doneString => LanguageProvider.translate("Done", "Done");
String get noDocumentAddedString => LanguageProvider.translate("No Document Added!", "No Document Added!");

// Attendance Type String
String get presentString => LanguageProvider.translate("Present", "Present");
String get absentString => LanguageProvider.translate("Absent", "Absent");
String get unPaidLeaveString => LanguageProvider.translate("UnPaid Leave", "UnPaid Leave");
String get weekOffString => LanguageProvider.translate("Week Off", "Week Off");
String get onLeaveString => LanguageProvider.translate("On Leave", "On Leave");

String get viewString => LanguageProvider.translate("View", "View");
String get editString => LanguageProvider.translate("Edit", "Edit");
String get deleteString => LanguageProvider.translate("Delete", "Delete");
String get areYouSureString => LanguageProvider.translate("Are You Sure?", "Are You Sure?");
String get deleteDecString => LanguageProvider.translate("You won't be able to revert this!", "You won't be able to revert this!");
String get noCancelString => LanguageProvider.translate("No, cancel!", "No, cancel!");
String get yesDeleteString => LanguageProvider.translate("Yes, delete it!", "Yes, delete it!");
String get punchTimeString => LanguageProvider.translate("Punch Time", "Punch Time");
String get noNotesAddedString => LanguageProvider.translate("No Notes Added!", "No Notes Added!");

String get selectCompanyString => LanguageProvider.translate("Select Company", "Select Company");

String get subAdminAccessControlString => LanguageProvider.translate("Sub-Admin Access Control", "Sub-Admin Access Control");
String get userRightsString => LanguageProvider.translate("User Rights", "User Rights");
String get asUserString => LanguageProvider.translate("As User", "As User");
String get asAdminString => LanguageProvider.translate("As Admin", "As Admin");
String get selectSubAdminString => LanguageProvider.translate("Select Sub-Admin", "Select Sub-Admin");
String get pleaseSelectSubAdminString => LanguageProvider.translate("Please Select Sub-Admin", "Please Select Sub-Admin");

// department screen title
String get departmentMasterString => LanguageProvider.translate("Department Master", "Department Master");
String get selectDepartmentNameString => LanguageProvider.translate("Select Department Name", "Select Department Name");
String get designationMasterString => LanguageProvider.translate("Designation Master", "Designation Master");
String get addDepartmentString => LanguageProvider.translate("Add Department", "Add Department");
String get addDesignationString => LanguageProvider.translate("Add Designation", "Add Designation");
String get noDepartmentAddedString => LanguageProvider.translate("No Department Added!", "No Department Added!");
String get noDesignationAddedString => LanguageProvider.translate("No Designation Added!", "No Designation Added!");
String get noShiftAddedString => LanguageProvider.translate("No Shift Added!", "No Shift Added!");
String get statusString => LanguageProvider.translate("Status", "Status");
String get activeString => LanguageProvider.translate("Active", "Active");
String get inActiveString => LanguageProvider.translate("InActive", "InActive");
String get designationNameString => LanguageProvider.translate("Designation Name", "Designation Name");
String get enterDesignationNameString => LanguageProvider.translate("Enter Designation Name", "Enter Designation Name");

// shift screen title
String get shiftShortNameString => LanguageProvider.translate("Shift Short Name", "Shift Short Name"); 
String get shiftFullNameString => LanguageProvider.translate("Shift Full Name", "Shift Full Name"); 
String get enterShiftFullNameString => LanguageProvider.translate("Enter Shift Full Name", "Enter Shift Full Name"); 
String get enterShiftShortNameString => LanguageProvider.translate("Enter Shift Short Name", "Enter Shift Short Name"); 
String get addShiftGroupString => LanguageProvider.translate("Add Shift Group", "Add Shift Group"); 
String get addShiftMasterString => LanguageProvider.translate("Add Shift Master", "Add Shift Master");
String get shiftDurationString => LanguageProvider.translate("Shift Duration", "Shift Duration"); 
String get shiftBeginTimeString => LanguageProvider.translate("Shift Begin Time", "Shift Begin Time");
String get shiftEndTimeString => LanguageProvider.translate("Shift End Time", "Shift End Time"); 
String get newShiftMasterString => LanguageProvider.translate("New Shift Master", "New Shift Master");

// Add shift Timing titles
String get designationString => LanguageProvider.translate("Designation", "Designation");
String get selectWorkDaysString => LanguageProvider.translate("Select Work Days", "Select Work Days");
String get break1String => LanguageProvider.translate("Break 1", "Break 1");
String get break2String => LanguageProvider.translate("Break 2", "Break 2");
String get selectShiftFullNameString => LanguageProvider.translate("Select Shift Full Name", "Select Shift Full Name");
String get selectDesignationNameString => LanguageProvider.translate("Select Designation Name", "Select Designation Name");
String get selectTimersString => LanguageProvider.translate("Select Time", "Select Time");
String get okString => LanguageProvider.translate("Ok", "Ok");
String get errorWorkingString => LanguageProvider.translate("Please select at least one working day", "Please select at least one working day");
String get positionErrorString => LanguageProvider.translate("Position is already used !!!", "Position is already used !!!");

// event screen titles
String get addEventString => LanguageProvider.translate("Add Event", "Add Event"); 
String get editEventString => LanguageProvider.translate("Edit Event", "Edit Event"); 
String get addPunchString => LanguageProvider.translate("Add Punch", "Add Punch");
String get noEventAddedString => LanguageProvider.translate("No Event Added!", "No Event Added!");
String get eventPlaceString => LanguageProvider.translate("Place", "Place");
String get enterEventPlaceString => LanguageProvider.translate("Enter Place", "Enter Place");
String get eventNameString => LanguageProvider.translate("Name", "Name");
String get enterEventNameString => LanguageProvider.translate("Enter Name", "Enter Name");
String get eventRemarkString => LanguageProvider.translate("Remark", "Remark");
String get enterEventRemarksString => LanguageProvider.translate("Enter Remark", "Enter Remark");
String get eventStartDateString => LanguageProvider.translate("Start Date", "Start Date");
String get selectEventStartDateString => LanguageProvider.translate("Select Start Date", "Select Start Date");
String get eventEndDateString => LanguageProvider.translate("End Date", "End Date");
String get selectEventEndDateString => LanguageProvider.translate("Select End Date", "Select End Date");
String get searchEventString => LanguageProvider.translate("Search Event", "Search Event");

// Recuirtment screen titles
String get addCandidateString => LanguageProvider.translate("Add Candidate", "Add Candidate"); 
String get candidateString => LanguageProvider.translate("Candidate List", "Candidate List");
String get searchCandidateListString => LanguageProvider.translate("Search Candidate", "Search Candidate");
String get noCandidateAddedString => LanguageProvider.translate("No Candidate Added!", "No Candidate Added!");
String get interviewDateString => LanguageProvider.translate("Interview Date", "Interview Date");
String get conductedByString => LanguageProvider.translate("Conducted By", "Conducted By");
String get candidateDetailsString => LanguageProvider.translate("Candidate Details", "Candidate Details");
String get referenceByString => LanguageProvider.translate("Reference By", "Reference By");
String get enterReferenceByNameString => LanguageProvider.translate("Enter Reference By Name", "Enter Reference By Name");
String get venueString => LanguageProvider.translate("Venue", "Venue");
String get enterVenueNameString => LanguageProvider.translate("Enter Venue Name", "Enter Venue Name");
String get candidateNameString => LanguageProvider.translate("Candidate Name", "Candidate Name");
String get enterCandidateNameString => LanguageProvider.translate("Enter Candidate Name", "Enter Candidate Name");
String get experienceString => LanguageProvider.translate("Experience", "Experience");
String get enterExperienceString => LanguageProvider.translate("Enter experience", "Enter experience");
String get mobileNoString => LanguageProvider.translate("Mobile No", "Mobile No");
String get enterMobileNoString => LanguageProvider.translate("Enter Mobile Number", "Enter Mobile Number");
String get enterEmailString => LanguageProvider.translate("Enter email", "Enter email");
String get lastSalaryString => LanguageProvider.translate("Last Salary", "Last Salary");
String get enterLastSalaryString => LanguageProvider.translate("Enter Last Salary", "Enter Last Salary");
String get expectedSalaryString => LanguageProvider.translate("Expected Salary", "Expected Salary");
String get enterExpectedSalaryString => LanguageProvider.translate("Enter Expected Salary", "Enter Expected Salary");
String get selectDateString => LanguageProvider.translate("Select Date", "Select Date");
String get selectConductedByString => LanguageProvider.translate("Select Conducted By", "Select Conducted By");
String get dateString => LanguageProvider.translate("Date", "Date");
String get noDataFoundsString => LanguageProvider.translate("No Data Found", "No Data Found");

// addition and deduction title
String get additionDeductionListString => LanguageProvider.translate("Addition Deduction List", "Addition Deduction List");
String get addAdditionDeductionString => LanguageProvider.translate("Add Addition Deduction", "Add Addition Deduction");
String get additionOrDeductionString => LanguageProvider.translate("Addition/Deduction", "Addition/Deduction");
String get hrmString => LanguageProvider.translate("HRA", "HRA");
String get daString => LanguageProvider.translate("DA", "DA");
String get conveyanceString => LanguageProvider.translate("Conveyance", "Conveyance");
String get specialAllowanceString => LanguageProvider.translate("Special Allowance", "Special Allowance");
String get otherDeducationString => LanguageProvider.translate("Other Deduction", "Other Deduction");
String get medicalAllowanceString => LanguageProvider.translate("Medical Allowance", "Medical Allowance");
String get tdsString => LanguageProvider.translate("TDS", "TDS");
String get professionalTaxString => LanguageProvider.translate("Professional Tax", "Professional Tax");
String get inPercentageString => LanguageProvider.translate("In Percentage (%)", "In Percentage (%)");
String get employessNameString => LanguageProvider.translate("Employee Name", "Employee Name");
String get amountString => LanguageProvider.translate("Amount", "Amount");
String get typeString => LanguageProvider.translate("Type", "Type");
String get enterAmountString => LanguageProvider.translate("Enter Amount", "Enter Amount");
String get pleaseAmountString => LanguageProvider.translate("Please enter a amount", "Please enter a amount");

// payroll title String
String get selectEmployeeString => LanguageProvider.translate("Select Employee", "Select Employee");
String get selectEmployeeNameString => LanguageProvider.translate("Select Employee Name", "Select Employee Name");
String get netPayableString => LanguageProvider.translate("Net Payable", "Net Payable");
String get addEmployeeSalaryString => LanguageProvider.translate("Add Employee Salary", "Add Employee Salary");
String get editEmployeeSalaryString => LanguageProvider.translate("Edit Employee Salary", "Edit Employee Salary");
String get employeeSummryString => LanguageProvider.translate("Employee Summary", "Employee Summary");
String get totalTimeString => LanguageProvider.translate("Total Time", "Total Time");
String get totalBreakString => LanguageProvider.translate("Total Break", "Total Break");
String get workingTimeString => LanguageProvider.translate("Working Time", "Working Time");
String get workingHoursString => LanguageProvider.translate("Working Hours", "Working Hours");
String get plString => LanguageProvider.translate("PL", "PL");
String get lwpString => LanguageProvider.translate("L.W.P", "L.W.P");
String get totalHoursString => LanguageProvider.translate("Total Hours", "Total Hours");
String get inTimeString => LanguageProvider.translate("In Time", "In Time");
String get outTimeString => LanguageProvider.translate("Out Time", "Out Time");
String get hoursString => LanguageProvider.translate("Hours", "Hours");
String get totalNetPayableString => LanguageProvider.translate("Total Net Payable", "Total Net Payable");
String get bankNameString => LanguageProvider.translate("Bank Name", "Bank Name");
String get bankAccountNoString => LanguageProvider.translate("Bank Account No", "Bank Account No");
String get otherAditionString => LanguageProvider.translate("Other Addition", "Other Addition");
String get otString => LanguageProvider.translate("OT", "OT");
String get otHoursString => LanguageProvider.translate("OT Hours", "OT Hours");
String get salaryAmountString => LanguageProvider.translate("Salary Amount", "Salary Amount");
String get effectiveDateString => LanguageProvider.translate("Effective Date", "Effective Date");
String get viewPaySlipString => LanguageProvider.translate("View Payslip", "View Payslip");

// admin Leave Master 
String get addLeaveString => LanguageProvider.translate("Add Leave", "Add Leave");
String get yearlyLimitString => LanguageProvider.translate("Yearly Limit", "Yearly Limit");	
String get monthlyLimitString => LanguageProvider.translate("Monthly Limit", "Monthly Limit");
String get quarterlyLimitString => LanguageProvider.translate("Quarterly Limit", "Quarterly Limit");
String get halfYearlyString => LanguageProvider.translate("Half Yearly", "Half Yearly");
String get considerWeeklyString => LanguageProvider.translate("Consider Weekly Off", "Consider Weekly Off");	
String get considerHolidayString => LanguageProvider.translate("Consider Holiday", "Consider Holiday");
String get leaveTypeFullNameString => LanguageProvider.translate("Leave Type FullName", "Leave Type FullName");
String get enterleaveTypeFullNameString => LanguageProvider.translate("Enter Leave Type FullName", "Enter Leave Type FullName");
String get leaveTypeSortNameString => LanguageProvider.translate("Leave Type SortName", "Leave Type SortName");
String get enterleaveTypeSortNameString => LanguageProvider.translate("Enter Leave Type SortName", "Enter Leave Type SortName");
String get policyIssueDateString => LanguageProvider.translate("Policy Issue Date", "Policy Issue Date");
String get selectPolicyIssueDateString => LanguageProvider.translate("Select Policy Issue Date", "Select Policy Issue Date");
String get enterString => LanguageProvider.translate("Enter ", "Enter ");
String get leaveLimitString => LanguageProvider.translate("Leave Limit", "Leave Limit");
String get selectLeaveLimitString => LanguageProvider.translate("Select Leave Limit", "Select Leave Limit");
String get pleaseSelectLeaveLimitString => LanguageProvider.translate("Please Select Leave Limit", "Please Select Leave Limit");

// Leaderboard Strings
String get leaderboardString => LanguageProvider.translate("Leaderboard", "Leaderboard");
String get participantsString => LanguageProvider.translate("Participants", "Participants");
String get avgHoursString => LanguageProvider.translate("Avg Hours", "Avg Hours");
String get topHoursString => LanguageProvider.translate("Top Hours", "Top Hours");
String get topPerformerString => LanguageProvider.translate("Top Performer", "Top Performer");
String get performanceOverviewString => LanguageProvider.translate("Performance Overview", "Performance Overview");
String get goldMedalistsString => LanguageProvider.translate("Gold Medalists", "Gold Medalists");
String get silverMedalistsString => LanguageProvider.translate("Silver Medalists", "Silver Medalists");
String get bronzeMedalistsString => LanguageProvider.translate("Bronze Medalists", "Bronze Medalists");
String get winnersString => LanguageProvider.translate("Winners", "Winners");
String get winnerString => LanguageProvider.translate("Winner", "Winner");
String get daysString => LanguageProvider.translate("days", "days");
String get otherParticipantsString => LanguageProvider.translate("Other Participants", "Other Participants");
String get noDataAvailableString => LanguageProvider.translate("No Data Available", "No Data Available");
String get noRecordsFoundForString => LanguageProvider.translate("No records found for", "No records found for");

// logviewedit Strings
String get addTimeString => LanguageProvider.translate("Add Time", "Add Time");
String get editTimeString => LanguageProvider.translate("Edit Time", "Edit Time");
String get selectPunchTimeAndTypeString => LanguageProvider.translate("Select punch time and type", "Select punch time and type");
String get selectedTimeString => LanguageProvider.translate("Selected Time", "Selected Time");
String get changeString => LanguageProvider.translate("Change", "Change");
String get manageEmployeeAttendanceString => LanguageProvider.translate("Manage employee attendance", "Manage employee attendance");
String get timeString => LanguageProvider.translate("Time", "Time");
String get inString => LanguageProvider.translate("In", "In");
String get outString => LanguageProvider.translate("Out", "Out");
String get actionString => LanguageProvider.translate("Action", "Action");
String get deleteEntryString => LanguageProvider.translate("Delete Entry", "Delete Entry");
String get areYouSureDeletePunchString => LanguageProvider.translate("Are you sure you want to delete the punch entry at", "Are you sure you want to delete the punch entry at");
String get punchEntryDeletedString => LanguageProvider.translate("Punch entry at", "Punch entry at");
String get deletedString => LanguageProvider.translate("deleted", "deleted");
String get addedNewPunchAtString => LanguageProvider.translate("Added new punch at", "Added new punch at");
String get failedToAddPunchString => LanguageProvider.translate("Failed to add punch", "Failed to add punch");
String get punchEntriesSavedSuccessfullyString => LanguageProvider.translate("Punch entries saved successfully", "Punch entries saved successfully");
String get noPunchesFoundForThisDateString => LanguageProvider.translate("No punches found for this date", "No punches found for this date");

// Miscellaneous Extra Strings
String get totalHolidaysString => LanguageProvider.translate("Total Holidays", "Total Holidays");
String get upcomingString => LanguageProvider.translate("Upcoming", "Upcoming");
String get pastString => LanguageProvider.translate("Past", "Past");
String get pendingString => LanguageProvider.translate("Pending", "Pending");
String get approveString => LanguageProvider.translate("Approve", "Approve");
String get rejectString => LanguageProvider.translate("Reject", "Reject");
String get approveUpperString => LanguageProvider.translate("APPROVE", "APPROVE");
String get rejectUpperString => LanguageProvider.translate("REJECT", "REJECT");
String get chooseFromGalleryString => LanguageProvider.translate("Choose from Gallery", "Choose from Gallery");
String get takeAPhotoString => LanguageProvider.translate("Take a Photo", "Take a Photo");

// Home Design Strings
String get todaysAttendanceString => LanguageProvider.translate("Today's Attendance", "Today's Attendance");
String get activeUpperString => LanguageProvider.translate("ACTIVE", "ACTIVE");
String get seeAllString => LanguageProvider.translate("See All", "See All");

// Bottom Sheet & Stats Strings
String get languageTitleString => LanguageProvider.translate("Language", "Language");
String get selectLanguageTitleString => LanguageProvider.translate("Select Language", "Select Language");
String get employeesString => LanguageProvider.translate("Employees", "Employees");
String get noEmployeesFoundString => LanguageProvider.translate("No employees found", "No employees found");
String get trySearchingWithDifferentNameString => LanguageProvider.translate("Try searching with a different name", "Try searching with a different name");
String get clearSearchString => LanguageProvider.translate("Clear Search", "Clear Search");
String get completedString => LanguageProvider.translate("Completed", "Completed");
String get punchInBeforeString => LanguageProvider.translate("Punch in before 10:00 AM to avoid late marking", "Punch in before 10:00 AM to avoid late marking");
String get noDataAvailableToDownloadString => LanguageProvider.translate("No data available to download", "No data available to download");

// CSV & PDF Strings
String get noString => LanguageProvider.translate("No", "No");
String get dobString => LanguageProvider.translate("DOB", "DOB");
String get dojString => LanguageProvider.translate("DOJ", "DOJ");
String get genderString => LanguageProvider.translate("Gender", "Gender");
String get panString => LanguageProvider.translate("PAN", "PAN");
String get roleString => LanguageProvider.translate("Role", "Role");
String get imageString => LanguageProvider.translate("Image", "Image");
String get requiredString => LanguageProvider.translate("Required", "Required");
String get lengthString => LanguageProvider.translate("Length", "Length");
String get moreString => LanguageProvider.translate("More", "More");


String get paidLeaveHrsString => LanguageProvider.translate("Paid Leave Hrs", "Paid Leave Hrs");
String get holidayHrsString => LanguageProvider.translate("Holiday Hrs", "Holiday Hrs");
String get searchEmployeeHintString => LanguageProvider.translate("Search employee...", "Search employee...");
String get searchForAnEmployeeString => LanguageProvider.translate("Search for an employee...", "Search for an employee...");
String get monString => LanguageProvider.translate("Mon", "Mon");
String get tueString => LanguageProvider.translate("Tue", "Tue");
String get wedString => LanguageProvider.translate("Wed", "Wed");
String get thuString => LanguageProvider.translate("Thu", "Thu");
String get friString => LanguageProvider.translate("Fri", "Fri");
String get satString => LanguageProvider.translate("Sat", "Sat");
String get sunString => LanguageProvider.translate("Sun", "Sun");
String get reasonForLeaveString => LanguageProvider.translate("Reason for Leave", "Reason for Leave");
String get adminModeString => LanguageProvider.translate("Admin Mode", "Admin Mode");
String get darkThemeString => LanguageProvider.translate("Dark Theme", "Dark Theme");
String get employeeRoleString => LanguageProvider.translate("Employee", "Employee");
String get checkInString => LanguageProvider.translate("Check In", "Check In");
String get workingHrsString => LanguageProvider.translate("Working HR'S", "Working HR'S");
String get approvedString => LanguageProvider.translate("Approved", "Approved");
String get rejectedString => LanguageProvider.translate("Rejected", "Rejected");
String get ongoingString => LanguageProvider.translate("Ongoing", "Ongoing");
String get todayString => LanguageProvider.translate("Today", "Today");
String get leaveEligibilityString => LanguageProvider.translate("Leave Eligibility", "Leave Eligibility");
String get gainString => LanguageProvider.translate("Gain", "Gain");
String get usedString => LanguageProvider.translate("Used", "Used");
String get eligibleString => LanguageProvider.translate("Eligible", "Eligible");
String get totalEmployeesString => LanguageProvider.translate("Total Employees", "Total Employees");
String get allEmployeesString => LanguageProvider.translate("All Employees", "All Employees");
String get idString => LanguageProvider.translate("ID", "ID");

// Export and OTP localization getters
String get todayAttendanceReportString => LanguageProvider.translate("Today Attendance Report", "Today Attendance Report");
String get monthlyExcelReportString => LanguageProvider.translate("Monthly Excel Report", "Monthly Excel Report");
String get exportString => LanguageProvider.translate("Export", "Export");
String get yourOtpExpireString => LanguageProvider.translate("Your OTP Expire !!", "Your OTP Expire !!");
String get pleaseEnterOtpWithinString => LanguageProvider.translate("Please enter OTP within", "Please enter OTP within");
String get secondsString => LanguageProvider.translate("seconds", "seconds");
String get exportDailyAttendanceReportString => LanguageProvider.translate("Export Daily Attendance Report", "Export Daily Attendance Report");
String get exportMonthlyAttendanceReportString => LanguageProvider.translate("Export Monthly Attendance Report", "Export Monthly Attendance Report");
String get loadingAttendanceDataString => LanguageProvider.translate("Loading attendance data...", "Loading attendance data...");
String get selectMonthString => LanguageProvider.translate("Select Month", "Select Month");

// New localization getters
String get alwaysAllowString => LanguageProvider.translate("Always Allow — active for shift tracking", "Always Allow — active for shift tracking");
String get requiredLocationTrackString => LanguageProvider.translate("Required to track location during your shift", "Required to track location during your shift");
String get backgroundLocationString => LanguageProvider.translate("Background Location", "Background Location");
String get dateSelectionString => LanguageProvider.translate("Date Selection", "Date Selection");
String get locationTimelineString => LanguageProvider.translate("Location Timeline", "Location Timeline");
String get loadingCoordinatesString => LanguageProvider.translate("Loading coordinates...", "Loading coordinates...");
String get coordinatesLoggedString => LanguageProvider.translate("coordinates logged", "coordinates logged");
String get breakHoursString => LanguageProvider.translate("Break Hours", "Break Hours");
String get netHoursString => LanguageProvider.translate("Net Hours", "Net Hours");
String get remainingHoursString => LanguageProvider.translate("Remaining Hours", "Remaining Hours");
String get overtimeHoursString => LanguageProvider.translate("Overtime Hours", "Overtime Hours");
String get deletePayrollDataString => LanguageProvider.translate("Delete Payroll Data", "Delete Payroll Data");
String get deletePayrollDecString => LanguageProvider.translate("Are you sure you want to delete the payroll attendance data for the selected month? This action cannot be undone.", "Are you sure you want to delete the payroll attendance data for the selected month? This action cannot be undone.");
String get breakString => LanguageProvider.translate("Break", "Break");
String get totalString => LanguageProvider.translate("Total", "Total");
String get hrsString => LanguageProvider.translate("Hrs", "Hrs");
String get workString => LanguageProvider.translate("Work", "Work");

// Employee Add/Edit Screen localization keys
String get accountInformationString => LanguageProvider.translate("accountInformationString", "Account Information");
String get personalInformationString => LanguageProvider.translate("personalInformationString", "Personal Information");
String get contactInformationString => LanguageProvider.translate("contactInformationString", "Contact Information");
String get educationDetailsString => LanguageProvider.translate("educationDetailsString", "Education Details");
String get bankDetailsString => LanguageProvider.translate("bankDetailsString", "Bank Details");
String get loginCredentialsString => LanguageProvider.translate("loginCredentialsString", "Login Credentials");
String get organizationDetailsString => LanguageProvider.translate("organizationDetailsString", "Organization Details");
String get employmentDetailsString => LanguageProvider.translate("employmentDetailsString", "Employment Details");
String get addressInformationString => LanguageProvider.translate("addressInformationString", "Address Information");
String get contactDetailsString => LanguageProvider.translate("contactDetailsString", "Contact Details");
String get locationDetailsString => LanguageProvider.translate("locationDetailsString", "Location Details");
String get userNameRequiredString => LanguageProvider.translate("userNameRequiredString", "User Name is required");
String get passwordRequiredString => LanguageProvider.translate("passwordRequiredString", "Password is required");
String get selectRoleString => LanguageProvider.translate("selectRoleString", "Select Role");
String get selectOfficeString => LanguageProvider.translate("selectOfficeString", "Select Office");
String get selectWorkTypeString => LanguageProvider.translate("selectWorkTypeString", "Select Work Type");
String get fetchLocationString => LanguageProvider.translate("fetchLocationString", "Fetch Location");
String get enabledString => LanguageProvider.translate("enabledString", "Enabled");
String get disabledString => LanguageProvider.translate("disabledString", "Disabled");
String get locationRadiusString => LanguageProvider.translate("locationRadiusString", "Location Radius (m)");
String get egRadiusHintString => LanguageProvider.translate("egRadiusHintString", "e.g. 50");
String get radiusRequiredString => LanguageProvider.translate("radiusRequiredString", "Radius is required");
String get enterValidNumberString => LanguageProvider.translate("enterValidNumberString", "Enter valid number");
String get firstNameRequiredString => LanguageProvider.translate("firstNameRequiredString", "First Name is required");
String get lastNameRequiredString => LanguageProvider.translate("lastNameRequiredString", "Last Name is required");
String get dojRequiredString => LanguageProvider.translate("dojRequiredString", "Date of Joining is required");
String get selectJoiningDateString => LanguageProvider.translate("selectJoiningDateString", "Select Joining Date");
String get maritalStatusString => LanguageProvider.translate("maritalStatusString", "Marital Status");
String get salaryTypeString => LanguageProvider.translate("salaryTypeString", "Salary Type");
String get salaryRequiredString => LanguageProvider.translate("salaryRequiredString", "Salary is required");
String get totalHoursRequiredString => LanguageProvider.translate("totalHoursRequiredString", "Total Hours is required");
String get invalidPanFormatString => LanguageProvider.translate("invalidPanFormatString", "Invalid format! Valid format \"ABCDE1234A\"");
String get address1String => LanguageProvider.translate("address1String", "Address 1");
String get address2String => LanguageProvider.translate("address2String", "Address 2");
String get address3String => LanguageProvider.translate("address3String", "Address 3");
String get phoneRequiredString => LanguageProvider.translate("phoneRequiredString", "Phone number is required");
String get stateString => LanguageProvider.translate("stateString", "State");
String get selectStateString => LanguageProvider.translate("selectStateString", "Select State");
String get cityString => LanguageProvider.translate("cityString", "City");
String get selectCityString => LanguageProvider.translate("selectCityString", "Select City");
String get pincodeString => LanguageProvider.translate("pincodeString", "Pincode");
String get selectPincodeString => LanguageProvider.translate("selectPincodeString", "Select Pincode");
String get highestDegreeString => LanguageProvider.translate("highestDegreeString", "Highest Degree");
String get degreeNameString => LanguageProvider.translate("degreeNameString", "Degree Name");
String get universitySchoolString => LanguageProvider.translate("universitySchoolString", "University/School");
String get passingYearString => LanguageProvider.translate("passingYearString", "Passing Year");
String get branchNameString => LanguageProvider.translate("branchNameString", "Branch Name");
String get accountNoString => LanguageProvider.translate("accountNoString", "Account No");
String get accountTypeString => LanguageProvider.translate("accountTypeString", "Account Type");
String get uanNumberString => LanguageProvider.translate("uanNumberString", "UAN Number");
String get esicNumberString => LanguageProvider.translate("esicNumberString", "ESIC Number");
String get selectIfscCodeString => LanguageProvider.translate("selectIfscCodeString", "Select IFSC Code");
String get selectIfscString => LanguageProvider.translate("selectIfscString", "Select IFSC");


