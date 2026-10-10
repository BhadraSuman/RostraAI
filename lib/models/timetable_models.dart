import 'dart:convert';

enum ClassStatusType {
  normal,
  cancelled,
  roomMoved,
  timeMoved,
  extraClass;

  String get displayName {
    switch (this) {
      case ClassStatusType.normal:
        return 'Normal';
      case ClassStatusType.cancelled:
        return 'Cancelled';
      case ClassStatusType.roomMoved:
        return 'Room Changed';
      case ClassStatusType.timeMoved:
        return 'Time Moved';
      case ClassStatusType.extraClass:
        return 'Extra Class';
    }
  }

  static ClassStatusType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'cancelled':
        return ClassStatusType.cancelled;
      case 'roommoved':
      case 'room_moved':
      case 'room_changed':
        return ClassStatusType.roomMoved;
      case 'timemoved':
      case 'time_moved':
        return ClassStatusType.timeMoved;
      case 'extraclass':
      case 'extra_class':
        return ClassStatusType.extraClass;
      default:
        return ClassStatusType.normal;
    }
  }
}

class ClassPage {
  final String id;
  final String college;
  final String department;
  final String year;
  final String section;
  final String createdBy;
  final String createdByName;
  final List<String> editors;
  final String verificationStatus; // 'unverified' | 'verified'
  final String timezone;
  final List<String> availableGroups;
  final String classCode;

  const ClassPage({
    required this.id,
    required this.college,
    required this.department,
    required this.year,
    required this.section,
    required this.createdBy,
    required this.createdByName,
    required this.editors,
    this.verificationStatus = 'unverified',
    this.timezone = 'Asia/Kolkata',
    this.availableGroups = const ['All', 'B1', 'B2'],
    this.classCode = '',
  });

  String get title => '$department $year • $section';
  String get subtitle => college;
  String get displayCode => classCode.isNotEmpty ? classCode : id.toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'college': college,
      'department': department,
      'year': year,
      'section': section,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'editors': editors,
      'verificationStatus': verificationStatus,
      'timezone': timezone,
      'availableGroups': availableGroups,
      'classCode': classCode,
    };
  }

  factory ClassPage.fromMap(Map<String, dynamic> map) {
    return ClassPage(
      id: map['id'] as String? ?? '',
      college: map['college'] as String? ?? '',
      department: map['department'] as String? ?? '',
      year: map['year'] as String? ?? '',
      section: map['section'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      editors: (map['editors'] as List<dynamic>?)?.cast<String>() ?? [],
      verificationStatus: map['verificationStatus'] as String? ?? 'unverified',
      timezone: map['timezone'] as String? ?? 'Asia/Kolkata',
      availableGroups: (map['availableGroups'] as List<dynamic>?)?.cast<String>() ?? const ['All', 'B1', 'B2'],
      classCode: map['classCode'] as String? ?? map['code'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());
  factory ClassPage.fromJson(String source) => ClassPage.fromMap(json.decode(source) as Map<String, dynamic>);
}

class TimetableEntry {
  final String id;
  final String day; // SUNDAY, MONDAY, TUESDAY, etc.
  final String startTime; // "09:00"
  final String endTime; // "10:00"
  final String subject;
  final String room;
  final String teacher;
  final String group; // "All", "B1", "B2", etc.
  final String? courseCode;
  final bool isBreak; // Recess, Lunch, or Break slot

  const TimetableEntry({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.room,
    required this.teacher,
    this.group = 'All',
    this.courseCode,
    this.isBreak = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'room': room,
      'teacher': teacher,
      'group': group,
      'isBreak': isBreak,
      if (courseCode != null) 'courseCode': courseCode,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'] as String? ?? '',
      day: map['day'] as String? ?? 'MONDAY',
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '10:00',
      subject: map['subject'] as String? ?? '',
      room: map['room'] as String? ?? '',
      teacher: map['teacher'] as String? ?? '',
      group: map['group'] as String? ?? 'All',
      courseCode: map['courseCode'] as String?,
      isBreak: map['isBreak'] as bool? ?? false,
    );
  }

  TimetableEntry copyWith({
    String? id,
    String? day,
    String? startTime,
    String? endTime,
    String? subject,
    String? room,
    String? teacher,
    String? group,
    String? courseCode,
    bool? isBreak,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      group: group ?? this.group,
      courseCode: courseCode ?? this.courseCode,
      isBreak: isBreak ?? this.isBreak,
    );
  }
}

class ClassStatus {
  final String entryId;
  final ClassStatusType status;
  final String? updatedRoom;
  final String? updatedStartTime;
  final String? updatedEndTime;
  final String? note;
  final String updatedAt;
  final String updatedByName;

  const ClassStatus({
    required this.entryId,
    required this.status,
    this.updatedRoom,
    this.updatedStartTime,
    this.updatedEndTime,
    this.note,
    required this.updatedAt,
    required this.updatedByName,
  });

  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'status': status.name,
      if (updatedRoom != null) 'updatedRoom': updatedRoom,
      if (updatedStartTime != null) 'updatedStartTime': updatedStartTime,
      if (updatedEndTime != null) 'updatedEndTime': updatedEndTime,
      if (note != null) 'note': note,
      'updatedAt': updatedAt,
      'updatedByName': updatedByName,
    };
  }

  factory ClassStatus.fromMap(Map<String, dynamic> map) {
    return ClassStatus(
      entryId: map['entryId'] as String? ?? '',
      status: ClassStatusType.fromString(map['status'] as String? ?? 'normal'),
      updatedRoom: map['updatedRoom'] as String?,
      updatedStartTime: map['updatedStartTime'] as String?,
      updatedEndTime: map['updatedEndTime'] as String?,
      note: map['note'] as String?,
      updatedAt: map['updatedAt'] as String? ?? '',
      updatedByName: map['updatedByName'] as String? ?? '',
    );
  }
}

