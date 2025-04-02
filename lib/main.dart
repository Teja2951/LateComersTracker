import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:latecomers/custom_tile.dart';
import 'package:latecomers/email_service.dart';
import 'package:latecomers/supabase_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:latecomers/wa_service.dart';

void main() async{
  await Supabase.initialize(
    url: 'https://visxmjagkngohmjpdxjw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpc3htamFna25nb2htanBkeGp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ4NjI5NzksImV4cCI6MjA1MDQzODk3OX0.IrcE3EznIK8enw8J9aulwvZjd726TqroIVzEW92POG8'
  );
  runApp(myApp());
}

class myApp extends StatefulWidget {
  const myApp({super.key});

  @override
  State<myApp> createState() => _myAppState();
}

class _myAppState extends State<myApp> {
  TextEditingController _controller = TextEditingController();
  int _selectedScreenIndex = 0;
  List<String> _scannedBarcodes = [];

  final supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> _fetchMentors() {
    return supabase
        .from('mentor') // Listen to the 'mentor' table
        .stream(primaryKey: ['id']) // Ensure that the stream uses a primary key for efficient updates
        .order('id') // Order data by 'id' or any other field
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  String? extractRawValue(String data) {
    final regex = RegExp(r'(?:displayValue|rawValue):\s*([^\s,]+)');
    final match = regex.firstMatch(data);

    return match?.group(1);
  }

  Future<void> appendToColumn(String mentorEmail, String newValue) async {
  try {
    print('appending');
    final response = await Supabase.instance.client
        .from('mentor')
        .select('data')
        .eq('mentor_email', mentorEmail)
        .single();

    if (response != null && response['data'] is String) {
      final existingValue = response['data'];

      // Step 2: Concatenate the new value
      final updatedValue = (existingValue as String) + ' ($newValue)';

      // Step 3: Update the column
      await Supabase.instance.client
          .from('mentor')
          .update({'data': updatedValue})
          .eq('mentor_email', mentorEmail);

      print('Column updated successfully!');
    } else {
      print('No existing notes found or invalid response.');
    }
  } catch (error) {
    print('Error appending to column: $error');
  }
}

Future<void> updateCount(String rollNo) async{
  try{
    final response = await Supabase.instance.client
    .from('students')
    .select('count')
    .eq('roll_no', rollNo)
    .single();
    
    if (response != null && response['count'] is int) {
      final count = response['count'];

      // Step 2: Concatenate the new value
      final updateCount = (count as int) + 1;

      // Step 3: Update the column
      await Supabase.instance.client
          .from('students')
          .update({'count': updateCount})
          .eq('roll_no', rollNo);

      print('added current is $updateCount');
    } else {
      print('No existing notes found or invalid response.');
    }
  } catch (error) {
    print('Error counting to   --- fd: $error');
  }


}


  Widget _getCurrentScreen() {
    switch(_selectedScreenIndex) {
      case 0:
        return _buildScanner();
      case 1:
        return _buildListView();
      default:
        return _buildScanner();
    }
  }

  Widget _buildScanner() {
    return Column(
          children: [
             Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MobileScanner(
                      onDetect: (barcode) async{
                        Vibration.vibrate(duration: 100);
                        final rawValue = extractRawValue(barcode.raw.toString());
                        if (rawValue != null && !_scannedBarcodes.contains(rawValue)) { 
                          Map<String,dynamic>? _data = await SupabaseService().getMentorEmailAndNameByRollNo(rawValue);
                          String _currentEmail = _data!['mentorEmail']!;
                          int lateCount = _data!['lateCount']!;
                          String sec_no = _data!['sec_no']!;
                          String msg = "${_data['studentName']} ($rawValue) of section $sec_no arrived at ${DateTime.now().toString()} He is late to college $lateCount Times till date";
                          appendToColumn(_currentEmail, msg);
                          updateCount(rawValue);
                          setState(() {
                            _scannedBarcodes.add(rawValue);
                          });
                        }
                      },
                    ),
                  ),
                ),

                // Positioned(
                //   left: 90,
                //   top: 50,
                //   child: Container(
                //     height: 100,
                //     width: 250,
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.red)
                //     ),
                //   )
                // )
              ],
            ),

            

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Divider(color: Colors.black,),
                  // Container for input field and button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.purple.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Roll No TextField
                        TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Roll No',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        // Add Button
                        ElevatedButton(
              onPressed: () async{
                if(!_controller.text.isEmpty){
                  print('gfds');
                          if (!_scannedBarcodes.contains(_controller.text)) { 
                            updateCount(_controller.text);
                            
                          Map<String,dynamic>? _data = await SupabaseService().getMentorEmailAndNameByRollNo(_controller.text);
                          String _currentEmail = _data!['mentorEmail']!;
                          int lateCount = _data!['lateCount']!;
                          String sec_no = _data!['sec_no']!;
                          print(_currentEmail);
                          String msg = "${_data['studentName']} (${_controller.text}) of section $sec_no arrived at ${DateTime.now().toString()} He/She is late to college $lateCount times till date";
                          print(msg);
                          appendToColumn(_currentEmail, msg);
                          
                      }else{
                        print('already there');
                      }
                          
                setState(() {
                  _scannedBarcodes.add( _controller.text,);
                });
                _controller.clear();
                }
                else{
                  print('Vibarte');
                  Vibration.vibrate(duration: 100);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 20),
                padding: EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 30.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
                        ),
                      ],
                    ),
                  ),

                  //Divider(color: Colors.black,),

              // ElevatedButton(
              // onPressed: () {},
              // style: ElevatedButton.styleFrom(
              //   backgroundColor: Colors.grey,
              //   minimumSize: Size(double.infinity, 20),
              //   padding: EdgeInsets.symmetric(
              //       vertical: 12.0, horizontal: 30.0),
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              // ),
              // child: Text(
              //   'Search LateComers',
              //   style: TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.black,
              //   ),
              // ),
              //           ),

              //           ElevatedButton(
              // onPressed: () {},
              // style: ElevatedButton.styleFrom(
              //   backgroundColor: Colors.grey,
              //   minimumSize: Size(double.infinity, 20),
              //   padding: EdgeInsets.symmetric(
              //       vertical: 12.0, horizontal: 30.0),
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              // ),
              // child: Text(
              //   'Analysis',
              //   style: TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.black,
              //   ),
              // ),
              //           ),

              // ElevatedButton(
              // onPressed: () {},
              // style: ElevatedButton.styleFrom(
              //   backgroundColor: Colors.grey,
              //   minimumSize: Size(double.infinity, 20),
              //   padding: EdgeInsets.symmetric(
              //       vertical: 12.0, horizontal: 30.0),
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              // ),
              // child: Text(
              //   'Broadcast an Email',
              //   style: TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.black,
              //   ),
              // ),
              //           ),


        ],
              ),
            ),

            Spacer(),

            Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Made by Teja Varshith.V(23341A05O8) - CSE-D',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),



          ],
        );
  }

  void _deleteItem(int index) {
    setState(() {
      _scannedBarcodes.removeAt(index);
    });
  }

  Future<void> clearColumnValue(String mentorEmail) async {
  final response = await supabase
      .from('mentor') // Replace with your table name
      .update({'data': ''}) // Replace with your column name
      .eq('mentor_email', mentorEmail); // Match the row based on its unique identifier

  if (response.error != null) {
    print('Error clearing column: ${response.error!.message}');
  } else {
    print('Column cleared successfully!');
  }
}


  Widget _buildListView() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: _fetchMentors(), // Stream from Supabase
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No mentors available.'));
      }

      List<Map<String, dynamic>> mentors = snapshot.data!;

      return ListView.builder(
        itemCount: mentors.length,
        itemBuilder: (context, index) {
          return CustomTile(
            title: mentors[index]['mentor_email'] ?? 'No email',
            subtitle: mentors[index]['data'] ?? 'No data',
            onSendEmail: () async{
              await WaService().sendStudentInfo('916302199456', 'teja var cse');

              // if(mentors[index]['data'] != null && mentors[index]['data'] != ''){
              // SendEmailService().sendEmail('${mentors[index]['mentor_email']}', '${mentors[index]['data']}');
              // ScaffoldMessenger.of(context).showSnackBar(
              //               SnackBar(
              //                 content: Text('Email sent successfully to ${mentors[index]['mentor_email']}!'),
              //                 backgroundColor: Colors.green,
              //               ),
              //               );
              // clearColumnValue(mentors[index]['mentor_email']);
              // }
              // else{
              //   ScaffoldMessenger.of(context).showSnackBar(
              //               SnackBar(
              //                 content: Text('No Latecomers to send email!'),
              //                 backgroundColor: Colors.red,
              //               ),
              //               );
              // }
            }
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.cyan[500],
        appBar: AppBar(
          title:Text('LateComers Auto'),
          centerTitle: true,
          backgroundColor: Colors.cyan,
          elevation: 20,
          actions: [
            IconButton(
              onPressed: () {
                _scannedBarcodes = [];
              },
             icon: Icon(Icons.replay_circle_filled_rounded)
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
  elevation: 20,
  backgroundColor: Colors.white, // Lighter background for better contrast
  selectedItemColor: Colors.cyan[700], // Highlight selected icon with a vibrant color
  unselectedItemColor: Colors.grey, // Subtle color for unselected icons
  selectedFontSize: 16, // Uniform font size
  unselectedFontSize: 14,
  type: BottomNavigationBarType.fixed, // Smooth transitions for selected icons
  currentIndex: _selectedScreenIndex,
  onTap: (index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.camera_alt_rounded),
      activeIcon: Icon(Icons.camera_alt_rounded, size: 30), // Larger icon when active
      label: 'Scanner',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.email),
      activeIcon: Icon(Icons.format_list_bulleted_rounded, size: 30), // Larger icon when active
      label: 'Email',
    ),
  ],
),

        body: _getCurrentScreen(),
      ),
    );
  }
}

