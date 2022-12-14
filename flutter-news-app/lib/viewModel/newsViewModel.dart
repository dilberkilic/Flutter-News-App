import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news_app/model/newsModel.dart';
import 'package:flutter_news_app/viewModel/pageStatus.dart';
import 'package:http/http.dart' as http;

//haberleri genel olarak control edecegimiz yapı
class NewsViewModel {
  //eklenen news üyelerini api'den çektiten sonra bu news listesine ekliyoruz.
  List<NewsModel> news = [];
  final String baseUrl = 'https://newsapi.org/v2/everything?q=';
  final String apiKey = '65e7cffb1deb4c3c84a25c54c4e41f49';
  int pageKey=1;
  int perPage=30;
  ValueNotifier<PageStatus> pageStatus = ValueNotifier<PageStatus>(
      PageStatus.idle);

  //pagination durumlarını yazdığımız bu kontrollerle sağlamaktayız.

  Future getInitialNewsSearch(String keyword) async {
   pageStatus.value=PageStatus.firstPageLoading;
   try{
   await getNews(keyword, 1);
   if(news.isEmpty){
     pageStatus.value=PageStatus.firstPageNoItemsFound;
   }else{
     pageStatus.value=PageStatus.firstPageLoaded;
   }
   }catch(e){
     pageStatus.value=PageStatus.firstPageError;
   }
  }
  Future getInitialNews() async {
    pageStatus.value=PageStatus.firstPageLoading;
    try{
      await getNewsGeneral(1);
      if(news.isEmpty){
        pageStatus.value=PageStatus.firstPageNoItemsFound;
      }else{
        pageStatus.value=PageStatus.firstPageLoaded;
      }
    }catch(e){
      pageStatus.value=PageStatus.firstPageError;
    }
  }
  Future loadMoreNewsSearch(String keyword) async {
    pageStatus.value=PageStatus.newPageLoading;
    pageKey++;
    print(pageKey);
    try{
      int currentNewsCount=news.length;
      await getNews(keyword, pageKey);

      if(currentNewsCount == news.length){
        pageStatus.value=PageStatus.newPageNoItemsFound;
      }else{
        pageStatus.value=PageStatus.newPageLoaded;
      }
    }catch(e){
      pageStatus.value=PageStatus.newPageError;
    }
  }

  Future loadMoreNews() async {
    pageStatus.value=PageStatus.newPageLoading;
    pageKey++;
    print(pageKey);
    try{
      int currentNewsCount=news.length;
      await getNewsGeneral(pageKey);

      if(currentNewsCount == news.length){
        pageStatus.value=PageStatus.newPageNoItemsFound;
      }else{
        pageStatus.value=PageStatus.newPageLoaded;
      }
    }catch(e){
      pageStatus.value=PageStatus.newPageError;
    }
  }

  Future<void> getNews(String keyword, int page) async {
    //Kullanıcıdan alınan keyword ve page bilgileri ile api adresi olusturuluyor.
    var response = await http.get(
        Uri.parse('$baseUrl$keyword&pageSize=$perPage&page=$page&apiKey=$apiKey'));
    var jsonData = jsonDecode(response.body);

    //status yerine statusCode=200 kontrolü de yapılabilir.
    if (jsonData['status'] == 'ok') {
      jsonData['articles'].forEach((element) {
        if (element['urlToImage'] != null && element['description'] != null) {
          NewsModel newsModel = NewsModel(
            element['title'],
            element['description'],
            element['publishedAt'],
            element['urlToImage'],
            element['url'],
            element['source']['name'],
          );
          //Parse edilen datalar news listesine aktarılıyor. Viewsler ile direkt bu listeye erisiyoruz.
          news.add(newsModel);
        }
      });
    }
  }

  //Anasayfada kullanıcı herhangi bir arama yapmadığı durumda karşısına çıkacak ekran için bu metodu kullanıyoruz.
  //US gündemidnen önce çıkan haberleri getiriyor. Farklı etiketler verilerek değiştirilebilir.
  Future<void> getNewsGeneral(int pageKey) async {
    var response = await http.get(Uri.parse(
        'https://newsapi.org/v2/top-headlines?country=us&pageSize=$perPage&page=$pageKey&apiKey=$apiKey'));
    var jsonData = jsonDecode(response.body);

    if (jsonData['status'] == 'ok') {
      jsonData['articles'].forEach((element) {
        if (element['urlToImage'] != null && element['description'] != null) {
          NewsModel newsModel = NewsModel(
            element['title'],
            element['description'],
            element['publishedAt'],
            element['urlToImage'],
            element['url'],
            element['source']['name'],
          );

          news.add(newsModel);
        }
      });
    }
  }
}
