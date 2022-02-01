import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_stack/flutter_image_stack.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart' as imp;
import 'package:photo_gallery_app/post_Controller.dart';
import 'package:photo_view/photo_view.dart';
import 'package:progress_loader_overlay/progress_loader_overlay.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final imp.ImagePicker _imagePicker = imp.ImagePicker();
  final List<String> _images = [
    'https://images.unsplash.com/photo-1593642532842-98d0fd5ebc1a?ixid=MXwxMjA3fDF8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=2250&q=80',
    'https://images.unsplash.com/photo-1612594305265-86300a9a5b5b?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1612626256634-991e6e977fc1?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1712&q=80',
    'https://images.unsplash.com/photo-1593642702749-b7d2a804fbcf?ixid=MXwxMjA3fDF8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1400&q=80'
  ];

  final PostController _postController = PostController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<File?> cropImage({required File imageFile}) async {
    return await ImageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: const AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: const IOSUiSettings(
            minimumAspectRatio: 1.0, title: 'Image Cropper'));
  }

  submitPost(File myCroppedFile, BuildContext context) async {
    //upload file to firebase storage
    bool isSuccessful = await _postController.submitPost(image: myCroppedFile);

    //dismiss progress loader
    await ProgressLoader().dismiss();
    if (isSuccessful) {
      print('Success');

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Post Uploaded Successfully",
              style: TextStyle(color: Colors.green))));
    } else {
      print('Error');

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error Uploading Post",
              style: TextStyle(color: Colors.red))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          "Gallery",
          style: TextStyle(color: Colors.blue),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(15))),
                    builder: (context) {
                      return SizedBox(
                        height: 150,
                        child: Column(
                          children: [
                            TextButton.icon(
                                onPressed: () async {
                                  final imp.XFile? xfile =
                                      await _imagePicker.pickImage(
                                          source: imp.ImageSource.camera);
                                  if (xfile != null) {
                                    File? myCroppedFile = await cropImage(
                                        imageFile: File(xfile.path));

                                    await submitPost(myCroppedFile!, context);
                                    Navigator.pop(context);
                                    //show progress dialog
                                    await ProgressLoader().show(context);
                                  }
                                },
                                icon: const Icon(CupertinoIcons.camera),
                                label: const Text('Select from Camera')),
                            const Divider(),
                            TextButton.icon(
                                onPressed: () async {
                                  final imp.XFile? xfile =
                                      await _imagePicker.pickImage(
                                          source: imp.ImageSource.gallery);

                                  if (xfile != null) {
                                    File? myCroppedFile = await cropImage(
                                        imageFile: File(xfile.path));

                                    await submitPost(myCroppedFile!, context);
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(CupertinoIcons
                                    .photo_fill_on_rectangle_fill),
                                label: const Text('Select from Gallery'))
                          ],
                        ),
                      );
                    });
              },
              icon: const Icon(CupertinoIcons.camera))
        ],
        bottom: PreferredSize(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: Text(
                  "Today",
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1!
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 39),
                ),
              ),
            ),
            preferredSize: const Size.fromHeight(50)),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              return ListView.separated(
                  itemBuilder: (context, index) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.done &&
                        !snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(Icons.info, color: Colors.red),
                          Text("No posts available at the moment")
                        ],
                      );
                    }
                    return PostCardWidget(
                      images: _images,
                      name: snapshot.data!.docs[index].data()['name'],
                      profilePic:
                          snapshot.data!.docs[index].data()['profile_picture'],
                      location: snapshot.data!.docs[index].data()['location'],
                      postImage: snapshot.data!.docs[index].data()['image_url'],
                      likeCount:
                          snapshot.data!.docs[index].data()['likesCount'],
                      commentCount:
                          snapshot.data!.docs[index].data()['commentCount'],
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const Divider();
                  },
                  itemCount:
                      snapshot.data == null ? 0 : snapshot.data!.docs.length);
            }),
      ),
    );
  }
}

class PostCardWidget extends StatelessWidget {
  const PostCardWidget({
    Key? key,
    required List<String> images,
    required this.name,
    required this.profilePic,
    required this.postImage,
    required this.likeCount,
    required this.commentCount,
    required this.location,
  })  : _images = images,
        super(key: key);

  final List<String> _images;
  final String name;
  final String location;
  final String profilePic;
  final String postImage;
  final int likeCount;
  final int commentCount;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(profilePic),
            ),
            title: Text(name,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontWeight: FontWeight.w500, fontSize: 21)),
            subtitle: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 17,
                ),
                Text(
                  location,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .copyWith(color: Colors.grey),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () {
                showBottomSheet(
                    backgroundColor: Colors.blue,
                    context: context,
                    builder: (context) {
                      return PhotoView(
                        backgroundDecoration:
                            const BoxDecoration(color: Colors.blue),
                        imageProvider: NetworkImage(postImage),
                        loadingBuilder: (context, event) {
                          return Center(
                            child: CircularProgressIndicator(
                              value: event == null
                                  ? 0
                                  : event.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!,
                            ),
                          );
                        },
                      );
                    });
              },
              child: Image.network(
                postImage,
                height: 270,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Material(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(90),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '$likeCount',
                          style: Theme.of(context).textTheme.bodyText2,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                FlutterImageStack(
                  imageList: _images,
                  showTotalCount: false,
                  totalCount: 4,
                  itemRadius: 40, // Radius of each images
                  itemCount: 3, // Maximum number of images to be shown in stack
                  itemBorderWidth:
                      3, // Border widt // Border width around the images
                ),
                const Spacer(),
                Material(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(90),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.chat_bubble_fill,
                          color: Colors.grey,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '$commentCount',
                          style: Theme.of(context).textTheme.bodyText2,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
