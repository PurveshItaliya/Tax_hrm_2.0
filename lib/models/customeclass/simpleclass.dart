class  TypedClass{
String  keys,values;

TypedClass(this.keys,this.values);


}
// TypedClass? selectGender = gendersList.first;

    List<TypedClass>  gendersList = [
    TypedClass('M', 'Male'),
    TypedClass('F', 'Female'),
    TypedClass('T', 'Transgender'),
];


List<TypedClass>  typeLeaveStatus = [
  TypedClass('P', 'Pending'),
  TypedClass('A', 'Approved'),
  TypedClass('R', 'Reject'),
];


List<TypedClass>  halfdayTypes = [
  TypedClass('First Half', 'First Half'),
  TypedClass('Second Half', 'Second Half'),
];

List<TypedClass>    salaryBaseList = [
  TypedClass('Days', 'Day Base'),
  TypedClass('Hours', 'Hour Base'),
  TypedClass('Monthly', 'Monthly'),
];



List<TypedClass>  leaveTypeMasters = [
  TypedClass('Monthly', 'Monthly'),
  TypedClass('Quarterly', 'Quarterly'),
  TypedClass('HalfYearly', 'HalfYearly'),
    TypedClass('Yearly', 'Yearly'),
];


final List<String> maritalitem = ['Single','Married', 'Divorsed', 'Comitted'];
