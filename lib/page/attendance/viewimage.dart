import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

class FullPageImage extends StatefulWidget {
final String image,name;
  const FullPageImage(this.image,this.name,{super.key});

  @override
  State<FullPageImage> createState() => _FullPageImageState();
}

class _FullPageImageState extends State<FullPageImage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return  Scaffold(
      appBar: AppBar(
        title: Text('IMG'),
      ),
      body: Column(
        children: [
          SizedBox(
            height:  size.height * 0.8 ,
            width: size.width,
            child: Image.network(widget.image,fit: BoxFit.cover,))
        ],
      ),
    );
  }
}

Widget buildPunchCard({
  required Size size,
  required String title,
  required String time,
  required IconData icon,
  required Color color,
  required Color gradientStart,
  required Color gradientEnd,
  required String status,
  required VoidCallback onTap,
  required bool isCompleted,
}) {
  return GestureDetector(
    onTap: isCompleted ? null : onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade200 : color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isCompleted ? null : onTap,
          child: Container(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(size.width * 0.025),
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: size.width * 0.05,
                  ),
                ),
                
                SizedBox(width: size.width * 0.04),
                
                // Title and Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: size.width * 0.032,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.grey.shade500 : color,
                              fontFamily: fontInterSemiBoldString,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (!isCompleted)
                            Container(
                              margin: EdgeInsets.only(left: size.width * 0.02),
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.02,
                                vertical: size.height * 0.003,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: size.width * 0.022,
                                  color: color,
                                  fontFamily: fontInterMediumString,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.004),
                      Text(
                        time.isEmpty ? '--:-- --' : time,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey.shade700 : ColorConst.black,
                          fontFamily: fontInterBoldString,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: size.width * 0.025,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontFamily: fontInterSemiBoldString,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
