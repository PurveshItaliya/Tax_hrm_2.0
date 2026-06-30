import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

class LeaveRejectCard extends StatelessWidget {
  final String name;
  final String reason;
  final String date;
  final String status;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LeaveRejectCard({
    super.key,
    required this.name,
    required this.reason,
    required this.date,
    this.status = "Rejected",
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: ColorConst.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              /// TOP ACTION BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _iconBtn(Icons.edit_outlined, Colors.blue, onEdit),
                      const SizedBox(width: 8),
                      _iconBtn(Icons.delete_outline, Colors.red, onDelete),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildRow(Icons.person_outline, "Name", name),
              const SizedBox(height: 10),
              _buildRow(Icons.description_outlined, "Reason", reason),
              const SizedBox(height: 10),
              _buildRow(Icons.calendar_month_outlined, "Date", date),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade200),
              _buildRow(
                Icons.cancel_outlined,
                "Status",
                status,
                valueColor: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildRow(
    IconData icon,
    String title,
    String value, {
    Color valueColor = Colors.black87,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 10),
        SizedBox(
          width: 65,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}