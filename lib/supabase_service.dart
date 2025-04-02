import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMentorEmailAndNameByRollNo(String rollNo) async {
    try{
    final response = await supabase
        .from('students') // Assuming you have a "students" table
        .select('mentor_email, name, count, sec_no') // Assuming these are the columns in your table
        .eq('roll_no', rollNo)
        .single(); // Use .single() to get a single record

    // If the response is successful, return the data
    if (response != null) {
      final mentorEmail = response['mentor_email'];
      final studentName = response['name'];
      final lateCount = response['count'];
      final sec_no = response['sec_no'];

      return {'mentorEmail': mentorEmail, 'studentName': studentName , 'lateCount': lateCount , 'sec_no': sec_no};
    } else {
      return null;
    }
    }catch(e){
      print('Error: $e');
      return null;
    }
  }
}
