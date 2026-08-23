// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:bam_bam_driver/app/app.dart';
// import 'package:bam_bam_driver/app/navigators/navigators.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';

// // ignore: must_be_immutable
// class ThumbNailImageFullpage extends StatefulWidget {
//   final String? url;
//   BoxFit? fit;
//   ThumbNailImageFullpage({super.key, required this.url, required this.fit});

//   @override
//   ThumbNailImageFullpageState createState() => ThumbNailImageFullpageState();
// }

// class ThumbNailImageFullpageState extends State<ThumbNailImageFullpage> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var thumbnailRequest = ThumbnailRequest(
//       video: (widget.url ?? ''),
//       thumbnailPath: null,
//       imageFormat: ImageFormat.JPEG,
//       maxHeight: 300,
//       maxWidth: 300,
//       quality: 100,
//     );
//     return FutureBuilder<ThumbnailResult>(
//       future: genThumbnail(thumbnailRequest, widget.fit ?? BoxFit.fitHeight),
//       builder: (BuildContext context, AsyncSnapshot snapshot) {
//         if (snapshot.hasData) {
//           final image = snapshot.data.image;
//           return GestureDetector(
//             onTap: () {
//               // RouteManagement.goToShowFullScareenImage(
//               //     widget.url ?? '', "video");
//             },
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(5.0),
//               child: image,
//             ),
//           );
//         } else {
//           return Center(
//             child: CircularProgressIndicator(color: ColorsValue.appColor),
//           );
//         }
//       },
//     );
//   }
// }

// class ThumbnailResult {
//   final Image? image;
//   final int? dataSize;
//   final int? height;
//   final int? width;
//   const ThumbnailResult({this.image, this.dataSize, this.height, this.width});
// }

// Future<ThumbnailResult> genThumbnail(ThumbnailRequest r, BoxFit fit) async {
//   //WidgetsFlutterBinding.ensureInitialized();
//   Uint8List? bytes;
//   final Completer<ThumbnailResult> completer = Completer();

//   if (r.thumbnailPath != null) {
//   } else {
//     bytes = await VideoThumbnail.thumbnailData(
//       video: r.video!,
//       imageFormat: r.imageFormat!,
//       maxHeight: r.maxHeight!,
//       maxWidth: r.maxWidth!,
//       quality: r.quality!,
//     );
//   }




//   // final fileName = await VideoThumbnail.thumbnailFile(
//   //   video: r.video!,
//   //   thumbnailPath: (await getTemporaryDirectory()).path,
//   //   imageFormat: ImageFormat.PNG,
//   //   maxHeight: r.maxWidth!,
//   //   quality: 100,
//   // );

//   int imageDataSize = bytes!.length;

//   final image = Image.memory(bytes, fit: fit);
//   image.image
//       .resolve(const ImageConfiguration())
//       .addListener(
//         ImageStreamListener((ImageInfo info, bool _) {
//           completer.complete(
//             ThumbnailResult(
//               image: image,
//               dataSize: imageDataSize,
//               height: info.image.height,
//               width: info.image.width,
//             ),
//           );
//         }),
//       );
//   return completer.future;
// }

// class ThumbnailRequest {
//   final String? video;
//   final String? thumbnailPath;  



//   final ImageFormat? imageFormat;
//   final int? maxHeight;
//   final int? maxWidth;
//   final int? timeMs;
//   final int? quality;
//
//   const ThumbnailRequest({
//     this.video,
//     this.thumbnailPath,
//     this.imageFormat,
//     this.maxHeight,
//     this.maxWidth,
//     this.timeMs,
//     this.quality,
//   });
// }
