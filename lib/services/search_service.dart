import 'package:leancloud_storage/leancloud.dart';
import '../models/project_post_model.dart';
import '../models/talent_post_model.dart';
import '../services/feed_service.dart';

class SearchService {
  final FeedService _feedService = FeedService();
  
  // 搜索项目和人才帖子
  Future<Map<String, dynamic>> search(String keyword, {int skip = 0, int limit = 10}) async {
    if (keyword.isEmpty) {
      return {
        'results': <dynamic>[],
        'totalHits': 0,
        'hasMore': false,
        'currentSkip': skip
      };
    }

    try {
      print('SearchService.search - 开始搜索关键词: $keyword, skip: $skip, limit: $limit');

      // 使用FeedService的search方法获取搜索结果
      final searchResponse = await _feedService.search(keyword, skip: skip, limit: limit);
      final lcObjects = searchResponse['results'] as List<dynamic>;
      final totalHits = searchResponse['totalHits'] as int;
      final hasMore = searchResponse['hasMore'] as bool;
      final currentSkip = searchResponse['currentSkip'] as int;
      
      print('SearchService.search - 搜索API返回结果数量: ${lcObjects.length}');
      print('SearchService.search - 总命中数: $totalHits, 是否有更多: $hasMore, 当前skip: $currentSkip');
      
      // 将结果转换为适当的模型对象
      List<dynamic> results = [];
      
      for (var obj in lcObjects) {
        try {
          if (obj is LCObject) {
            if (obj.className == 'ProjectPost') {
              final projectPost = ProjectPost.fromLCObject(obj);
              results.add(projectPost);
              print('SearchService.search - 添加ProjectPost: ${projectPost.projectName}, ID: ${projectPost.objectId}');
            } else if (obj.className == 'TalentPost') {
              final talentPost = TalentPost.fromLCObject(obj);
              results.add(talentPost);
              print('SearchService.search - 添加TalentPost: ${talentPost.title}, ID: ${talentPost.objectId}');
            } else {
              print('SearchService.search - 未知类型: ${obj.className}');
            }
          } else {
            print('SearchService.search - 非LCObject类型: ${obj.runtimeType}');
          }
        } catch (e) {
          print('SearchService.search - 转换搜索结果出错: $e');
          print('错误堆栈: ${StackTrace.current}');
          // 跳过转换失败的对象
        }
      }
      
      print('SearchService.search - 全文搜索结果数量: ${results.length}');
      
      return {
        'results': results,
        'totalHits': totalHits,
        'hasMore': hasMore,
        'currentSkip': currentSkip
      };
    } catch (e) {
      print('SearchService.search - 搜索出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      return {
        'results': <dynamic>[],
        'totalHits': 0,
        'hasMore': false,
        'currentSkip': skip
      }; // 返回空结果而不是抛出异常，以便UI层可以正常处理
    }
  }
} 