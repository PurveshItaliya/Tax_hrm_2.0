// ignore_for_file: strict_top_level_inference, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

Widget shimmerBox({double? height, double? width, BorderRadius? radius}) {
  return Shimmer(
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: radius ?? BorderRadius.circular(6),
      ),
    ),
  );
}

// holiday shimmer design 
Widget holidaysShimmer(size) {
  return ListView.separated(
    itemCount: 20,
    padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
    separatorBuilder: (context, index) {
      return heightSpacer(size.height * 0.02);
    },
    itemBuilder: (context, index) {
      return Shimmer(
        child: Container(
          padding: EdgeInsets.all(size.width*0.025),
          decoration: BoxDecoration(
            color: ColorConst.white,
            border: Border(bottom: BorderSide(color: ColorConst.containerBorderColor,width: 1),top: BorderSide(color: ColorConst.containerBorderColor,width: 1))
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 25,backgroundColor:Colors.grey.shade400,),
              widthSpacer(size.width*0.03,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: Colors.grey.shade400),
                    heightSpacer(size.height*0.01),
                    Container(height: 14,width: 150,color: Colors.grey.shade400,),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}

// setting shimmer design 
Widget settingShimmer(size) {
  return Shimmer(
    child: Column(
      children: [
        Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [
            SizedBox(
              width: size.width,
              height: size.width * 0.78,
              child: Stack(
                children: [
                  Container(
                    height: size.width *0.39,
                    decoration: BoxDecoration(color: Colors.grey.shade400),
                  ),
                  Center(
                    child: Material(elevation: 2,borderRadius: BorderRadius.circular(100),child: Stack(
                      alignment: AlignmentGeometry.bottomRight,
                      children: [
                        CircleAvatar(radius: size.width * 0.18,  backgroundColor: Colors.grey.shade500,
                          child: Container(
                            decoration: BoxDecoration(shape: BoxShape.circle,),
                          ),
                        ),
                      ],
                    ),),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.only(bottom: 25),
              child: Container(height: 14,width: 150, color: Colors.grey.shade400),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 20,
           padding: EdgeInsets.symmetric(horizontal: size.height * 0.01,vertical: size.height *0.04),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(size.height*0.012),
                      leading: Container(height: size.width*0.12,width: size.width*0.12,decoration: BoxDecoration(color: Colors.grey.shade400,borderRadius: BorderRadius.circular(12),),child: Padding(
                        padding: const EdgeInsets.all(12.0),
                      ),),
                      title: Container(height: 40,width: 150,color: Colors.grey.shade400,),
                      trailing: Container(height: size.width*0.12,width: size.width*0.12,color: Colors.grey.shade400),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10,right: 10),
                    child: const Divider(height: 1),
                  )
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

// setting shimmer design 
Widget userProfileShimmer(size) {
  return ListView.builder(
    itemCount: 20,
   padding: EdgeInsets.symmetric(horizontal: size.height * 0.01,vertical: size.height *0.04),
    itemBuilder: (context, index) {
      return Shimmer(
        child: Column(
          children: [
            Container(height: 14, color: Colors.grey.shade400),
            heightSpacer(size.height *0.01),
            Container(height: size.width*0.14,width:size.width,decoration: BoxDecoration(color: Colors.grey.shade400,borderRadius: BorderRadius.circular(12),),child: Padding(padding: const EdgeInsets.all(12.0),),),
            heightSpacer(size.height *0.01),
          ],
        ),
      );
    },
  );
}

// timeline View shimmer
Widget timeLineViewShimmer(size) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: 20,
    itemBuilder: (context, index) {
      return Shimmer(
        child: Container(
          width: size.width,
          decoration: BoxDecoration(
            color: ColorConst.white,
          ),
          child: Row(
            children: [
              widthSpacer(size.width * 0.03),
              Container(height: 18,width: 70, color: Colors.grey.shade400),
          
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                child: Column(
                  children: [
                    Container(
                      width: 2,
                      height: size.height * 0.03,
                      color: ColorConst.grey,
                    ),
                    Container(
                      width: size.width * 0.06,
                      height: size.width * 0.06,
                      decoration: BoxDecoration(
                        color: ColorConst.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 16, color: ColorConst.white),
                    ),
                    Container(
                      width: 2,
                      height: size.height * 0.055,
                      color: ColorConst.grey,
                    ),
                  ],
                ),
              ),
          
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(size.width * 0.03),
                  height: size.height *0.09,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
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

// View Calender Screen Shimmer
Widget viewCalenderShimmer(Size size) {
  return Padding(
    padding:  EdgeInsets.all(size.width * 0.03),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.9,
            padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
            children: List.generate(6, (index) {
              return shimmerBox(
                radius: BorderRadius.circular(8),
              );
            }),
          ),
    
          SizedBox(height: size.height * 0.02),
    
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                return shimmerBox(
                  height: 14,
                  width: size.width * 0.1,
                  radius: BorderRadius.circular(4),
                );
              }),
            ),
          ),
    
          SizedBox(height: size.height * 0.015),
    
          SizedBox(
            height: size.height * 0.4, // same as MonthView
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                return shimmerBox(
                  radius: BorderRadius.circular(6),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// documents shimmer
Widget documentShimmer(size) {
  return ListView.separated(
    itemCount: 20,
    padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
    separatorBuilder: (context, index) {
      return heightSpacer(size.height * 0.02);
    },
    itemBuilder: (context, index) {
      return Shimmer(
        child: Container(
          padding: EdgeInsets.all(size.width*0.025),
          decoration: BoxDecoration(
            color: ColorConst.white,
            border: Border(bottom: BorderSide(color: ColorConst.containerBorderColor,width: 1),top: BorderSide(color: ColorConst.containerBorderColor,width: 1))
          ),
          child: Row(
            children: [
              Container(height: 50,width: 50,color:Colors.grey.shade400,),
              widthSpacer(size.width*0.03,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: Colors.grey.shade400),
                    heightSpacer(size.height*0.01),
                    Container(height: 14,width: 150,color: Colors.grey.shade400,),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}

// notes shimmer design 
Widget notesShimmer(size) {
  return Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: size.height*0.02,right: size.height*0.02),
          child: 
          Container(height: 50, color: Colors.grey.shade400),
        ),
        heightSpacer(size.height*0.02,),
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: 20,
            padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
            separatorBuilder: (context, index) {
              return heightSpacer(size.height * 0.02);
            },
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.all(size.width*0.025),
                decoration: BoxDecoration(color: ColorConst.white,border: Border(bottom: BorderSide(color: ColorConst.containerBorderColor,width: 1),top: BorderSide(color: ColorConst.containerBorderColor,width: 1))),
                child: Row(
                  children: [
                    CircleAvatar(radius: 25,backgroundColor:Colors.grey.shade400,),
                    widthSpacer(size.width*0.03,),
                    Expanded(child: Container(height: 50, color: Colors.grey.shade400),),
                    widthSpacer(size.width*0.03,),
                    Container(height: 50,width: 50, color: Colors.grey.shade400),
                  ],
                )
              );
            },
          ),
        ),
      ],
    ),
  );
}

// department Master shimer
Widget departmentMasterShimmer(size,designationFlag) {
  return Shimmer(
    child: ListView.separated(
      shrinkWrap: true,
      itemCount: 20,
      separatorBuilder: (context, index) {
        return heightSpacer(size.height * 0.02);
      },
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorConst.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ColorConst.grey.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(height: 36,color: Colors.grey.shade300,)
                  ),  
                  widthSpacer(size.width *0.02),
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  widthSpacer(size.width *0.02),
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              if(!designationFlag)...[
                heightSpacer(size.height *0.01),
                Container(height: 36,color: Colors.grey.shade300,),  
              ],
            ],
          ),
        );
      },
    ),
  );
}

// Attendance All Employee Data Shimmer
Widget attendanceAllEmployeeShimmer(Size size) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(size.width * 0.02),
        color: ColorConst.white,
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                shimmerBox(height: 20, width: 20),
                shimmerBox(height: 18, width: size.width * 0.35),
                shimmerBox(height: 20, width: 20),
              ],
            ),

            SizedBox(height: size.height * 0.02),

            GridView.builder(
              itemCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.9,
              ),
              itemBuilder: (_, __) {
                return shimmerBox(
                  height: size.height * 0.07,
                  radius: BorderRadius.circular(8),
                );
              },
            ),
          ],
        ),
      ),

      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.all(size.width * 0.03),
          itemCount: 8,
          itemBuilder: (_, __) {
            return Container(
              margin: EdgeInsets.only(bottom: size.height * 0.015),
              padding: EdgeInsets.all(size.width * 0.03),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmerBox(
                    height: 18,
                    width: size.width * 0.6,
                  ),

                  SizedBox(height: size.height * 0.015),

                  Row(
                    children: [
                      shimmerBox(height: 28, width: 70),
                      SizedBox(width: size.width * 0.02),
                      shimmerBox(height: 28, width: 70),
                      const Spacer(),
                      shimmerBox(height: 30, width: 90),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

// payroll Data Shimmer
Widget payrollMasterShimmer(Size size) {
  return Padding(
    padding: EdgeInsets.all(size.width * 0.02),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerBox(height: 20, width: 100),
        heightSpacer(size.height*0.02),
        Row(
          children: [
            Expanded(child: shimmerBox(height: size.width*0.16,width: size.width,),),
            widthSpacer(size.width*0.02),
            shimmerBox(height: size.width*0.16,width: size.width*0.14,)
          ],
        ),
        heightSpacer(size.height*0.01),
        shimmerBox(height: 20, width: 100),
        heightSpacer(size.height*0.01),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            padding: EdgeInsets.only(bottom: size.height * 0.075),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                width: size.width,
                decoration: BoxDecoration(
                  color: ColorConst.white,
                  border: Border.all(color: ColorConst.grey,width: 1),
                  borderRadius: BorderRadius.circular(6.0),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConst.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: shimmerBox(height: 36),
                        ),
                        widthSpacer(size.width *0.02),
                        shimmerBox(height: 36,width: 36,),
                        widthSpacer(size.width *0.02),
                        shimmerBox(height: 36,width: 36,),
                        widthSpacer(size.width *0.02),
                        shimmerBox(height: 36,width: 36,),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

// add Employee Salary Shimmer
Widget addEmployeeSalaryShimmer(Size size) {
  return Padding(
    padding: EdgeInsets.all(size.width * 0.02),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerBox(height: 20, width: 100),
        heightSpacer(size.height*0.02),
        Row(
          children: [
            Expanded(child: shimmerBox(height: size.width*0.16,width: size.width,),),
            widthSpacer(size.width*0.02),
            shimmerBox(height: size.width*0.16,width: size.width*0.14,)
          ],
        ),
        heightSpacer(size.height*0.01),
        shimmerBox(height: 20, width: 100),
        heightSpacer(size.height*0.01),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.9,
          padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
          children: [
            shimmerBox(),
            shimmerBox(),
            shimmerBox(),
            shimmerBox(),
            shimmerBox(),
            shimmerBox(),
          ],
        ),
        heightSpacer(size.height * 0.001),
        shimmerBox(height: size.height*0.08,width: size.width),
        heightSpacer(size.height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: shimmerBox(height: 25),),
            widthSpacer(size.width*0.01),
            Expanded(child: shimmerBox(height: 25),),
            widthSpacer(size.width*0.01),
            Expanded(child: shimmerBox(height: 25),),
            widthSpacer(size.width*0.01),
            Expanded(child: shimmerBox(height: 25),),
          ],
        ),
        heightSpacer(size.height * 0.005),
        Expanded(
          child: ListView.separated(
            itemCount: 20,
            padding: EdgeInsets.only(bottom: size.height*0.09),
            separatorBuilder: (context, index) {return heightSpacer(size.height * 0.015);},
            itemBuilder: (context, index) {
              return shimmerBox(
                height: size.height *0.06,
              );
            },
          ),
        ),
      ],
    ),
  );
}

// add Employee Summry Shimmer
Widget addEmployeeSummryShimmer(Size size) {
  return Padding(
    padding: EdgeInsets.all(size.width * 0.03),
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                employeeSummryShimmer(size), 
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size),
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size),
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size),
                heightSpacer(size.height*0.015),
                Container(
                  width: size.width,
                  padding: EdgeInsets.all(size.height*0.01),
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConst.textBorder,width: 1),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Column(
                    children: [
                      employeeSummryShimmer(size), 
                      heightSpacer(size.height*0.01),
                      employeeSummryShimmer(size),
                      heightSpacer(size.height*0.01),
                      employeeSummryShimmer(size),
                      heightSpacer(size.height*0.01),
                      employeeSummryShimmer(size),
                      heightSpacer(size.height*0.01),
                      employeeSummryShimmer(size),
                      heightSpacer(size.height*0.01),
                    ],
                  ),
                ),
                heightSpacer(size.height*0.015),
                shimmerBox( height: size.height * 0.06,),
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size), 
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size),
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size),
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size),
                heightSpacer(size.height*0.01),
                employeeSummryShimmer(size),
                heightSpacer(size.height*0.01),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget employeeSummryShimmer(size) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      shimmerBox(height: 20, width: 100),
      heightSpacer(size.height*0.008),
      Container(
        width: size.width,
        height: size.height*0.06,
        decoration: BoxDecoration(
          border: Border.all(color: ColorConst.textBorder,width: 1)
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 10,right: 10),
        child: shimmerBox(width: size.width,height: size.height*0.04),
      ),    
    ],
  );
}

// payslip Data Shimmer
Widget payslipMasterShimmer(Size size) {
  return Padding(
    padding: EdgeInsets.all(size.width * 0.02),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerBox(height: 20, width: 100),
        heightSpacer(size.height*0.02),
        Row(
          children: [
            Expanded(child: shimmerBox(height: size.width*0.16,width: size.width,),),
            widthSpacer(size.width*0.02),
            shimmerBox(height: size.width*0.16,width: size.width*0.14,)
          ],
        ),
        heightSpacer(size.height*0.01),
        shimmerBox(height: 20, width: 100),
        heightSpacer(size.height*0.01),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            padding: EdgeInsets.only(bottom: size.height * 0.075),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                width: size.width,
                decoration: BoxDecoration(
                  color: ColorConst.white,
                  border: Border.all(color: ColorConst.grey,width: 1),
                  borderRadius: BorderRadius.circular(6.0),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConst.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: shimmerBox(height: 36),
                        ),
                        widthSpacer(size.width *0.02),
                        shimmerBox(height: 36,width: 60,),
                        widthSpacer(size.width *0.02),
                        shimmerBox(height: 36,width: 36,),
                        widthSpacer(size.width *0.02),
                        shimmerBox(height: 36,width: 36,),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
