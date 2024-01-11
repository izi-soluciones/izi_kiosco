import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

class DownloadUtils{
  Future<bool> _checkPermission() async {
    if(kIsWeb){
      return true;
    }
    if(Platform.isAndroid){
      DeviceInfoPlugin plugin = DeviceInfoPlugin();
      AndroidDeviceInfo android = await plugin.androidInfo;
      if(android.version.sdkInt >=33){
        return true;
      }
    }
    await Permission.storage.request();
    var per=await Permission.storage.request().isGranted;
    if(per){
      return per;
    }
    else{
      await Permission.storage.request();
    }
    return await Permission.storage.request().isGranted;
  }
  Future<String?> _getSavedDir() async {
    String? externalStorageDirPath;

    if (Platform.isAndroid) {
      try {
        externalStorageDirPath = (await getDownloadsDirectory())?.path;
      } catch (err,_) {
        final directory = await getExternalStorageDirectory();
        externalStorageDirPath = directory?.path;
      }
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }
    return externalStorageDirPath;
  }
  Future<bool> saveFileLocal(Uint8List bytes,String fileName)async{
    try{

      bool permission=await _checkPermission();
      if(!permission){
        throw "Error";
      }

      if(kIsWeb){
        Printing.layoutPdf(onLayout: (format)=>bytes);
      }else{
        String route="${(await _getSavedDir()??"/")}/$fileName";
        await File(route).writeAsBytes(bytes);
        await OpenFile.open(route, type: 'application/pdf');
      }
      return true;
    }
    catch(error){
      debugPrint(error.toString());
      return false;
    }

  }
  Future<File?> downloadFile(String url)async{
    try{

      bool permission=await _checkPermission();
      if(!permission){
        throw "Error";
      }

      if(kIsWeb){
        return null;
      }else{

        String fileName = url.split("/").last;
        String route="${(await _getSavedDir()??"/")}/$fileName";
        var file = File(route);
        if(await file.exists()){
          return file;
        }
        else{
          var data = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
          if(data.data is List<int>){
            await file.writeAsBytes(data.data);
            return file;
          }
        }
      }
      return null;
    }
    catch(error){
      debugPrint(error.toString());
      return null;
    }

  }
  Future<bool> downloadFilePdf(String url)async{
    try{

      bool permission=await _checkPermission();
      if(!permission){
        throw "Error";
      }

      if(kIsWeb){
        html.window.open(url, "_blank");
      }else{

        String fileName = url.split("/").last;
        String route="${(await _getSavedDir()??"/")}/$fileName";
        await Dio().download(url, route,);
        await OpenFile.open(route, type: 'application/pdf');
      }
      return true;
    }
    catch(error){
      debugPrint(error.toString());
      return false;
    }

  }
}