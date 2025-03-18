import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:travel_companion/pages/create_post_page.dart';
import 'package:travel_companion/pages/profile.dart';
import 'package:travel_companion/utils/colors.dart';
import '../main.dart';

class ViewPost extends StatefulWidget {
  final Map<String, dynamic> post;

  const ViewPost({Key? key, required this.post}) : super(key: key);

  @override
  State<ViewPost> createState() => _ViewPostState();
}

class _ViewPostState extends State<ViewPost> {
  late Map<String, dynamic> post;
  String loggedInUser = Profile.userData['username'];

  var message;
  var sentByUsername = Profile.userData['username'];
  var sentByPhoneNumber = Profile.phoneNumber;

  showNormalSnackBar(BuildContext context, String snackBarText) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.all(5),
        behavior: SnackBarBehavior.floating,
        content: Text(snackBarText)));
  }

  showErrorSnackBar(BuildContext context, String snackBarText) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.all(5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: errorRed,
        content: Text(snackBarText)));
  }

  @override
  void initState() {
    super.initState();
    post = widget.post;
  }

  bool isOwnPost() {
    return post.isNotEmpty && post['username'] == loggedInUser;
  }

  void storeRequest() async {
    try {
      String? userEmail = FirebaseAuth.instance.currentUser!.email;
      var firestore = FirebaseFirestore.instance;

      DocumentSnapshot<Map<String, dynamic>> myRequestSnapshot =
          await firestore.collection('Requests').doc(userEmail).get();

      Map<String, dynamic> myRequestInfo = {
        'tripId': post['id'],
        'status': 'Pending',
        'type': 'Sent',
        'sentBy': userEmail,
        'sentTo': post['createdBy'],
        'Message': message,
        'sentByUsername': sentByUsername,
      };
      Map<String, dynamic> ownerRequestInfo = {
        'tripId': post['id'],
        'status': 'Pending',
        'type': 'Received',
        'sentBy': userEmail,
        'sentTo': post['createdBy'],
        'Message': message,
        'sentByUsername': sentByUsername,
        'phoneNumber': sentByPhoneNumber
      };

      if (myRequestSnapshot.exists) {
        List<dynamic> myExistingRequests =
            myRequestSnapshot.data()?['requests'] ?? [];
        for (var i = 0; i < myExistingRequests.length; i++) {
          //checking if the request exists
          if (myExistingRequests[i]['tripId'] == myRequestInfo['tripId']) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request already exists')));
            return;
          }
        }
        await firestore.collection('Requests').doc(userEmail).update({
          'requests': FieldValue.arrayUnion([myRequestInfo]),
        });
        await firestore.collection('Requests').doc(post['createdBy']).update({
          'requests': FieldValue.arrayUnion([ownerRequestInfo]),
        });

        Navigator.of(context).pop();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request sent')));
      }
    } catch (e) {
      showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> deletePost() async {
    try {
      await FirebaseFirestore.instance
          .collection('Trips')
          .doc(widget.post['id'])
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Post Deleted')));
      Navigator.pop(context, true);
    } catch (e) {
      showErrorSnackBar(context, "Error deleting post: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageController = TextEditingController();
    List<dynamic> companion = post['companion'] ?? [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: secondaryTextColor,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "View Post",
          style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: secondaryTextColor),
        ),
      ),
      backgroundColor: primaryColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Post By:",
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post['profilePhotoState'] == 0) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ProfilePicture(
                      name: post['username'],
                      radius: 30,
                      fontsize: 20,
                    ),
                  )
                ] else ...[
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 30.0,
                        backgroundImage: NetworkImage(Base
                            .profilePictures[post['profilePhotoState'] - 1]),
                      ))
                ],
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['username'] ?? 'Not available',
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 120,
                      child: Row(
                        children: [
                          if (post['about'] != null &&
                              post['about'].isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                "About: ${post['about']}",
                                style: const TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      "Email: ${post['createdBy'] ?? 'Not available'}",
                      style: const TextStyle(
                        color: primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              height: 10,
              color: primaryTextColor,
              thickness: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              "Trip Route",
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
              child: Row(
                children: [
                  const Text(
                    "From:",
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Text(
                    "${post['source'] ?? 'Not available'}",
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Row(
                children: [
                  const Text(
                    "To:",
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 40),
                  Text(
                    "${post['destination'] ?? 'Not available'}",
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(
              height: 10,
              color: primaryTextColor,
              thickness: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              "On",
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date: ${post['date'] ?? 'Not available'}",
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Time: ${post['time'] ?? 'Not available'}",
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(
              height: 10,
              color: primaryTextColor,
              thickness: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              "By",
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mode Of Transportation:",
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${post['modeOfTransport'] ?? 'Not available'}",
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(
              height: 10,
              color: primaryTextColor,
              thickness: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              "Description",
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Text(
                post['desc'] != null
                    ? "${post['desc']}"
                    : "Description: Not Specified",
                style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(
              height: 10,
              color: primaryTextColor,
              thickness: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              "Companions",
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < companion.length; i++) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                child: Text(
                  companion[i].toString(),
                  style: const TextStyle(
                    color: primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Divider(
              height: 10,
              color: primaryTextColor,
              thickness: 2,
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isOwnPost()) ...[
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Your Message:-'),
                          content: TextField(
                            controller: messageController,
                            decoration: const InputDecoration(
                                hintText: 'Enter your message'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                message = messageController.text;
                                storeRequest();
                              },
                              child: const Text('Submit'),
                            )
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: complementaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      "REQUEST",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePostPage(
                            initialPost: post,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: complementaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      "EDIT",
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete this post?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                deletePost();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Yes'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('No'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: complementaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      "DELETE",
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
