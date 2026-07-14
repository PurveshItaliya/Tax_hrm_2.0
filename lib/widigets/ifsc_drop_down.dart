// ignore_for_file: use_build_context_synchronously, must_be_immutable

import 'package:tax_hrm/widigets/app_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/ifsc/ifsc_model.dart';
import 'package:tax_hrm/provider/ifsc_provider.dart';
import 'package:tax_hrm/utils/FixText.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

class IfscCodeDropdown extends StatefulWidget {
  IfscListModel? ifscList;
  Function onagentSelection;
  Function onAgentClear;
  IfscCodeDropdown(this.ifscList,this.onagentSelection, this.onAgentClear,{super.key});

  @override
  State<IfscCodeDropdown> createState() => _IfscCodeDropdownState();
}

class _IfscCodeDropdownState extends State<IfscCodeDropdown> {
  Future<List<IfscListModel>> getFilterIfsc(String ss) async {
    return await Future.delayed(const Duration(seconds: 1), () {
      return Provider.of<IfscMastServices>(context, listen: false)
          .getallIfscDataList
          .where((e) {
        return e.branchName.toString().toLowerCase().contains(ss.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ifscProvider = Provider.of<IfscMastServices>(context);
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectIfscCodeString,
            style: normalHeadingText(size),
          ),
          heightSpacer(size.height * 0.008), // Reduced from 0.01 to 0.008
          SizedBox(
            height: size.height * 0.067, // Reduced from 0.07 to 0.067
            child: AppSearchableDropdown<IfscListModel>(
              dropdownKey: ValueKey(widget.ifscList),
              initialItem: widget.ifscList,
              hintText: selectIfscString,
              futureRequest: getFilterIfsc,
              items: ifscProvider.getallIfscDataList,
              itemAsString: (item) => item.iFSC.toString(),
              headerBuilder: (context, selectedItem, enabled) {
                return Row(
                  children: [
                    Text(widget.ifscList == null
                        ? selectIfscCodeString
                        : widget.ifscList!.iFSC.toString()),
                    const Spacer(),
                    widget.ifscList == null
                        ? Container()
                        : Transform.translate(
                      offset: Offset(0, -size.width * 0.017),
                      child: IconButton(
                          onPressed: () {
                            widget.ifscList = null;
                            widget.onAgentClear();
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            size: size.height * 0.02,
                          )),
                    )
                  ],
                );
              },
              onChanged: (vals) {
                setState(() {
                  widget.ifscList = vals;
                  widget.onagentSelection(vals);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