class DayOverride {
  final String date; // YYYY-MM-DD
  final bool isNoClasses;
  final String? followsWeekday; // e.g. "FRIDAY"
  final String? note;

  const DayOverride({
    required this.date,
    this.isNoClasses = false,
    this.followsWeekday,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'isNoClasses': isNoClasses,
      if (followsWeekday != null) 'followsWeekday': followsWeekday,
      if (note != null) 'note': note,
    };
  }

  factory DayOverride.fromMap(Map<String, dynamic> map) {
    return DayOverride(
      date: map['date'] as String? ?? '',
      isNoClasses: map['isNoClasses'] as bool? ?? false,
      followsWeekday: map['followsWeekday'] as String?,
      note: map['note'] as String?,
    );
  }
}

class ClassComment {
  final String id;
  final String classDate; // YYYY-MM-DD
  final String entryId;
  final String authorId;
  final String authorName;
  final bool isEditor;
  final String text;
  final String createdAt;
  final String expiresAt; // Midnight IST UTC ISO
  final bool isReported;

  const ClassComment({
    required this.id,
    required this.classDate,
    required this.entryId,
    required this.authorId,
    required this.authorName,
    this.isEditor = false,
    required this.text,
    required this.createdAt,
    required this.expiresAt,
    this.isReported = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classDate': classDate,
      'entryId': entryId,
      'authorId': authorId,
      'authorName': authorName,
      'isEditor': isEditor,
      'text': text,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'isReported': isReported,
    };
  }

  factory ClassComment.fromMap(Map<String, dynamic> map) {
    return ClassComment(
      id: map['id'] as String? ?? '',
      classDate: map['classDate'] as String? ?? '',
      entryId: map['entryId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      isEditor: map['isEditor'] as bool? ?? false,
      text: map['text'] as String? ?? '',
      createdAt: map['createdAt'] as String? ?? '',
      expiresAt: map['expiresAt'] as String? ?? '',
      isReported: map['isReported'] as bool? ?? false,
    );
  }
}
