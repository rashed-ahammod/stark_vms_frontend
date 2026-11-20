import 'package:json_annotation/json_annotation.dart';

part 'page_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.hasNext,
    required this.totalElements,
  });

  final List<T> content;
  final bool hasNext;
  final int totalElements;

  bool get last => !hasNext;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PageResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}
