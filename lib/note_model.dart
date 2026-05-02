import 'package:flutter/material.dart';

class Note {
  final String title;
  final String content;
  final DateTime createTime;
  final DateTime updateTime;
  final Color textColor;
  final List<String> imagePaths;
  final bool isFavorite;
  final String category;
  final List<String> tags;
  final bool hasHistoryLink;

  Note({
    required this.title,
    required this.content,
    required this.createTime,
    required this.updateTime,
    this.textColor = Colors.black,
    this.imagePaths = const [],
    this.isFavorite = false,
    this.category = '其他',
    this.tags = const [],
    this.hasHistoryLink = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'textColor': textColor.value.toString(),
      'imagePaths': imagePaths,
      'isFavorite': isFavorite,
      'category': category,
      'tags': tags,
      'hasHistoryLink': hasHistoryLink,
    };
  }

  static Note fromJson(Map<String, dynamic> json) {
    String parsedCategory = '其他';
    if (json['category'] != null) {
      String raw = json['category'].toString();
      if (raw == 'NoteCategory.work')
        parsedCategory = '代数';
      else if (raw == 'NoteCategory.life')
        parsedCategory = '几何';
      else if (raw == 'NoteCategory.study')
        parsedCategory = '微积分';
      else if (raw == 'NoteCategory.other')
        parsedCategory = '其他';
      else
        parsedCategory = raw;
    }

    return Note(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createTime: DateTime.parse(json['createTime'] ?? DateTime.now().toIso8601String()),
      updateTime: DateTime.parse(json['updateTime'] ?? json['createTime']),
      textColor: Color(
        int.parse(json['textColor'] ?? Colors.black.value.toString()),
      ),
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      category: parsedCategory,
      tags: List<String>.from(json['tags'] ?? []),
      hasHistoryLink: json['hasHistoryLink'] ?? false,
    );
  }
}