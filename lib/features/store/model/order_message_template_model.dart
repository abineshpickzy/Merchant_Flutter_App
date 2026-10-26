import 'package:equatable/equatable.dart';

/// Data model representing predefined customer notification message template from `POST order/msgTemplate`.
class OrderMessageTemplateModel extends Equatable {
  final String title;
  final String message;

  const OrderMessageTemplateModel({
    required this.title,
    required this.message,
  });

  factory OrderMessageTemplateModel.fromJson(Map<String, dynamic> json) {
    return OrderMessageTemplateModel(
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [title, message];
}
