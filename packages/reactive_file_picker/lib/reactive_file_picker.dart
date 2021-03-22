library reactive_file_picker;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_file_picker/multi_file.dart';
import 'package:reactive_forms/reactive_forms.dart';

export 'package:reactive_file_picker/multi_file.dart';
export 'package:file_picker/file_picker.dart';

typedef Future<void> PickFileCallback();
typedef void FilePickerChangeCallback<T>(MultiFile<T> files);

typedef Widget FilePickerBuilder<T>(
  PickFileCallback pickImage,
  MultiFile<T> files,
  FilePickerChangeCallback<T> onChange,
);

/// A [ReactiveFilePicker] that contains a [TouchSpin].
///
/// This is a convenience widget that wraps a [TouchSpin] widget in a
/// [ReactiveFilePicker].
///
/// A [ReactiveForm] ancestor is required.
///
class ReactiveFilePicker<T> extends ReactiveFormField<MultiFile<T>> {
  /// Creates a [ReactiveFilePicker] that contains a [TouchSpin].
  ///
  /// Can optionally provide a [formControl] to bind this widget to a control.
  ///
  /// Can optionally provide a [formControlName] to bind this ReactiveFormField
  /// to a [FormControl].
  ///
  /// Must provide one of the arguments [formControl] or a [formControlName],
  /// but not both at the same time.
  ///
  /// Can optionally provide a [validationMessages] argument to customize a
  /// message for different kinds of validation errors.
  ///
  /// Can optionally provide a [valueAccessor] to set a custom value accessors.
  /// See [ControlValueAccessor].
  ///
  /// Can optionally provide a [showErrors] function to customize when to show
  /// validation messages. Reactive Widgets make validation messages visible
  /// when the control is INVALID and TOUCHED, this behavior can be customized
  /// in the [showErrors] function.
  ///
  /// ### Example:
  /// Binds a text field.
  /// ```
  /// final form = fb.group({'email': Validators.required});
  ///
  /// ReactiveFilePicker(
  ///   formControlName: 'email',
  /// ),
  ///
  /// ```
  ///
  /// Binds a text field directly with a *FormControl*.
  /// ```
  /// final form = fb.group({'email': Validators.required});
  ///
  /// ReactiveFilePicker(
  ///   formControl: form.control('email'),
  /// ),
  ///
  /// ```
  ///
  /// Customize validation messages
  /// ```dart
  /// ReactiveFilePicker(
  ///   formControlName: 'email',
  ///   validationMessages: {
  ///     ValidationMessage.required: 'The email must not be empty',
  ///     ValidationMessage.email: 'The email must be a valid email',
  ///   }
  /// ),
  /// ```
  ///
  /// Customize when to show up validation messages.
  /// ```dart
  /// ReactiveFilePicker(
  ///   formControlName: 'email',
  ///   showErrors: (control) => control.invalid && control.touched && control.dirty,
  /// ),
  /// ```
  ///
  /// For documentation about the various parameters, see the [TouchSpin] class
  /// and [new TouchSpin], the constructor.
  ReactiveFilePicker({
    Key key,
    String formControlName,
    InputDecoration decoration,
    FormControl formControl,
    ValidationMessagesFunction validationMessages,
    ControlValueAccessor valueAccessor,
    ShowErrorsFunction showErrors,
    //
    FilePickerBuilder<T> filePickerBuilder,
    bool allowMultiple = false,
    FileType type = FileType.any,
    List<String> allowedExtensions,
    Function(FilePickerStatus) onFileLoading,
    bool allowCompression,
    bool withData,
    bool withReadStream,
  }) : super(
          key: key,
          formControl: formControl,
          formControlName: formControlName,
          valueAccessor: valueAccessor,
          validationMessages: validationMessages,
          showErrors: showErrors,
          builder: (ReactiveFormFieldState field) {
            final value = field.value as MultiFile<T> ?? MultiFile<T>();
            final InputDecoration effectiveDecoration = (decoration ??
                    const InputDecoration())
                .applyDefaults(Theme.of(field.context).inputDecorationTheme);

            String pickerError;

            final pickFile = () async {
              List<PlatformFile> platformFiles;
              try {
                platformFiles = (await FilePicker.platform.pickFiles(
                  allowMultiple: allowMultiple,
                  type: type,
                  allowedExtensions: allowedExtensions,
                  onFileLoading: onFileLoading,
                  allowCompression: allowCompression,
                  withData: withData,
                  withReadStream: withReadStream,
                ))
                    ?.files;
              } on PlatformException catch (e) {
                pickerError = "Unsupported operation" + e.toString();
              } catch (e) {
                pickerError = e.toString();
              }

              field.control.markAsTouched();
              field.didChange(value.copyWith(platformFiles: platformFiles));
            };

            return InputDecorator(
              decoration: effectiveDecoration.copyWith(
                errorText: field.errorText ?? pickerError,
                enabled: field.control.enabled,
              ),
              child: filePickerBuilder?.call(pickFile, value, (files) {
                field.control.markAsTouched();
                field.didChange(files);
              }),
            );
          },
        );
}