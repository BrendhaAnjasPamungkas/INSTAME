import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class MainWidget {
  Widget text({
    required String data,
    int? maxLines,
    TextOverflow? overflow,
    bool? softWrap,
    TextStyle? style,
    TextAlign? textAlign,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    style ??= GoogleFonts.poppins();

    return Text(
      data,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: style.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
    );
  }

  Widget richText({
    required List<InlineSpan> children,
    int? maxLines,
    TextOverflow? overflow,
    bool? softWrap,
    TextAlign? textAlign,
    TextStyle? style,
    Color? defaultColor,
    double? defaultFontSize,
    FontWeight? defaultFontWeight,
  }) {
    overflow ??= TextOverflow.clip;
    softWrap = true;
    TextAlign textAlign = TextAlign.start;
    style ??= GoogleFonts.poppins();

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textAlign: textAlign,
      text: TextSpan(
        style: style.copyWith(
          color: defaultColor,
          fontSize: defaultFontSize,
          fontWeight: defaultFontWeight,
        ),
        children: children,
      ),
    );
  }

  TextSpan textSpan({
    required String text,
    TextStyle? style,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    style ??= GoogleFonts.poppins();

    return TextSpan(
      style: style.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      text: text,
    );
  }

  Widget textField({
    Widget? Function(
      BuildContext, {
      required int currentLength,
      required bool isFocused,
      required int? maxLength,
    })?
    buildCounter,
    FocusNode? focusNode,
    InputBorder? focusedBorder,
    TextEditingController? controller,
    Color? cursorColor,
    bool? enabled,
    Widget Function(BuildContext, String)? errorBuilder,
    bool? expands,
    String? initialValue,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    int? maxLength,
    int? maxLines,
    int? minLines,
    bool? obscureText,
    Function(String?)? onChanged,
    Function(String?)? onFieldSubmitted,
    void Function()? onTap,
    bool? readOnly,
    TextStyle? style,
    TextAlign? textAlign,
    String? Function(String?)? validator,
    EdgeInsetsGeometry? contentPadding,
    Color? fillColor,
    Widget? hint,
    bool? isDense,
    Widget? label,
    Widget? prefix,
    Widget? suffix,
    TextStyle? counterStyle,
    TextStyle? errorStyle,
    Color? fontColor,
    double? fontSize,
    FontWeight? fontWeigt,
    Color? counterFontColor,
    double? counterFontSize,
    FontWeight? counterFontWeight,
    Color? errorFontColor,
    double? errorFontSize,
    FontWeight? errorFontWeight,
    InputBorder? disabledBorder,
    InputBorder? enabledBorder,
    InputBorder? errorBorder,
    
  }) {
    expands ??= false;
    obscureText ??= false;
    readOnly ??= false;
    style ??= GoogleFonts.poppins();
    textAlign ??= TextAlign.start;
    counterStyle ??= GoogleFonts.poppins();
    errorStyle ??= GoogleFonts.poppins();

    void onTapOutside(PointerDownEvent _) {
      FocusManager.instance.primaryFocus!.unfocus();
    }

    return TextFormField(
      focusNode: focusNode,
      buildCounter: buildCounter,
      controller: controller,
      cursorColor: cursorColor,
      decoration: InputDecoration(
        contentPadding: contentPadding,
        counterStyle: counterStyle.copyWith(
          color: counterFontColor,
          fontSize: counterFontSize,
          fontWeight: counterFontWeight,
        ),
        disabledBorder: disabledBorder,
        enabledBorder: enabledBorder,
        errorBorder: errorBorder,
        errorStyle: errorStyle.copyWith(
          color: errorFontColor,
          fontSize: errorFontSize,
          fontWeight: errorFontWeight,
        ),
        fillColor: fillColor,
        filled: true,
        focusedBorder: focusedBorder,
        hint: hint,
        isDense: isDense,
        label: label,
        prefix: prefix,
        suffix: suffix,
      ),
      enabled: enabled,
      errorBuilder: errorBuilder,
      expands: expands,
      initialValue: initialValue,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      onTapOutside: onTapOutside,
      readOnly: readOnly,
      style: style.copyWith(
        color: fontColor,
        fontSize: fontSize,
        fontWeight: fontWeigt,
      ),
      textAlign: textAlign,
      validator: validator,
    );
  }

  Widget checkbox({
    required bool value,
    required void Function(bool?)? onChanged,
    Color? checkColor,
    BorderRadiusGeometry? borderRadius,
    BorderSide? side,
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? overlayColor,
  }) {
    borderRadius ??= BorderRadius.zero;

    return Checkbox(
      value: value,
      onChanged: onChanged,
      checkColor: checkColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      side: side,
      fillColor: fillColor,
      overlayColor: overlayColor,
    );
  }

  Widget radio({
    required bool value,
    required dynamic groupValue,
    required ValueChanged<Object?>? onChanged,
    bool? toggleable,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<Color?>? fillColor,
  }) {
    toggleable ??= false;

    return Radio(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      toggleable: toggleable,
      overlayColor: overlayColor,
      fillColor: fillColor,
    );
  }

  Widget swicth({
    required bool value,
    required Function(bool?)? onChanged,
    WidgetStateProperty<Color?>? thumbColor,
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<Icon?>? thumbIcon,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: thumbColor,
      trackColor: trackColor,
      overlayColor: overlayColor,
      thumbIcon: thumbIcon,
    );
  }

  Widget dropDownButton({
    required dynamic value,
    required List<DropdownMenuItem<dynamic>>? items,
    required void Function(dynamic)? onChanged,
    AlignmentGeometry alignment = AlignmentDirectional.centerStart,
    BorderRadius? borderRadius,
    Color? dropdownColor,
    Widget? icon,
    bool? isDense,
    bool? isExpanded,
    EdgeInsetsGeometry? padding,
    TextStyle? style,
    EdgeInsetsGeometry? contentPadding,
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    Color? fontColor,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    isDense ??= true;
    isExpanded ??= true;
    style ??= GoogleFonts.poppins();
    enabledBorder ??= OutlineInputBorder();
    focusedBorder ??= OutlineInputBorder();

    return DropdownButtonFormField(
      value: value,
      items: items,
      onChanged: onChanged,
      alignment: alignment,
      borderRadius: borderRadius,
      decoration: InputDecoration(
        contentPadding: contentPadding,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
      ),
      dropdownColor: dropdownColor,
      icon: icon,
      isDense: isDense,
      isExpanded: isExpanded,
      padding: padding,
      style: style.copyWith(
        color: fontColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }

  Widget button({
    required Function() onPressed,
    required Widget child,
    double? width,
    Function()? onLongPress,
    Color? backgroundColor,
    Color? disabledBackgroundColor,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? borderRadius,
    Color? borderColor,
    double? borderWidth,
    bool? enabled, 
  }) {
    enabled ??= true;
    borderRadius ??= BorderRadius.circular(16);
    borderColor ??= Color(0x00000000);
    borderWidth ??= 1.0;

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        onLongPress: enabled ? onLongPress : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        child: child,
      ),
    );
  }

  Widget gap({double? height, double? width}) {
    return SizedBox(height: height, width: width);
  }
}

MainWidget get W => MainWidget();
