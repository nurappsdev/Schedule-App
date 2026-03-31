import 'package:flutter/material.dart';


class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    this.maxline,
    this.textOverflow,
    this.fontName,
    this.textAlign = TextAlign.center,
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0,
    this.fontsize,
    this.textHeight,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.text = "",
    this.fontStyle = FontStyle.normal,
  });

  final double left;
  final TextOverflow? textOverflow;
  final double right;
  final double top;
  final double bottom;
  final double? fontsize;
  final FontWeight fontWeight;
  final Color? color;
  final String text;
  final TextAlign textAlign;
  final int? maxline;
  final String? fontName;
  final double? textHeight;
  final FontStyle fontStyle;

  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Base design width (you can change it based on your design, e.g. 375 for iPhone)
    const double baseWidth = 375;

    return (screenWidth / baseWidth) * baseFontSize;
  }

  @override
  Widget build(BuildContext context) {
    final double finalFontSize =
    _getResponsiveFontSize(context, fontsize ?? 14);

    return Padding(
      padding: EdgeInsets.only(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
      ),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxline,
        overflow: textOverflow ?? TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: finalFontSize,
          height: textHeight,
          fontFamily: fontName ?? "Montserrat-Light",
          fontWeight: fontWeight,
          color: color ?? Colors.black,
          fontStyle: fontStyle,
        ),
      ),
    );
  }
}