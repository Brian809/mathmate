import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoInfo {
  final String title;
  final String subtitle;
  final String bvId;
  final List<String> keywords;
  String? _coverUrl;

  VideoInfo({
    required this.title,
    required this.subtitle,
    required this.bvId,
    required this.keywords,
  });

  String get url =>
      'https://www.bilibili.com/video/$bvId/?spm_id_from=333.337.search-card.all.click&vd_source=5d6add47d5117935b61df3a47eaa2266';

  Future<String> getCoverUrl() async {
    if (_coverUrl != null) return _coverUrl!;

    try {
      final String apiUrl =
          'https://api.bilibili.com/x/web-interface/view?bvid=$bvId';
      final http.Response response = await http
          .get(Uri.parse(apiUrl), headers: <String, String>{
            'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            'Referer': 'https://www.bilibili.com/',
          })
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['code'] == 0 && data['data'] != null) {
          _coverUrl = data['data']['pic'] as String?;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to fetch cover for $bvId: $e');
    }

    return _coverUrl ?? '';
  }
}

final List<VideoInfo> allVideos = <VideoInfo>[
  // 小学
  VideoInfo(
    title: '小学数学基础',
    subtitle: '夯实基础很重要',
    bvId: 'BV12A9cBmExK',
    keywords: <String>['小学', '基础', '计算', '加减乘除'],
  ),
  VideoInfo(
    title: '小学奥数思维',
    subtitle: '拓展数学思维',
    bvId: 'BV1p1rQYbEYb',
    keywords: <String>['小学', '奥数', '思维', '拓展'],
  ),

  // 初中
  VideoInfo(
    title: '初中数学几何',
    subtitle: '几何证明与计算',
    bvId: 'BV17T4y1E7Kt',
    keywords: <String>['初中', '几何', '证明', '三角形', '全等', '相似'],
  ),
  VideoInfo(
    title: '初中代数专题',
    subtitle: '方程与函数',
    bvId: 'BV1gJ411v78Z',
    keywords: <String>['初中', '代数', '方程', '函数', '一次函数', '二次函数'],
  ),

  // 高中
  VideoInfo(
    title: '导数大题拆解',
    subtitle: '导数题型精讲',
    bvId: 'BV1ij96BGE53',
    keywords: <String>['高中', '导数', '函数', '极值', '单调性'],
  ),
  VideoInfo(
    title: '正弦余弦定理',
    subtitle: '解三角形必学',
    bvId: 'BV1bJ4m177Wb',
    keywords: <String>['高中', '正弦', '余弦', '解三角形', '三角函数'],
  ),
  VideoInfo(
    title: '数列求通项公式',
    subtitle: '数列题型归纳',
    bvId: 'BV1E4c4ePEJT',
    keywords: <String>['高中', '数列', '通项', '递推', '求和'],
  ),
  VideoInfo(
    title: '三角函数基础',
    subtitle: '从入门到掌握',
    bvId: 'BV1622LBFEv7',
    keywords: <String>['高中', '三角函数', '基础', '正弦', '余弦'],
  ),
  VideoInfo(
    title: '三角函数母题精讲',
    subtitle: '攻克三角函数大题',
    bvId: 'BV1xZoxBZEGJ',
    keywords: <String>['高中', '三角函数', '母题', '大题', '综合'],
  ),
  VideoInfo(
    title: '基本不等式技巧',
    subtitle: '不等式核心方法',
    bvId: 'BV1hBm8BRE7J',
    keywords: <String>['高中', '不等式', '基本不等式', '技巧', '均值'],
  ),
  VideoInfo(
    title: '错位相减法',
    subtitle: '数列求和必杀技',
    bvId: 'BV1byZtBuEV1',
    keywords: <String>['高中', '数列', '错位相减', '求和', '技巧'],
  ),
  VideoInfo(
    title: '集合与逻辑基础',
    subtitle: '集合运算与命题',
    bvId: 'BV15XHdehEk7',
    keywords: <String>['高中', '集合', '逻辑', '命题', '基础'],
  ),
  VideoInfo(
    title: '恒等变换技巧',
    subtitle: '三角恒等变换',
    bvId: 'BV1544y1774z',
    keywords: <String>['高中', '恒等变换', '三角函数', '公式', '技巧'],
  ),
  VideoInfo(
    title: '复数专题',
    subtitle: '复数运算与应用',
    bvId: 'BV1YV4y1f7vY',
    keywords: <String>['高中', '复数', '运算', '模', '几何意义'],
  ),
  VideoInfo(
    title: '高考数学复习大全',
    subtitle: '高考全面复习',
    bvId: 'BV1nJ411G79Z',
    keywords: <String>['高中', '高考', '复习', '综合', '真题'],
  ),
  VideoInfo(
    title: '不等式同步讲解',
    subtitle: '不等式全题型',
    bvId: 'BV1FCbcevEfv',
    keywords: <String>['高中', '不等式', '同步', '讲解', '题型'],
  ),
  VideoInfo(
    title: '高中解析几何',
    subtitle: '圆锥曲线专题',
    bvId: 'BV1d8qaBkEVJ',
    keywords: <String>['高中', '解析几何', '椭圆', '双曲线', '抛物线', '圆锥曲线'],
  ),
  VideoInfo(
    title: '高中概率统计',
    subtitle: '概率与分布',
    bvId: 'BV1Me411P7tx',
    keywords: <String>['高中', '概率', '统计', '分布', '随机变量'],
  ),
];

List<VideoInfo> getVideosByGrade(int? grade) {
  if (grade == null) return <VideoInfo>[];

  if (grade >= 1 && grade <= 6) {
    return allVideos.where((v) => v.keywords.contains('小学')).toList();
  } else if (grade >= 7 && grade <= 9) {
    return allVideos.where((v) => v.keywords.contains('初中')).toList();
  } else if (grade >= 10 && grade <= 12) {
    return allVideos.where((v) => v.keywords.contains('高中')).toList();
  }
  return <VideoInfo>[];
}

List<VideoInfo> getVideosByKeywords(List<String> keywords) {
  if (keywords.isEmpty) return <VideoInfo>[];

  final List<VideoInfo> matched = <VideoInfo>[];
  for (final VideoInfo video in allVideos) {
    for (final String keyword in keywords) {
      if (video.keywords
          .any((k) => k.toLowerCase().contains(keyword.toLowerCase()))) {
        matched.add(video);
        break;
      }
    }
  }
  return matched;
}
