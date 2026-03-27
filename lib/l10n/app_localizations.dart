// lib/l10n/app_localizations.dart

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
    Locale('ms'),
    Locale('ta'),
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    // ── English ───────────────────────────────────────────────────────────
    'en': {
      'appName': 'ElderCare SG',
      'tagline': 'Your family, always connected',
      'cancel': 'Cancel',
      'save': 'Save',
      'confirm': 'Confirm',
      'logOut': 'Log Out',
      'logOutConfirm': 'Are you sure you want to log out?',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'changeLanguage': 'Change Language',
      'selectLanguage': 'Select Language',
      'login': 'Log In',
      'signup': 'Create Account',
      'forgotPassword': 'Forgot Password?',
      'email': 'Email Address',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'phoneNumber': 'Phone Number (optional)',
      'iAm': 'I am a...',
      'elderly': 'Elderly',
      'caregiver': 'Caregiver',
      'elderlyDesc': 'I want to be\nlooked after',
      'caregiverDesc': 'I care for\nan elderly person',
      'noAccount': 'Don\'t have an account?',
      'alreadyAccount': 'Already have an account?',
      'findMyAccount': 'Find My Account',
      'resetPassword': 'Reset Password',
      'setNewPassword': 'Set New Password',
      'newPassword': 'New Password',
      'saveNewPassword': 'Save New Password',
      'passwordResetSuccess': 'Password reset! Please log in.',
      'accountCreated': 'Account created! Please log in.',
      'goodDay': 'Good day,',
      'dailyCheckIn': 'Daily Check-In',
      'checkedInToday': 'Checked In Today',
      'tapToCheckIn': 'Tap to Check In',
      'lastCheckIn': 'Last check-in',
      'manual': 'Manual',
      'phoneUnlock': 'Phone unlock',
      'checkInSuccess': 'Checked in! Your caregivers have been notified.',
      'myFamilyGroup': 'My Family Group',
      'createOrJoin': 'Tap to create or join a group',
      'myCaregivers': 'My Caregivers',
      'noCaregivers': 'No caregivers yet.\nInvite a caregiver from My Family Group.',
      'pendingInvites': 'pending invite(s)',
      'sosActive': 'SOS Active',
      'caringFor': 'Caring for',
      'groups': 'group(s)',
      'elderlyStatus': 'Elderly Status',
      'phoneActive': 'Phone Active',
      'phoneInactive': 'Phone Inactive',
      'checkedIn': 'Checked In',
      'notCheckedIn': 'Not Checked In',
      'lastSeen': 'Last seen',
      'sosHistory': 'SOS History',
      'manageGroups': 'Manage Groups',
      'manageGroupsDesc': 'Join, request or manage elderly groups',
      'noGroups': 'No elderly groups yet',
      'noGroupsDesc': 'Join or request to be added to an elderly person\'s group.',
      'resolve': 'Resolve',
      'activeSOSAlerts': 'Active SOS Alert(s)!',
      'sendSOS': 'Send SOS Alert',
      'sosDesc': 'All your caregivers will be notified immediately.\n\nDescribe your situation:',
      'sosHint': 'e.g. I fell down and need help...',
      'sendSOSButton': 'Send SOS',
      'sosSent': 'SOS sent! Your caregivers have been notified.',
      'myFamilyGroupPage': 'My Family Group',
      'createYourGroup': 'Create Your Group',
      'createGroupDesc': 'Start by creating a family group. Your caregivers can then join.',
      'groupName': 'Group Name (e.g. Tan Family)',
      'createGroup': 'Create Group',
      'groupCreated': 'Group created!',
      'inviteCaregiver': 'Invite a caregiver by searching their email address:',
      'searchCaregiverEmail': 'Search caregiver by email',
      'invite': 'Invite',
      'inviteSent': 'Invite sent to',
      'allMembers': 'All Members',
      'pendingRequests': 'Pending Requests',
      'caregiverWantsToJoin': 'Caregiver wants to join your group',
      'youInvited': 'You invited this caregiver',
      'you': 'You',
      'groupInvitations': 'Group Invitations',
      'myGroups': 'My Groups',
      'requestToJoin': 'Request to Join a Group',
      'requestDesc': 'Search for an elderly person by email to request joining their family group:',
      'searchElderlyEmail': 'Search elderly by email',
      'request': 'Request',
      'requestSent': 'Request sent to',
      'accept': 'Accept',
      'decline': 'Decline',
      'joinedGroup': 'Joined group!',
      'inviteAccepted': 'Invite accepted!',
      'inviteDeclined': 'Invite declined.',
      'noGroupYet': 'No group yet',
      'invitedToJoin': 'Invited you to join their group',
      'requestPending': 'Your request is pending',
      'noGroupsJoined': 'You have not joined any groups yet.',
      'members': 'Members',
      'myProfile': 'My Profile',
      'editProfile': 'Edit Profile',
      'changePassword': 'Change Password',
      'profileUpdated': 'Profile updated!',
      'saveChanges': 'Save Changes',
      'noMessages': 'No messages yet.\nSay hello to',
      'typeMessage': 'Type a message...',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'manualCheckIn': 'Manual check-in',
      'phoneUnlockCheckIn': 'Phone unlock',
      'noActivity': 'No activity recorded yet.',
      'editName': 'Edit Name',
      'newName': 'New name',
      'rememberMe': 'Remember me',
      'noSosHistory': 'No SOS history',
      'setAdmin': 'Set Admin',
      'noAdmin': 'No Admin',
      'adminSet': 'Admin updated successfully',
      'adminRemoved': 'Admin removed',
      'activity': 'Activity',
      'todayCheckIns': 'Today\'s Check-ins',
      'sosAlerts': 'SOS alerts',
      'triggered': 'Triggered',
      'resolvedAt': 'Resolved at',
      'duration': 'Duration',
      'total': 'Total',
      'active': 'Active',
      'resolved': 'Resolved',
      'sendMessage': 'Send Message',
      // New keys
      'newMessages': 'New Messages',
      'deleteMessage': 'Delete this message',
      'deleteAllMessages': 'Delete All Messages',
      'deleteAllConfirm': 'This will permanently delete all messages in this conversation. Are you sure?',
      'deleteAll': 'Delete All',
      'deleteForEveryone': 'Delete for everyone',
      'deleteForMe': 'Delete for me',
      'deletedMessage': 'This message was deleted',
      'disbandGroup': 'Disband Group',
      'disbandGroupConfirm': 'This will permanently disband your family group and remove all caregivers. Are you sure?',
      'disband': 'Disband',
      'disbandLeaveGroup': 'Disband & Leave Group',
      'leaveGroup': 'Leave Group',
      'leaveGroupConfirm': 'Are you sure you want to leave this group?',
      'leave': 'Leave',
      'youHaveLeftGroup': 'You have left the group.',
      'groupDisbanded': 'Group disbanded.',
      'kickMember': 'Remove Member',
      'kickMemberConfirm': 'Are you sure you want to remove this member from the group?',
      'kick': 'Remove',
      'memberRemoved': 'Member removed from group.',
      'renameGroup': 'Rename Group',
      'newGroupName': 'New group name',
      'groupRenamed': 'Group name updated!',
      'rename': 'Rename',
      'messages': 'Messages',
      'quickActions': 'Quick Actions',
      'dailyCheckInDesc': 'Manual daily check-in to let caregivers know you are OK.',
      'backgroundTracking': 'Background Activity Tracking',
      'sleepModeActive': 'Sleep Mode Active',
      'activityCheckTitle': 'Activity Check',
      'activityCheckMessage': 'No phone activity detected in the last 5 hours. Are you OK? Tap I\'m OK to let your caregivers know.',
      'imOk': "I'm OK",
      'phoneUnlockCheck': 'Phone Unlock',
      'stepsCheck': 'Steps (50+ steps)',
      'phonePickupCheck': 'Phone Pickup',
      'steps': 'steps',
      'checkInStatus': 'Check-in Status (Today)',
      'sleepWindow': 'Sleep Window',
      'sleepWindowDesc': 'Set a sleep window so activity tracking is paused during sleep hours.',
      'sleepWindowActive': 'Sleep window is active',
      'setSleepWindow': 'Set Sleep Window',
      'editSleepWindow': 'Edit Sleep Window',
      'clearSleepWindow': 'Clear Sleep Window',
      'sleepWindowSaved': 'Sleep window saved!',
      'sleepWindowCleared': 'Sleep window cleared.',
      'sleepStart': 'Sleep Start',
      'sleepEnd': 'Wake Time',
      'current': 'Current',
      'adminLabel': 'Admin',
      'activeSOSCount': '{count} Active SOS Alert(s)!',
      'dailyWellbeing': 'Daily Wellbeing',
      'wellbeingGreeting': 'How are you feeling today?',
      'wellbeingSubtitle': 'Your answers help your family care for you better.',
      'wellbeingMood': 'How is your mood?',
      'wellbeingPain': 'Any pain or discomfort?',
      'wellbeingSleep': 'How did you sleep?',
      'wellbeingAppetite': 'How is your appetite?',
      'wellbeingLonely': 'Are you feeling connected?',
      'wellbeingSaved': 'Thank you! Your answers have been saved.',
      'wellbeingSubmit': 'Submit',
      'wellbeingUpdate': 'Update Answers',
      'wellbeingAlreadyDone': 'You have already filled in today\'s wellbeing check.',
      'wellbeingHistory': 'Past 7 Days',
      'todayWellbeing': 'Today\'s Wellbeing',
      'noWellbeingData': 'No wellbeing records yet.',
      'wellbeingButton': 'Daily Wellbeing',
      'noMessagesChinese': 'No messages yet.\nSay hello!',
      'selectCaregiver': 'Select a Caregiver',
      'inviteCode': 'Invite Code',
      'inviteCodeHint': 'Enter 6-character code',
      'joinWithCode': 'Join with Invite Code',
      'joinWithCodeDesc': 'Enter the 6-character code shared by the elderly user.',
      'yourInviteCode': 'Your Group Invite Code',
      'shareCode': 'Share this code with caregivers to let them join directly.',
      'regenerateCode': 'Regenerate Code',
      'codeRegenerated': 'New invite code generated!',
      'joinedWithCode': 'Successfully joined the group!',
      'copyCode': 'Copy Code',
      'codeCopied': 'Code copied to clipboard!',
      'orSearchByEmail': 'Or search by email',
      'orJoinWithCode': 'Or join with invite code',
      'searching': 'Searching...',
      'dailyTrackingData': 'Daily Tracking Data',
      'trackingDataDesc': 'Summary of your check-ins and wellbeing for today.',
      'clearTrackingData': 'Clear All Tracking Data',
      'clearTrackingDataConfirm': 'This will delete all your check-ins, wellbeing entries and SOS records. This is for testing only. Are you sure?',
      'clearTrackingDataDone': 'All tracking data cleared.',
      'checkInsToday': 'Check-ins Today',
      'wellbeingScore': 'Wellbeing Score',
      'notDoneToday': 'Not done today',
      'manualCheckInCount': 'Manual Check-ins',
      'phoneUnlockCount': 'Phone Unlocks',
      'stepsCount': 'Steps Sessions',
      'pickupCount': 'Phone Pickups',
      'sosCount': 'SOS Alerts',
      'devTesting': 'Developer & Testing',
      'autoCheckInInterval': 'Auto Check-In Interval',
      'autoCheckInIntervalDesc': 'Set how often the app should automatically check for activity. (2-12 hours)',
      'hours': 'hours',
      'disabled': 'Disabled',
      'autoCheckInEnabled': 'Auto Check-In Enabled',
      'autoCheckInSaved': 'Auto check-in interval saved!',
      // ── Check-in config page ──
      'configureCheckIn': 'Configure Check-In Settings',
      'currentConfiguration': 'Current Configuration',
      'autoTracking': 'Auto tracking',
      'alertWindow': 'Alert window',
      'trackingLabel': 'Tracking',
      'notSet': 'Not set',
      'alertInterval': 'Alert interval',
      'liveLabel': 'Live',
      'enabled': 'Enabled',
      'configureTitle': 'Configure – {name}',
      'manualCheckInSection': 'Manual Check-In',
      'manualCheckInAlwaysOn': 'Always active — 24-hour window.',
      'alwaysOn': 'Always ON',
      'automaticSignals': 'Automatic Signals',
      'enableAutoTracking': 'Enable Automatic Tracking',
      'autoTrackingSubtitle': 'When disabled, only manual check-ins are counted.',
      'phoneUnlockLabel': 'Phone Unlock',
      'phoneUnlockSubtitle': 'Counts each time the screen is unlocked.',
      'stepsWalking': 'Steps (Walking)',
      'stepsWalkingSubtitle': 'Counts every 50+ steps detected.',
      'phonePickupLabel': 'Phone Pickup',
      'phonePickupSubtitle': 'Counts when phone is picked up via motion sensors.',
      'alertWindowSection': 'Alert Window',
      'alertAfterHours': 'Alert after {hours} hour{s} of inactivity',
      'alertWindowDesc': 'If no automatic signal is detected within this window, caregivers are alerted.',
      'defaultTenH': 'Default: 10h',
      'sleepWindowSection': 'Sleep Window',
      'sleepWindowPauseDesc': 'Activity tracking is paused during this window. No alerts will fire while the elderly user is sleeping.',
      'clearLabel': 'Clear',
      'sleepTimeLabel': 'Sleep time',
      'wakeTimeLabel': 'Wake time',
      'noSleepWindowSet': 'No sleep window set — tracking runs 24/7.',
      'saveAndSync': 'Save & Sync to Device',
      'syncBannerText': 'Changes are saved to Firebase and automatically synced to the elderly device on their next app open.',
      'sleepValidationError': 'Please set both sleep start and wake time, or clear both.',
      'settingsSaved': 'Settings saved and synced to elderly device ✓',
      'saveFailed': 'Save failed: {error}',
    },

    // ── Chinese ───────────────────────────────────────────────────────────
    'zh': {
      'appName': '乐龄护理 SG',
      'tagline': '家人，永远相连',
      'cancel': '取消',
      'save': '保存',
      'confirm': '确认',
      'logOut': '登出',
      'logOutConfirm': '您确定要登出吗？',
      'loading': '加载中...',
      'error': '错误',
      'success': '成功',
      'changeLanguage': '更改语言',
      'selectLanguage': '选择语言',
      'login': '登录',
      'signup': '创建账户',
      'forgotPassword': '忘记密码？',
      'email': '电子邮件',
      'password': '密码',
      'confirmPassword': '确认密码',
      'fullName': '全名',
      'phoneNumber': '电话号码（可选）',
      'iAm': '我是...',
      'elderly': '乐龄人士',
      'caregiver': '护理员',
      'elderlyDesc': '我需要被\n照顾',
      'caregiverDesc': '我照顾\n一位老人',
      'noAccount': '还没有账户？',
      'alreadyAccount': '已有账户？',
      'findMyAccount': '查找我的账户',
      'resetPassword': '重置密码',
      'setNewPassword': '设置新密码',
      'newPassword': '新密码',
      'saveNewPassword': '保存新密码',
      'passwordResetSuccess': '密码已重置！请登录。',
      'accountCreated': '账户已创建！请登录。',
      'goodDay': '你好，',
      'dailyCheckIn': '每日报到',
      'checkedInToday': '今日已报到',
      'tapToCheckIn': '点击报到',
      'lastCheckIn': '上次报到',
      'manual': '手动',
      'phoneUnlock': '解锁手机',
      'checkInSuccess': '已报到！护理员已收到通知。',
      'myFamilyGroup': '我的家庭群组',
      'createOrJoin': '点击创建或加入群组',
      'myCaregivers': '我的护理员',
      'noCaregivers': '暂无护理员。\n请从家庭群组邀请护理员。',
      'pendingInvites': '个待处理邀请',
      'sosActive': 'SOS 求救中',
      'caringFor': '照顾',
      'groups': '个群组',
      'elderlyStatus': '乐龄人士状态',
      'phoneActive': '手机活跃',
      'phoneInactive': '手机不活跃',
      'checkedIn': '已报到',
      'notCheckedIn': '未报到',
      'lastSeen': '最近活动',
      'sosHistory': 'SOS 记录',
      'manageGroups': '管理群组',
      'manageGroupsDesc': '加入、申请或管理群组',
      'noGroups': '暂无群组',
      'noGroupsDesc': '申请加入乐龄人士的群组。',
      'resolve': '已解决',
      'activeSOSAlerts': '紧急求救！',
      'sendSOS': '发送紧急求救',
      'sosDesc': '所有护理员将立即收到通知。\n\n请描述您的情况：',
      'sosHint': '例：我摔倒了，需要帮助...',
      'sendSOSButton': '发送求救',
      'sosSent': '已发送求救！护理员已收到通知。',
      'myFamilyGroupPage': '我的家庭群组',
      'createYourGroup': '创建您的群组',
      'createGroupDesc': '创建家庭群组，护理员可以加入。',
      'groupName': '群组名称（如：陈家）',
      'createGroup': '创建群组',
      'groupCreated': '群组已创建！',
      'inviteCaregiver': '通过电子邮件搜索护理员：',
      'searchCaregiverEmail': '搜索护理员邮件',
      'invite': '邀请',
      'inviteSent': '邀请已发送给',
      'allMembers': '所有成员',
      'pendingRequests': '待处理请求',
      'caregiverWantsToJoin': '护理员申请加入群组',
      'youInvited': '您已邀请此护理员',
      'you': '您',
      'groupInvitations': '群组邀请',
      'myGroups': '我的群组',
      'requestToJoin': '申请加入群组',
      'requestDesc': '通过邮件搜索乐龄人士以申请加入其家庭群组：',
      'searchElderlyEmail': '搜索乐龄人士邮件',
      'request': '申请',
      'requestSent': '申请已发送给',
      'accept': '接受',
      'decline': '拒绝',
      'joinedGroup': '已加入群组！',
      'inviteAccepted': '邀请已接受！',
      'inviteDeclined': '邀请已拒绝。',
      'noGroupYet': '暂无群组',
      'invitedToJoin': '邀请您加入群组',
      'requestPending': '您的申请待审核',
      'noGroupsJoined': '您尚未加入任何群组。',
      'members': '成员',
      'myProfile': '我的资料',
      'editProfile': '编辑资料',
      'changePassword': '更改密码',
      'profileUpdated': '资料已更新！',
      'saveChanges': '保存更改',
      'noMessages': '暂无消息。\n打个招呼吧！',
      'typeMessage': '输入消息...',
      'today': '今天',
      'yesterday': '昨天',
      'manualCheckIn': '手动报到',
      'phoneUnlockCheckIn': '解锁手机',
      'noActivity': '暂无活动记录。',
      'editName': '编辑名称',
      'newName': '新名称',
      'rememberMe': '记住我',
      'noSosHistory': '没有SOS历史记录',
      'setAdmin': '设置管理员',
      'noAdmin': '无管理员',
      'adminSet': '管理员更新成功',
      'adminRemoved': '已删除管理员',
      'activity': '活动',
      'todayCheckIns': '今日签到',
      'sosAlerts': '紧急警报',
      'triggered': '触发',
      'resolvedAt': '解决于',
      'duration': '持续时间',
      'total': '总计',
      'active': '活跃',
      'resolved': '已解决',
      'sendMessage': '发送消息',
      'newMessages': '新消息',
      'deleteMessage': '删除此消息',
      'deleteAllMessages': '删除所有消息',
      'deleteAllConfirm': '这将永久删除此对话中的所有消息。您确定吗？',
      'deleteAll': '全部删除',
      'deleteForEveryone': '为所有人删除',
      'deleteForMe': '仅为我删除',
      'deletedMessage': '此消息已被删除',
      'disbandGroup': '解散群组',
      'disbandGroupConfirm': '这将永久解散您的家庭群组并移除所有护理员。您确定吗？',
      'disband': '解散',
      'disbandLeaveGroup': '解散并退出群组',
      'leaveGroup': '退出群组',
      'leaveGroupConfirm': '您确定要退出此群组吗？',
      'leave': '退出',
      'youHaveLeftGroup': '您已退出群组。',
      'groupDisbanded': '群组已解散。',
      'kickMember': '移除成员',
      'kickMemberConfirm': '您确定要将此成员从群组中移除吗？',
      'kick': '移除',
      'memberRemoved': '成员已从群组移除。',
      'renameGroup': '重命名群组',
      'newGroupName': '新群组名称',
      'groupRenamed': '群组名称已更新！',
      'rename': '重命名',
      'messages': '消息',
      'quickActions': '快捷操作',
      'dailyCheckInDesc': '手动每日报到，让护理员知道您一切安好。',
      'backgroundTracking': '后台活动追踪',
      'sleepModeActive': '睡眠模式已激活',
      'activityCheckTitle': '活动检查',
      'activityCheckMessage': '过去5小时内未检测到手机活动。您还好吗？',
      'imOk': '我很好',
      'phoneUnlockCheck': '手机解锁',
      'stepsCheck': '步数（50步以上）',
      'phonePickupCheck': '拿起手机',
      'steps': '步',
      'checkInStatus': '今日签到状态',
      'sleepWindow': '睡眠时段',
      'sleepWindowDesc': '设置睡眠时段，以便在睡眠期间暂停活动追踪。',
      'sleepWindowActive': '睡眠时段已激活',
      'setSleepWindow': '设置睡眠时段',
      'editSleepWindow': '编辑睡眠时段',
      'clearSleepWindow': '清除睡眠时段',
      'sleepWindowSaved': '睡眠时段已保存！',
      'sleepWindowCleared': '睡眠时段已清除。',
      'sleepStart': '入睡时间',
      'sleepEnd': '起床时间',
      'current': '当前',
      'adminLabel': '管理员',
      'activeSOSCount': '{count} 个紧急求救！',
      'dailyWellbeing': '每日健康问卷',
      'wellbeingGreeting': '您今天感觉怎么样？',
      'wellbeingSubtitle': '您的回答帮助家人更好地关心您。',
      'wellbeingMood': '您的心情如何？',
      'wellbeingPain': '有任何疼痛不适吗？',
      'wellbeingSleep': '您睡得怎么样？',
      'wellbeingAppetite': '您的胃口怎么样？',
      'wellbeingLonely': '您感到与家人联系紧密吗？',
      'wellbeingSaved': '谢谢！您的回答已保存。',
      'wellbeingSubmit': '提交',
      'wellbeingUpdate': '更新回答',
      'wellbeingAlreadyDone': '您今天已填写健康问卷。',
      'wellbeingHistory': '过去7天',
      'todayWellbeing': '今日健康状况',
      'noWellbeingData': '暂无健康记录。',
      'wellbeingButton': '每日健康问卷',
      'noMessagesChinese': '暂无消息。\n打个招呼吧！',
      'selectCaregiver': '选择护理员',
      'inviteCode': '邀请码',
      'inviteCodeHint': '输入6位邀请码',
      'joinWithCode': '使用邀请码加入',
      'joinWithCodeDesc': '输入乐龄人士分享的6位邀请码。',
      'yourInviteCode': '您的群组邀请码',
      'shareCode': '将此码分享给护理员，让他们直接加入。',
      'regenerateCode': '重新生成邀请码',
      'codeRegenerated': '已生成新邀请码！',
      'joinedWithCode': '成功加入群组！',
      'copyCode': '复制邀请码',
      'codeCopied': '已复制到剪贴板！',
      'orSearchByEmail': '或通过邮箱搜索',
      'orJoinWithCode': '或使用邀请码加入',
      'searching': '搜索中...',
      'dailyTrackingData': '每日追踪数据',
      'trackingDataDesc': '今日签到和健康状况摘要。',
      'clearTrackingData': '清除所有追踪数据',
      'clearTrackingDataConfirm': '这将删除您所有的签到、健康记录和SOS记录。此操作仅用于测试。您确定吗？',
      'clearTrackingDataDone': '所有追踪数据已清除。',
      'checkInsToday': '今日签到',
      'wellbeingScore': '健康评分',
      'notDoneToday': '今日未完成',
      'manualCheckInCount': '手动签到',
      'phoneUnlockCount': '手机解锁',
      'stepsCount': '步数记录',
      'pickupCount': '拿起手机',
      'sosCount': 'SOS警报',
      'devTesting': '开发者测试',
      'autoCheckInInterval': '自动报到间隔',
      'autoCheckInIntervalDesc': '设置应用程序应多久自动检查一次活动。（2-12小时）',
      'hours': '小时',
      'disabled': '已禁用',
      'autoCheckInEnabled': '启用自动报到',
      'autoCheckInSaved': '自动报到间隔已保存！',
      // ── Check-in config page ──
      'configureCheckIn': '配置报到设置',
      'currentConfiguration': '当前配置',
      'autoTracking': '自动追踪',
      'alertWindow': '警报窗口',
      'trackingLabel': '追踪项目',
      'notSet': '未设置',
      'alertInterval': '警报间隔',
      'liveLabel': '实时',
      'enabled': '已启用',
      'configureTitle': '配置 – {name}',
      'manualCheckInSection': '手动报到',
      'manualCheckInAlwaysOn': '始终活跃 — 24小时窗口。',
      'alwaysOn': '始终开启',
      'automaticSignals': '自动信号',
      'enableAutoTracking': '启用自动追踪',
      'autoTrackingSubtitle': '禁用时，仅手动报到计入。',
      'phoneUnlockLabel': '手机解锁',
      'phoneUnlockSubtitle': '每次屏幕解锁时计数。',
      'stepsWalking': '步数（步行）',
      'stepsWalkingSubtitle': '每检测到50步以上时计数。',
      'phonePickupLabel': '拿起手机',
      'phonePickupSubtitle': '通过运动传感器检测到拿起手机时计数。',
      'alertWindowSection': '警报窗口',
      'alertAfterHours': '无活动 {hours} 小时后发出警报',
      'alertWindowDesc': '若在此窗口内未检测到任何自动信号，将通知护理员。',
      'defaultTenH': '默认：10小时',
      'sleepWindowSection': '睡眠时段',
      'sleepWindowPauseDesc': '在此时段内暂停活动追踪。乐龄人士睡眠期间不会发出警报。',
      'clearLabel': '清除',
      'sleepTimeLabel': '入睡时间',
      'wakeTimeLabel': '起床时间',
      'noSleepWindowSet': '未设置睡眠时段 — 全天候追踪。',
      'saveAndSync': '保存并同步到设备',
      'syncBannerText': '更改已保存至 Firebase，并将在乐龄人士下次打开应用时自动同步。',
      'sleepValidationError': '请同时设置入睡时间和起床时间，或同时清除两者。',
      'settingsSaved': '设置已保存并同步到乐龄人士设备 ✓',
      'saveFailed': '保存失败：{error}',
    },

    // ── Malay ─────────────────────────────────────────────────────────────
    'ms': {
      'appName': 'ElderCare SG',
      'tagline': 'Keluarga anda, sentiasa berhubung',
      'cancel': 'Batal',
      'save': 'Simpan',
      'confirm': 'Sahkan',
      'logOut': 'Log Keluar',
      'logOutConfirm': 'Adakah anda pasti mahu log keluar?',
      'loading': 'Memuatkan...',
      'error': 'Ralat',
      'success': 'Berjaya',
      'changeLanguage': 'Tukar Bahasa',
      'selectLanguage': 'Pilih Bahasa',
      'login': 'Log Masuk',
      'signup': 'Buat Akaun',
      'forgotPassword': 'Lupa Kata Laluan?',
      'email': 'Alamat E-mel',
      'password': 'Kata Laluan',
      'confirmPassword': 'Sahkan Kata Laluan',
      'fullName': 'Nama Penuh',
      'phoneNumber': 'Nombor Telefon (pilihan)',
      'iAm': 'Saya seorang...',
      'elderly': 'Warga Emas',
      'caregiver': 'Penjaga',
      'elderlyDesc': 'Saya ingin\ndijaga',
      'caregiverDesc': 'Saya menjaga\nwarga emas',
      'noAccount': 'Tiada akaun?',
      'alreadyAccount': 'Sudah ada akaun?',
      'findMyAccount': 'Cari Akaun Saya',
      'resetPassword': 'Tetapkan Semula Kata Laluan',
      'setNewPassword': 'Tetapkan Kata Laluan Baharu',
      'newPassword': 'Kata Laluan Baharu',
      'saveNewPassword': 'Simpan Kata Laluan Baharu',
      'passwordResetSuccess': 'Kata laluan ditetapkan semula! Sila log masuk.',
      'accountCreated': 'Akaun dibuat! Sila log masuk.',
      'goodDay': 'Selamat datang,',
      'dailyCheckIn': 'Daftar Masuk Harian',
      'checkedInToday': 'Sudah Daftar Masuk Hari Ini',
      'tapToCheckIn': 'Ketik untuk Daftar Masuk',
      'lastCheckIn': 'Daftar masuk terakhir',
      'manual': 'Manual',
      'phoneUnlock': 'Buka kunci telefon',
      'checkInSuccess': 'Sudah daftar masuk! Penjaga telah dimaklumkan.',
      'myFamilyGroup': 'Kumpulan Keluarga Saya',
      'createOrJoin': 'Ketik untuk buat atau sertai kumpulan',
      'myCaregivers': 'Penjaga Saya',
      'noCaregivers': 'Tiada penjaga lagi.\nJemput penjaga dari Kumpulan Keluarga.',
      'pendingInvites': 'jemputan menunggu',
      'sosActive': 'SOS Aktif',
      'caringFor': 'Menjaga',
      'groups': 'kumpulan',
      'elderlyStatus': 'Status Warga Emas',
      'phoneActive': 'Telefon Aktif',
      'phoneInactive': 'Telefon Tidak Aktif',
      'checkedIn': 'Sudah Daftar Masuk',
      'notCheckedIn': 'Belum Daftar Masuk',
      'lastSeen': 'Terakhir dilihat',
      'sosHistory': 'Sejarah SOS',
      'manageGroups': 'Urus Kumpulan',
      'manageGroupsDesc': 'Sertai, minta atau urus kumpulan warga emas',
      'noGroups': 'Tiada kumpulan warga emas lagi',
      'noGroupsDesc': 'Sertai atau minta ditambah ke kumpulan warga emas.',
      'resolve': 'Selesai',
      'activeSOSAlerts': 'Amaran SOS Aktif!',
      'sendSOS': 'Hantar Amaran SOS',
      'sosDesc': 'Semua penjaga anda akan dimaklumkan dengan segera.\n\nTerangkan keadaan anda:',
      'sosHint': 'cth. Saya jatuh dan memerlukan bantuan...',
      'sendSOSButton': 'Hantar SOS',
      'sosSent': 'SOS dihantar! Penjaga telah dimaklumkan.',
      'myFamilyGroupPage': 'Kumpulan Keluarga Saya',
      'createYourGroup': 'Buat Kumpulan Anda',
      'createGroupDesc': 'Mulakan dengan membuat kumpulan keluarga. Penjaga boleh menyertai.',
      'groupName': 'Nama Kumpulan (cth. Keluarga Tan)',
      'createGroup': 'Buat Kumpulan',
      'groupCreated': 'Kumpulan dibuat!',
      'inviteCaregiver': 'Jemput penjaga dengan mencari e-mel mereka:',
      'searchCaregiverEmail': 'Cari penjaga melalui e-mel',
      'invite': 'Jemput',
      'inviteSent': 'Jemputan dihantar kepada',
      'allMembers': 'Semua Ahli',
      'pendingRequests': 'Permintaan Menunggu',
      'caregiverWantsToJoin': 'Penjaga ingin menyertai kumpulan anda',
      'youInvited': 'Anda telah menjemput penjaga ini',
      'you': 'Anda',
      'groupInvitations': 'Jemputan Kumpulan',
      'myGroups': 'Kumpulan Saya',
      'requestToJoin': 'Minta Sertai Kumpulan',
      'requestDesc': 'Cari warga emas melalui e-mel untuk minta menyertai kumpulan keluarga mereka:',
      'searchElderlyEmail': 'Cari warga emas melalui e-mel',
      'request': 'Minta',
      'requestSent': 'Permintaan dihantar kepada',
      'accept': 'Terima',
      'decline': 'Tolak',
      'joinedGroup': 'Telah menyertai kumpulan!',
      'inviteAccepted': 'Jemputan diterima!',
      'inviteDeclined': 'Jemputan ditolak.',
      'noGroupYet': 'Tiada kumpulan lagi',
      'invitedToJoin': 'Menjemput anda menyertai kumpulan mereka',
      'requestPending': 'Permintaan anda sedang diproses',
      'noGroupsJoined': 'Anda belum menyertai sebarang kumpulan.',
      'members': 'Ahli',
      'myProfile': 'Profil Saya',
      'editProfile': 'Edit Profil',
      'changePassword': 'Tukar Kata Laluan',
      'profileUpdated': 'Profil dikemaskini!',
      'saveChanges': 'Simpan Perubahan',
      'noMessages': 'Tiada mesej lagi.\nSapa',
      'typeMessage': 'Taip mesej...',
      'today': 'Hari ini',
      'yesterday': 'Semalam',
      'manualCheckIn': 'Daftar masuk manual',
      'phoneUnlockCheckIn': 'Buka kunci telefon',
      'noActivity': 'Tiada aktiviti direkodkan.',
      'editName': 'Edit Nama',
      'newName': 'Nama baharu',
      'rememberMe': 'Ingat saya',
      'noSosHistory': 'Tiada sejarah SOS',
      'setAdmin': 'Tetapkan Admin',
      'noAdmin': 'Tiada Admin',
      'adminSet': 'Admin berjaya dikemas kini',
      'adminRemoved': 'Admin telah dibuang',
      'activity': 'Aktiviti',
      'todayCheckIns': 'Daftar Masuk Hari Ini',
      'sosAlerts': 'Amaran SOS',
      'triggered': 'Dicetuskan',
      'resolvedAt': 'Diselesaikan pada',
      'duration': 'Tempoh',
      'total': 'Jumlah',
      'active': 'Aktif',
      'resolved': 'Diselesaikan',
      'sendMessage': 'Hantar Mesej',
      'newMessages': 'Mesej Baharu',
      'deleteMessage': 'Padam mesej ini',
      'deleteAllMessages': 'Padam Semua Mesej',
      'deleteAllConfirm': 'Ini akan memadamkan semua mesej dalam perbualan ini secara kekal. Adakah anda pasti?',
      'deleteAll': 'Padam Semua',
      'deleteForEveryone': 'Padam untuk semua',
      'deleteForMe': 'Padam untuk saya sahaja',
      'deletedMessage': 'Mesej ini telah dipadamkan',
      'disbandGroup': 'Bubarkan Kumpulan',
      'disbandGroupConfirm': 'Ini akan membubarkan kumpulan keluarga anda dan mengalih keluar semua penjaga. Adakah anda pasti?',
      'disband': 'Bubarkan',
      'disbandLeaveGroup': 'Bubarkan & Tinggalkan Kumpulan',
      'leaveGroup': 'Tinggalkan Kumpulan',
      'leaveGroupConfirm': 'Adakah anda pasti mahu meninggalkan kumpulan ini?',
      'leave': 'Tinggalkan',
      'youHaveLeftGroup': 'Anda telah meninggalkan kumpulan.',
      'groupDisbanded': 'Kumpulan telah dibubarkan.',
      'kickMember': 'Alih Keluar Ahli',
      'kickMemberConfirm': 'Adakah anda pasti mahu mengalih keluar ahli ini daripada kumpulan?',
      'kick': 'Alih Keluar',
      'memberRemoved': 'Ahli telah dialih keluar daripada kumpulan.',
      'renameGroup': 'Namakan Semula Kumpulan',
      'newGroupName': 'Nama kumpulan baharu',
      'groupRenamed': 'Nama kumpulan dikemas kini!',
      'rename': 'Namakan Semula',
      'messages': 'Mesej',
      'quickActions': 'Tindakan Pantas',
      'dailyCheckInDesc': 'Daftar masuk manual untuk memberitahu penjaga bahawa anda baik-baik saja.',
      'backgroundTracking': 'Penjejakan Aktiviti Latar',
      'sleepModeActive': 'Mod Tidur Aktif',
      'activityCheckTitle': 'Semakan Aktiviti',
      'activityCheckMessage': 'Tiada aktiviti dalam 5 jam terakhir. Adakah anda OK?',
      'imOk': 'Saya OK',
      'phoneUnlockCheck': 'Buka Kunci Telefon',
      'stepsCheck': 'Langkah (50+ langkah)',
      'phonePickupCheck': 'Ambil Telefon',
      'steps': 'langkah',
      'checkInStatus': 'Status Daftar Masuk (Hari Ini)',
      'sleepWindow': 'Waktu Tidur',
      'sleepWindowDesc': 'Tetapkan waktu tidur supaya penjejakan aktiviti dijeda semasa tidur.',
      'sleepWindowActive': 'Waktu tidur aktif',
      'setSleepWindow': 'Tetapkan Waktu Tidur',
      'editSleepWindow': 'Edit Waktu Tidur',
      'clearSleepWindow': 'Padam Waktu Tidur',
      'sleepWindowSaved': 'Waktu tidur disimpan!',
      'sleepWindowCleared': 'Waktu tidur dipadamkan.',
      'sleepStart': 'Mula Tidur',
      'sleepEnd': 'Masa Bangun',
      'current': 'Semasa',
      'adminLabel': 'Admin',
      'activeSOSCount': '{count} Amaran SOS Aktif!',
      'dailyWellbeing': 'Kesihatan Harian',
      'wellbeingGreeting': 'Bagaimana perasaan anda hari ini?',
      'wellbeingSubtitle': 'Jawapan anda membantu keluarga menjaga anda dengan lebih baik.',
      'wellbeingMood': 'Bagaimana mood anda?',
      'wellbeingPain': 'Ada sebarang kesakitan?',
      'wellbeingSleep': 'Bagaimana tidur anda?',
      'wellbeingAppetite': 'Bagaimana selera makan anda?',
      'wellbeingLonely': 'Adakah anda berasa berhubung dengan orang tersayang?',
      'wellbeingSaved': 'Terima kasih! Jawapan anda telah disimpan.',
      'wellbeingSubmit': 'Hantar',
      'wellbeingUpdate': 'Kemaskini Jawapan',
      'wellbeingAlreadyDone': 'Anda telah mengisi borang kesihatan hari ini.',
      'wellbeingHistory': '7 Hari Lepas',
      'todayWellbeing': 'Kesihatan Hari Ini',
      'noWellbeingData': 'Tiada rekod kesihatan lagi.',
      'wellbeingButton': 'Kesihatan Harian',
      'noMessagesChinese': 'Tiada mesej lagi.\nUcapkan hello!',
      'selectCaregiver': 'Pilih Penjaga',
      'inviteCode': 'Kod Jemputan',
      'inviteCodeHint': 'Masukkan kod 6 aksara',
      'joinWithCode': 'Sertai dengan Kod Jemputan',
      'joinWithCodeDesc': 'Masukkan kod 6 aksara yang dikongsi oleh warga emas.',
      'yourInviteCode': 'Kod Jemputan Kumpulan Anda',
      'shareCode': 'Kongsi kod ini dengan penjaga untuk mereka sertai terus.',
      'regenerateCode': 'Jana Semula Kod',
      'codeRegenerated': 'Kod jemputan baharu dijana!',
      'joinedWithCode': 'Berjaya menyertai kumpulan!',
      'copyCode': 'Salin Kod',
      'codeCopied': 'Kod disalin!',
      'orSearchByEmail': 'Atau cari melalui e-mel',
      'orJoinWithCode': 'Atau sertai dengan kod jemputan',
      'searching': 'Mencari...',
      'dailyTrackingData': 'Data Penjejakan Harian',
      'trackingDataDesc': 'Ringkasan daftar masuk dan kesihatan anda hari ini.',
      'clearTrackingData': 'Padam Semua Data Penjejakan',
      'clearTrackingDataConfirm': 'Ini akan memadamkan semua daftar masuk, rekod kesihatan dan rekod SOS anda. Ini hanya untuk ujian. Adakah anda pasti?',
      'clearTrackingDataDone': 'Semua data penjejakan telah dipadamkan.',
      'checkInsToday': 'Daftar Masuk Hari Ini',
      'wellbeingScore': 'Skor Kesihatan',
      'notDoneToday': 'Belum selesai hari ini',
      'manualCheckInCount': 'Daftar Masuk Manual',
      'phoneUnlockCount': 'Buka Kunci Telefon',
      'stepsCount': 'Sesi Langkah',
      'pickupCount': 'Ambil Telefon',
      'sosCount': 'Amaran SOS',
      'devTesting': 'Pembangun & Ujian',
      'autoCheckInInterval': 'Selang Daftar Masuk Auto',
      'autoCheckInIntervalDesc': 'Tetapkan kekerapan aplikasi harus memeriksa aktiviti secara automatik. (2-12 jam)',
      'hours': 'jam',
      'disabled': 'Nyahaktif',
      'autoCheckInEnabled': 'Aktifkan Daftar Masuk Auto',
      'autoCheckInSaved': 'Selang daftar masuk auto disimpan!',
      // ── Check-in config page ──
      'configureCheckIn': 'Konfigurasi Tetapan Daftar Masuk',
      'currentConfiguration': 'Konfigurasi Semasa',
      'autoTracking': 'Penjejakan auto',
      'alertWindow': 'Tetingkap amaran',
      'trackingLabel': 'Penjejakan',
      'notSet': 'Tidak ditetapkan',
      'alertInterval': 'Selang amaran',
      'liveLabel': 'Langsung',
      'enabled': 'Diaktifkan',
      'configureTitle': 'Konfigurasi – {name}',
      'manualCheckInSection': 'Daftar Masuk Manual',
      'manualCheckInAlwaysOn': 'Sentiasa aktif — tetingkap 24 jam.',
      'alwaysOn': 'Sentiasa HIDUP',
      'automaticSignals': 'Isyarat Automatik',
      'enableAutoTracking': 'Aktifkan Penjejakan Automatik',
      'autoTrackingSubtitle': 'Apabila dinyahaktifkan, hanya daftar masuk manual dikira.',
      'phoneUnlockLabel': 'Buka Kunci Telefon',
      'phoneUnlockSubtitle': 'Dikira setiap kali skrin dibuka kuncinya.',
      'stepsWalking': 'Langkah (Berjalan)',
      'stepsWalkingSubtitle': 'Dikira setiap 50+ langkah dikesan.',
      'phonePickupLabel': 'Ambil Telefon',
      'phonePickupSubtitle': 'Dikira apabila telefon diambil melalui penderia gerakan.',
      'alertWindowSection': 'Tetingkap Amaran',
      'alertAfterHours': 'Amaran selepas {hours} jam tanpa aktiviti',
      'alertWindowDesc': 'Jika tiada isyarat automatik dikesan dalam tetingkap ini, penjaga akan dimaklumkan.',
      'defaultTenH': 'Lalai: 10j',
      'sleepWindowSection': 'Waktu Tidur',
      'sleepWindowPauseDesc': 'Penjejakan aktiviti dijeda semasa waktu ini. Tiada amaran akan dihantar semasa warga emas tidur.',
      'clearLabel': 'Padam',
      'sleepTimeLabel': 'Masa tidur',
      'wakeTimeLabel': 'Masa bangun',
      'noSleepWindowSet': 'Tiada waktu tidur ditetapkan — penjejakan berjalan 24/7.',
      'saveAndSync': 'Simpan & Segerakkan ke Peranti',
      'syncBannerText': 'Perubahan disimpan ke Firebase dan disegerakkan secara automatik ke peranti warga emas pada pembukaan aplikasi seterusnya.',
      'sleepValidationError': 'Sila tetapkan masa tidur dan masa bangun, atau padam kedua-duanya.',
      'settingsSaved': 'Tetapan disimpan dan disegerakkan ke peranti warga emas ✓',
      'saveFailed': 'Simpan gagal: {error}',
    },

    // ── Tamil ─────────────────────────────────────────────────────────────
    'ta': {
      'appName': 'ElderCare SG',
      'tagline': 'உங்கள் குடும்பம், எப்போதும் இணைந்திருக்கும்',
      'cancel': 'ரத்து செய்',
      'save': 'சேமி',
      'confirm': 'உறுதிப்படுத்து',
      'logOut': 'வெளியேறு',
      'logOutConfirm': 'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'success': 'வெற்றி',
      'changeLanguage': 'மொழி மாற்று',
      'selectLanguage': 'மொழியை தேர்ந்தெடுக்கவும்',
      'login': 'உள்நுழை',
      'signup': 'கணக்கு உருவாக்கு',
      'forgotPassword': 'கடவுச்சொல் மறந்தீர்களா?',
      'email': 'மின்னஞ்சல் முகவரி',
      'password': 'கடவுச்சொல்',
      'confirmPassword': 'கடவுச்சொல்லை உறுதிப்படுத்து',
      'fullName': 'முழு பெயர்',
      'phoneNumber': 'தொலைபேசி எண் (விருப்பமானது)',
      'iAm': 'நான்...',
      'elderly': 'முதியோர்',
      'caregiver': 'பராமரிப்பாளர்',
      'elderlyDesc': 'என்னை\nகவனிக்க வேண்டும்',
      'caregiverDesc': 'நான் ஒரு முதியோரை\nகவனிக்கிறேன்',
      'noAccount': 'கணக்கு இல்லையா?',
      'alreadyAccount': 'ஏற்கனவே கணக்கு உள்ளதா?',
      'findMyAccount': 'என் கணக்கை கண்டுபிடி',
      'resetPassword': 'கடவுச்சொல் மீட்டமை',
      'setNewPassword': 'புதிய கடவுச்சொல் அமை',
      'newPassword': 'புதிய கடவுச்சொல்',
      'saveNewPassword': 'புதிய கடவுச்சொல் சேமி',
      'passwordResetSuccess': 'கடவுச்சொல் மீட்டமைக்கப்பட்டது! உள்நுழையவும்.',
      'accountCreated': 'கணக்கு உருவாக்கப்பட்டது! உள்நுழையவும்.',
      'goodDay': 'வணக்கம்,',
      'dailyCheckIn': 'தினசரி செக்-இன்',
      'checkedInToday': 'இன்று செக்-இன் செய்தீர்கள்',
      'tapToCheckIn': 'செக்-இன் செய்ய தட்டவும்',
      'lastCheckIn': 'கடைசி செக்-இன்',
      'manual': 'கையேடு',
      'phoneUnlock': 'தொலைபேசி திறப்பு',
      'checkInSuccess': 'செக்-இன் செய்யப்பட்டது! பராமரிப்பாளர்களுக்கு அறிவிக்கப்பட்டது.',
      'myFamilyGroup': 'என் குடும்ப குழு',
      'createOrJoin': 'குழுவை உருவாக்க அல்லது சேர தட்டவும்',
      'myCaregivers': 'என் பராமரிப்பாளர்கள்',
      'noCaregivers': 'பராமரிப்பாளர்கள் இல்லை.\nகுடும்ப குழுவிலிருந்து அழைக்கவும்.',
      'pendingInvites': 'நிலுவையில் உள்ள அழைப்புகள்',
      'sosActive': 'SOS செயலில் உள்ளது',
      'caringFor': 'கவனிக்கிறேன்',
      'groups': 'குழுக்கள்',
      'elderlyStatus': 'முதியோர் நிலை',
      'phoneActive': 'தொலைபேசி செயலில்',
      'phoneInactive': 'தொலைபேசி செயலற்றது',
      'checkedIn': 'செக்-இன் செய்தார்',
      'notCheckedIn': 'செக்-இன் செய்யவில்லை',
      'lastSeen': 'கடைசியாக பார்க்கப்பட்டது',
      'sosHistory': 'SOS வரலாறு',
      'manageGroups': 'குழுக்களை நிர்வகி',
      'manageGroupsDesc': 'முதியோர் குழுக்களை சேர்க்கவும் அல்லது நிர்வகிக்கவும்',
      'noGroups': 'குழுக்கள் இல்லை',
      'noGroupsDesc': 'முதியோரின் குழுவில் சேர கோரிக்கை அனுப்பவும்.',
      'resolve': 'தீர்க்கப்பட்டது',
      'activeSOSAlerts': 'செயலில் SOS எச்சரிக்கை!',
      'sendSOS': 'SOS எச்சரிக்கை அனுப்பு',
      'sosDesc': 'உங்கள் பராமரிப்பாளர்களுக்கு உடனடியாக அறிவிக்கப்படும்.\n\nஉங்கள் நிலையை விவரிக்கவும்:',
      'sosHint': 'எ.கா. நான் விழுந்தேன், உதவி தேவை...',
      'sendSOSButton': 'SOS அனுப்பு',
      'sosSent': 'SOS அனுப்பப்பட்டது! பராமரிப்பாளர்களுக்கு அறிவிக்கப்பட்டது.',
      'myFamilyGroupPage': 'என் குடும்ப குழு',
      'createYourGroup': 'உங்கள் குழுவை உருவாக்கவும்',
      'createGroupDesc': 'குடும்ப குழுவை உருவாக்கவும். பராமரிப்பாளர்கள் சேரலாம்.',
      'groupName': 'குழு பெயர் (எ.கா. தான் குடும்பம்)',
      'createGroup': 'குழு உருவாக்கு',
      'groupCreated': 'குழு உருவாக்கப்பட்டது!',
      'inviteCaregiver': 'மின்னஞ்சல் மூலம் பராமரிப்பாளரை தேடவும்:',
      'searchCaregiverEmail': 'பராமரிப்பாளர் மின்னஞ்சல் தேடு',
      'invite': 'அழைப்பு',
      'inviteSent': 'அழைப்பு அனுப்பப்பட்டது',
      'allMembers': 'அனைத்து உறுப்பினர்கள்',
      'pendingRequests': 'நிலுவையில் உள்ள கோரிக்கைகள்',
      'caregiverWantsToJoin': 'பராமரிப்பாளர் குழுவில் சேர விரும்புகிறார்',
      'youInvited': 'நீங்கள் இந்த பராமரிப்பாளரை அழைத்தீர்கள்',
      'you': 'நீங்கள்',
      'groupInvitations': 'குழு அழைப்புகள்',
      'myGroups': 'என் குழுக்கள்',
      'requestToJoin': 'குழுவில் சேர கோரிக்கை',
      'requestDesc': 'முதியோரின் குடும்ப குழுவில் சேர மின்னஞ்சல் மூலம் தேடவும்:',
      'searchElderlyEmail': 'முதியோர் மின்னஞ்சல் தேடு',
      'request': 'கோரிக்கை',
      'requestSent': 'கோரிக்கை அனுப்பப்பட்டது',
      'accept': 'ஏற்க',
      'decline': 'நிராகரி',
      'joinedGroup': 'குழுவில் சேர்ந்தீர்கள்!',
      'inviteAccepted': 'அழைப்பு ஏற்கப்பட்டது!',
      'inviteDeclined': 'அழைப்பு நிராகரிக்கப்பட்டது.',
      'noGroupYet': 'குழு இல்லை',
      'invitedToJoin': 'உங்களை குழுவில் சேர அழைக்கிறார்',
      'requestPending': 'உங்கள் கோரிக்கை நிலுவையில் உள்ளது',
      'noGroupsJoined': 'நீங்கள் எந்த குழுவிலும் சேரவில்லை.',
      'members': 'உறுப்பினர்கள்',
      'myProfile': 'என் சுயவிவரம்',
      'editProfile': 'சுயவிவரம் திருத்து',
      'changePassword': 'கடவுச்சொல் மாற்று',
      'profileUpdated': 'சுயவிவரம் புதுப்பிக்கப்பட்டது!',
      'saveChanges': 'மாற்றங்களை சேமி',
      'noMessages': 'செய்திகள் இல்லை.\nவணக்கம் சொல்லுங்கள்',
      'typeMessage': 'செய்தி தட்டச்சு செய்யவும்...',
      'today': 'இன்று',
      'yesterday': 'நேற்று',
      'manualCheckIn': 'கையேடு செக்-இன்',
      'phoneUnlockCheckIn': 'தொலைபேசி திறப்பு',
      'noActivity': 'செயல்பாடு பதிவு இல்லை.',
      'editName': 'பெயர் திருத்து',
      'newName': 'புதிய பெயர்',
      'rememberMe': 'என்னை நினைவில் வை',
      'noSosHistory': 'SOS வரலாறு இல்லை',
      'setAdmin': 'நிர்வாகியை அமை',
      'noAdmin': 'நிர்வாகி இல்லை',
      'adminSet': 'நிர்வாகி வெற்றிகரமாக புதுப்பிக்கப்பட்டது',
      'adminRemoved': 'நிர்வாகி நீக்கப்பட்டார்',
      'activity': 'செயல்பாடு',
      'todayCheckIns': 'இன்றைய செக்-இன்கள்',
      'sosAlerts': 'SOS எச்சரிக்கைகள்',
      'triggered': 'தூண்டப்பட்டது',
      'resolvedAt': 'தீர்க்கப்பட்டது',
      'duration': 'கால அளவு',
      'total': 'மொத்தம்',
      'active': 'செயலில்',
      'resolved': 'தீர்க்கப்பட்டது',
      'sendMessage': 'செய்தி அனுப்பு',
      'newMessages': 'புதிய செய்திகள்',
      'deleteMessage': 'இந்த செய்தியை நீக்கு',
      'deleteAllMessages': 'அனைத்து செய்திகளையும் நீக்கு',
      'deleteAllConfirm': 'இது இந்த உரையாடலில் உள்ள அனைத்து செய்திகளையும் நிரந்தரமாக நீக்கும். நீங்கள் உறுதியாக இருக்கிறீர்களா?',
      'deleteAll': 'அனைத்தும் நீக்கு',
      'deleteForEveryone': 'அனைவருக்கும் நீக்கு',
      'deleteForMe': 'என்னுக்காக மட்டும் நீக்கு',
      'deletedMessage': 'இந்த செய்தி நீக்கப்பட்டது',
      'disbandGroup': 'குழுவை கலைக்கவும்',
      'disbandGroupConfirm': 'இது உங்கள் குடும்ப குழுவை நிரந்தரமாக கலைத்து அனைத்து பராமரிப்பாளர்களையும் நீக்கும். நீங்கள் உறுதியாக இருக்கிறீர்களா?',
      'disband': 'கலைக்கவும்',
      'disbandLeaveGroup': 'கலைத்து குழுவை விட்டு வெளியேறு',
      'leaveGroup': 'குழுவை விட்டு வெளியேறு',
      'leaveGroupConfirm': 'இந்த குழுவை விட்டு வெளியேற விரும்புகிறீர்களா?',
      'leave': 'வெளியேறு',
      'youHaveLeftGroup': 'நீங்கள் குழுவை விட்டு வெளியேறினீர்கள்.',
      'groupDisbanded': 'குழு கலைக்கப்பட்டது.',
      'kickMember': 'உறுப்பினரை நீக்கு',
      'kickMemberConfirm': 'இந்த உறுப்பினரை குழுவிலிருந்து நீக்க விரும்புகிறீர்களா?',
      'kick': 'நீக்கு',
      'memberRemoved': 'உறுப்பினர் குழுவிலிருந்து நீக்கப்பட்டார்.',
      'renameGroup': 'குழுவை மறுபெயரிடு',
      'newGroupName': 'புதிய குழு பெயர்',
      'groupRenamed': 'குழு பெயர் புதுப்பிக்கப்பட்டது!',
      'rename': 'மறுபெயரிடு',
      'messages': 'செய்திகள்',
      'quickActions': 'விரைவு செயல்கள்',
      'dailyCheckInDesc': 'பராமரிப்பாளர்களுக்கு நீங்கள் நலமாக உள்ளீர்கள் என்று தெரிவிக்க.',
      'backgroundTracking': 'பின்னணி செயல்பாடு கண்காணிப்பு',
      'sleepModeActive': 'தூக்க பயன்முறை செயலில் உள்ளது',
      'activityCheckTitle': 'செயல்பாடு சரிபார்ப்பு',
      'activityCheckMessage': '5 மணி நேரத்தில் செயல்பாடு இல்லை. நீங்கள் நலமா?',
      'imOk': 'நான் சரியாக உள்ளேன்',
      'phoneUnlockCheck': 'தொலைபேசி திறத்தல்',
      'stepsCheck': 'படிகள் (50+ படிகள்)',
      'phonePickupCheck': 'தொலைபேசி எடுத்தல்',
      'steps': 'படிகள்',
      'checkInStatus': 'செக்-இன் நிலை (இன்று)',
      'sleepWindow': 'தூக்க நேரம்',
      'sleepWindowDesc': 'தூக்க நேரத்தில் கண்காணிப்பு இடைநிறுத்தப்படும்.',
      'sleepWindowActive': 'தூக்க நேரம் செயலில் உள்ளது',
      'setSleepWindow': 'தூக்க நேரம் அமை',
      'editSleepWindow': 'தூக்க நேரம் திருத்து',
      'clearSleepWindow': 'தூக்க நேரம் நீக்கு',
      'sleepWindowSaved': 'தூக்க நேரம் சேமிக்கப்பட்டது!',
      'sleepWindowCleared': 'தூக்க நேரம் நீக்கப்பட்டது.',
      'sleepStart': 'தூக்கம் தொடக்கம்',
      'sleepEnd': 'எழுந்திரிக்கும் நேரம்',
      'current': 'தற்போதைய',
      'adminLabel': 'நிர்வாகி',
      'activeSOSCount': '{count} SOS எச்சரிக்கை!',
      'dailyWellbeing': 'தினசரி நலன் கேள்வி',
      'wellbeingGreeting': 'இன்று உங்களுக்கு எப்படி இருக்கிறது?',
      'wellbeingSubtitle': 'உங்கள் பதில்கள் குடும்பம் உங்களை சிறப்பாக கவனிக்க உதவும்.',
      'wellbeingMood': 'உங்கள் மனநிலை எப்படி?',
      'wellbeingPain': 'ஏதாவது வலி உள்ளதா?',
      'wellbeingSleep': 'நீங்கள் எப்படி தூங்கினீர்கள்?',
      'wellbeingAppetite': 'உங்கள் பசி எப்படி?',
      'wellbeingLonely': 'நீங்கள் இணைப்பாக உணர்கிறீர்களா?',
      'wellbeingSaved': 'நன்றி! உங்கள் பதில்கள் சேமிக்கப்பட்டன.',
      'wellbeingSubmit': 'சமர்ப்பி',
      'wellbeingUpdate': 'பதில்களை புதுப்பி',
      'wellbeingAlreadyDone': 'இன்று ஏற்கனவே நலன் கேள்வி நிரப்பினீர்கள்.',
      'wellbeingHistory': 'கடந்த 7 நாட்கள்',
      'todayWellbeing': 'இன்றைய நலன்',
      'noWellbeingData': 'நலன் பதிவுகள் இல்லை.',
      'wellbeingButton': 'தினசரி நலன்',
      'noMessagesChinese': 'செய்திகள் இல்லை.\nவணக்கம் சொல்லுங்கள்!',
      'selectCaregiver': 'பராமரிப்பாளரை தேர்ந்தெடுக்கவும்',
      'inviteCode': 'அழைப்பு குறியீடு',
      'inviteCodeHint': '6 எழுத்து குறியீடு',
      'joinWithCode': 'குறியீட்டுடன் சேர',
      'joinWithCodeDesc': 'முதியோர் பகிர்ந்த 6 எழுத்து குறியீட்டை உள்ளிடவும்.',
      'yourInviteCode': 'உங்கள் குழு அழைப்பு குறியீடு',
      'shareCode': 'பராமரிப்பாளர்கள் சேர இந்த குறியீட்டை பகிரவும்.',
      'regenerateCode': 'குறியீட்டை மீண்டும் உருவாக்கு',
      'codeRegenerated': 'புதிய அழைப்பு குறியீடு உருவாக்கப்பட்டது!',
      'joinedWithCode': 'குழுவில் வெற்றிகரமாக சேர்ந்தீர்கள்!',
      'copyCode': 'குறியீட்டை நகலெடு',
      'codeCopied': 'குறியீடு நகலெடுக்கப்பட்டது!',
      'orSearchByEmail': 'மின்னஞ்சல் மூலம் தேடவும்',
      'orJoinWithCode': 'அழைப்பு குறியீட்டுடன் சேரவும்',
      'searching': 'தேடுகிறது...',
      'dailyTrackingData': 'தினசரி கண்காணிப்பு தரவு',
      'trackingDataDesc': 'இன்றைய செக்-இன் மற்றும் நலன் சுருக்கம்.',
      'clearTrackingData': 'அனைத்து கண்காணிப்பு தரவையும் நீக்கு',
      'clearTrackingDataConfirm': 'இது உங்கள் செக்-இன், நலன் மற்றும் SOS பதிவுகளை நீக்கும். இது சோதனைக்கு மட்டுமே. உறுதியா?',
      'clearTrackingDataDone': 'அனைத்து கண்காணிப்பு தரவும் நீக்கப்பட்டது.',
      'checkInsToday': 'இன்றைய செக்-இன்கள்',
      'wellbeingScore': 'நலன் மதிப்பெண்',
      'notDoneToday': 'இன்று முடிக்கவில்லை',
      'manualCheckInCount': 'கையேடு செக்-இன்',
      'phoneUnlockCount': 'தொலைபேசி திறப்பு',
      'stepsCount': 'படி அமர்வுகள்',
      'pickupCount': 'தொலைபேசி எடுத்தல்',
      'sosCount': 'SOS எச்சரிக்கைகள்',
      'devTesting': 'டெவலப்பர் சோதனை',
      'autoCheckInInterval': 'தானியங்கி செக்-இன் இடைவேளை',
      'autoCheckInIntervalDesc': 'செயல்பாட்டை எவ்வளவு அடிக்கடி சரிபார்க்க வேண்டும் என்பதை அமைக்கவும். (2-12 மணிநேரம்)',
      'hours': 'மணிநேரம்',
      'disabled': 'முடக்கப்பட்டது',
      'autoCheckInEnabled': 'தானியங்கி செக்-இன் இயக்கப்பட்டது',
      'autoCheckInSaved': 'தானியங்கி செக்-இன் இடைவேளை சேமிக்கப்பட்டது!',
      // ── Check-in config page ──
      'configureCheckIn': 'செக்-இன் அமைப்புகளை உள்ளமை',
      'currentConfiguration': 'தற்போதைய உள்ளமைவு',
      'autoTracking': 'தானியங்கி கண்காணிப்பு',
      'alertWindow': 'எச்சரிக்கை சாளரம்',
      'trackingLabel': 'கண்காணிப்பு',
      'notSet': 'அமைக்கப்படவில்லை',
      'alertInterval': 'எச்சரிக்கை இடைவேளை',
      'liveLabel': 'நேரடி',
      'enabled': 'இயக்கப்பட்டது',
      'configureTitle': 'உள்ளமை – {name}',
      'manualCheckInSection': 'கையேடு செக்-இன்',
      'manualCheckInAlwaysOn': 'எப்போதும் செயலில் — 24 மணி நேர சாளரம்.',
      'alwaysOn': 'எப்போதும் இயக்கம்',
      'automaticSignals': 'தானியங்கி சமிக்ஞைகள்',
      'enableAutoTracking': 'தானியங்கி கண்காணிப்பை இயக்கு',
      'autoTrackingSubtitle': 'முடக்கப்படும்போது, கையேடு செக்-இன் மட்டுமே கணக்கிடப்படும்.',
      'phoneUnlockLabel': 'தொலைபேசி திறத்தல்',
      'phoneUnlockSubtitle': 'திரை திறக்கப்படும் ஒவ்வொரு முறையும் கணக்கிடப்படும்.',
      'stepsWalking': 'படிகள் (நடை)',
      'stepsWalkingSubtitle': '50+ படிகள் கண்டறியப்படும் ஒவ்வொரு முறையும் கணக்கிடப்படும்.',
      'phonePickupLabel': 'தொலைபேசி எடுத்தல்',
      'phonePickupSubtitle': 'இயக்க உணர்திகள் மூலம் தொலைபேசி எடுக்கப்படும்போது கணக்கிடப்படும்.',
      'alertWindowSection': 'எச்சரிக்கை சாளரம்',
      'alertAfterHours': '{hours} மணி நேர செயலற்ற நிலையில் எச்சரிக்கை',
      'alertWindowDesc': 'இந்த சாளரத்தில் தானியங்கி சமிக்ஞை எதுவும் கண்டறியப்படவில்லை எனில், பராமரிப்பாளர்களுக்கு அறிவிக்கப்படும்.',
      'defaultTenH': 'இயல்பு: 10 மணி',
      'sleepWindowSection': 'தூக்க நேரம்',
      'sleepWindowPauseDesc': 'இந்த நேரத்தில் செயல்பாடு கண்காணிப்பு இடைநிறுத்தப்படும். முதியோர் தூங்கும்போது எச்சரிக்கைகள் வராது.',
      'clearLabel': 'நீக்கு',
      'sleepTimeLabel': 'தூக்க நேரம்',
      'wakeTimeLabel': 'எழுந்திரிக்கும் நேரம்',
      'noSleepWindowSet': 'தூக்க நேரம் அமைக்கப்படவில்லை — கண்காணிப்பு 24/7 இயங்கும்.',
      'saveAndSync': 'சேமித்து சாதனத்துடன் ஒத்திசை',
      'syncBannerText': 'மாற்றங்கள் Firebase இல் சேமிக்கப்பட்டு, முதியோர் அடுத்த முறை ஆப் திறக்கும்போது தானாக ஒத்திசைக்கப்படும்.',
      'sleepValidationError': 'தூக்க தொடக்க நேரம் மற்றும் எழுந்திரிக்கும் நேரம் இரண்டையும் அமைக்கவும், அல்லது இரண்டையும் நீக்கவும்.',
      'settingsSaved': 'அமைப்புகள் சேமிக்கப்பட்டு முதியோர் சாதனத்துடன் ஒத்திசைக்கப்பட்டன ✓',
      'saveFailed': 'சேமிப்பு தோல்வி: {error}',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }

  String get appName => get('appName');
  String get tagline => get('tagline');
  String get cancel => get('cancel');
  String get save => get('save');
  String get logOut => get('logOut');
  String get logOutConfirm => get('logOutConfirm');
  String get changeLanguage => get('changeLanguage');
  String get selectLanguage => get('selectLanguage');
  String get login => get('login');
  String get signup => get('signup');
  String get forgotPassword => get('forgotPassword');
  String get email => get('email');
  String get password => get('password');
  String get confirmPassword => get('confirmPassword');
  String get fullName => get('fullName');
  String get phoneNumber => get('phoneNumber');
  String get iAm => get('iAm');
  String get elderly => get('elderly');
  String get caregiver => get('caregiver');
  String get elderlyDesc => get('elderlyDesc');
  String get caregiverDesc => get('caregiverDesc');
  String get noAccount => get('noAccount');
  String get findMyAccount => get('findMyAccount');
  String get resetPassword => get('resetPassword');
  String get setNewPassword => get('setNewPassword');
  String get newPassword => get('newPassword');
  String get saveNewPassword => get('saveNewPassword');
  String get goodDay => get('goodDay');
  String get dailyCheckIn => get('dailyCheckIn');
  String get checkedInToday => get('checkedInToday');
  String get tapToCheckIn => get('tapToCheckIn');
  String get lastCheckIn => get('lastCheckIn');
  String get manual => get('manual');
  String get phoneUnlock => get('phoneUnlock');
  String get checkInSuccess => get('checkInSuccess');
  String get myFamilyGroup => get('myFamilyGroup');
  String get createOrJoin => get('createOrJoin');
  String get myCaregivers => get('myCaregivers');
  String get noCaregivers => get('noCaregivers');
  String get pendingInvites => get('pendingInvites');
  String get sosActive => get('sosActive');
  String get elderlyStatus => get('elderlyStatus');
  String get phoneActive => get('phoneActive');
  String get phoneInactive => get('phoneInactive');
  String get checkedIn => get('checkedIn');
  String get notCheckedIn => get('notCheckedIn');
  String get lastSeen => get('lastSeen');
  String get sosHistory => get('sosHistory');
  String get manageGroups => get('manageGroups');
  String get manageGroupsDesc => get('manageGroupsDesc');
  String get noGroups => get('noGroups');
  String get noGroupsDesc => get('noGroupsDesc');
  String get resolve => get('resolve');
  String get sendSOS => get('sendSOS');
  String get sosDesc => get('sosDesc');
  String get sosHint => get('sosHint');
  String get sendSOSButton => get('sendSOSButton');
  String get sosSent => get('sosSent');
  String get myFamilyGroupPage => get('myFamilyGroupPage');
  String get createYourGroup => get('createYourGroup');
  String get createGroupDesc => get('createGroupDesc');
  String get groupName => get('groupName');
  String get createGroup => get('createGroup');
  String get groupCreated => get('groupCreated');
  String get inviteCaregiver => get('inviteCaregiver');
  String get searchCaregiverEmail => get('searchCaregiverEmail');
  String get invite => get('invite');
  String get allMembers => get('allMembers');
  String get pendingRequests => get('pendingRequests');
  String get caregiverWantsToJoin => get('caregiverWantsToJoin');
  String get youInvited => get('youInvited');
  String get you => get('you');
  String get groupInvitations => get('groupInvitations');
  String get myGroups => get('myGroups');
  String get requestToJoin => get('requestToJoin');
  String get requestDesc => get('requestDesc');
  String get searchElderlyEmail => get('searchElderlyEmail');
  String get request => get('request');
  String get accept => get('accept');
  String get decline => get('decline');
  String get noGroupYet => get('noGroupYet');
  String get noGroupsJoined => get('noGroupsJoined');
  String get myProfile => get('myProfile');
  String get editProfile => get('editProfile');
  String get changePassword => get('changePassword');
  String get profileUpdated => get('profileUpdated');
  String get saveChanges => get('saveChanges');
  String get typeMessage => get('typeMessage');
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get manualCheckIn => get('manualCheckIn');
  String get phoneUnlockCheckIn => get('phoneUnlockCheckIn');
  String get passwordResetSuccess => get('passwordResetSuccess');
  String get accountCreated => get('accountCreated');
  String get invitedToJoin => get('invitedToJoin');
  String get requestPending => get('requestPending');
  String get caringFor => get('caringFor');
  String get groups => get('groups');
  String get noActivity => get('noActivity');
  String get inviteSent => get('inviteSent');
  String get inviteAccepted => get('inviteAccepted');
  String get inviteDeclined => get('inviteDeclined');
  String get joinedGroup => get('joinedGroup');
  String get requestSent => get('requestSent');
  String get members => get('members');
  String get noMessages => get('noMessages');
  String get editName => get('editName');
  String get newName => get('newName');
  String get rememberMe => get('rememberMe');
  String get noSosHistory => get('noSosHistory');
  String get setAdmin => get('setAdmin');
  String get noAdmin => get('noAdmin');
  String get adminSet => get('adminSet');
  String get adminRemoved => get('adminRemoved');
  String get activity => get('activity');
  String get todayCheckIns => get('todayCheckIns');
  String get sosAlerts => get('sosAlerts');
  String get triggered => get('triggered');
  String get resolvedAt => get('resolvedAt');
  String get duration => get('duration');
  String get total => get('total');
  String get active => get('active');
  String get resolved => get('resolved');
  String get sendMessage => get('sendMessage');
  String get newMessages => get('newMessages');
  String get deleteMessage => get('deleteMessage');
  String get deleteAllMessages => get('deleteAllMessages');
  String get deleteAllConfirm => get('deleteAllConfirm');
  String get deleteAll => get('deleteAll');
  String get disbandGroup => get('disbandGroup');
  String get disbandGroupConfirm => get('disbandGroupConfirm');
  String get disband => get('disband');
  String get disbandLeaveGroup => get('disbandLeaveGroup');
  String get leaveGroup => get('leaveGroup');
  String get leaveGroupConfirm => get('leaveGroupConfirm');
  String get leave => get('leave');
  String get youHaveLeftGroup => get('youHaveLeftGroup');
  String get groupDisbanded => get('groupDisbanded');
  String get kickMember => get('kickMember');
  String get kickMemberConfirm => get('kickMemberConfirm');
  String get kick => get('kick');
  String get memberRemoved => get('memberRemoved');
  String get renameGroup => get('renameGroup');
  String get newGroupName => get('newGroupName');
  String get groupRenamed => get('groupRenamed');
  String get rename => get('rename');
  String get deleteForEveryone => get('deleteForEveryone');
  String get deleteForMe => get('deleteForMe');
  String get deletedMessage => get('deletedMessage');
  String get messages => get('messages');
  String get quickActions => get('quickActions');
  String get dailyCheckInDesc => get('dailyCheckInDesc');
  String get backgroundTracking => get('backgroundTracking');
  String get sleepModeActive => get('sleepModeActive');
  String get activityCheckTitle => get('activityCheckTitle');
  String get activityCheckMessage => get('activityCheckMessage');
  String get imOk => get('imOk');
  String get phoneUnlockCheck => get('phoneUnlockCheck');
  String get stepsCheck => get('stepsCheck');
  String get phonePickupCheck => get('phonePickupCheck');
  String get steps => get('steps');
  String get checkInStatus => get('checkInStatus');
  String get sleepWindow => get('sleepWindow');
  String get sleepWindowDesc => get('sleepWindowDesc');
  String get sleepWindowActive => get('sleepWindowActive');
  String get setSleepWindow => get('setSleepWindow');
  String get editSleepWindow => get('editSleepWindow');
  String get clearSleepWindow => get('clearSleepWindow');
  String get sleepWindowSaved => get('sleepWindowSaved');
  String get sleepWindowCleared => get('sleepWindowCleared');
  String get sleepStart => get('sleepStart');
  String get sleepEnd => get('sleepEnd');
  String get current => get('current');
  String get adminLabel => get('adminLabel');
  String activeSOSCount(int count) => get('activeSOSCount').replaceAll('{count}', '$count');
  String get dailyWellbeing => get('dailyWellbeing');
  String get wellbeingGreeting => get('wellbeingGreeting');
  String get wellbeingSubtitle => get('wellbeingSubtitle');
  String get wellbeingMood => get('wellbeingMood');
  String get wellbeingPain => get('wellbeingPain');
  String get wellbeingSleep => get('wellbeingSleep');
  String get wellbeingAppetite => get('wellbeingAppetite');
  String get wellbeingLonely => get('wellbeingLonely');
  String get wellbeingSaved => get('wellbeingSaved');
  String get wellbeingSubmit => get('wellbeingSubmit');
  String get wellbeingUpdate => get('wellbeingUpdate');
  String get wellbeingAlreadyDone => get('wellbeingAlreadyDone');
  String get wellbeingHistory => get('wellbeingHistory');
  String get todayWellbeing => get('todayWellbeing');
  String get noWellbeingData => get('noWellbeingData');
  String get wellbeingButton => get('wellbeingButton');
  String get selectCaregiver => get('selectCaregiver');
  String get inviteCode => get('inviteCode');
  String get inviteCodeHint => get('inviteCodeHint');
  String get joinWithCode => get('joinWithCode');
  String get joinWithCodeDesc => get('joinWithCodeDesc');
  String get yourInviteCode => get('yourInviteCode');
  String get shareCode => get('shareCode');
  String get regenerateCode => get('regenerateCode');
  String get codeRegenerated => get('codeRegenerated');
  String get joinedWithCode => get('joinedWithCode');
  String get copyCode => get('copyCode');
  String get codeCopied => get('codeCopied');
  String get orSearchByEmail => get('orSearchByEmail');
  String get orJoinWithCode => get('orJoinWithCode');
  String get searching => get('searching');
  String get dailyTrackingData => get('dailyTrackingData');
  String get trackingDataDesc => get('trackingDataDesc');
  String get clearTrackingData => get('clearTrackingData');
  String get clearTrackingDataConfirm => get('clearTrackingDataConfirm');
  String get clearTrackingDataDone => get('clearTrackingDataDone');
  String get checkInsToday => get('checkInsToday');
  String get wellbeingScore => get('wellbeingScore');
  String get notDoneToday => get('notDoneToday');
  String get manualCheckInCount => get('manualCheckInCount');
  String get phoneUnlockCount => get('phoneUnlockCount');
  String get stepsCount => get('stepsCount');
  String get pickupCount => get('pickupCount');
  String get sosCount => get('sosCount');
  String get devTesting => get('devTesting');
  String get autoCheckInInterval => get('autoCheckInInterval');
  String get autoCheckInIntervalDesc => get('autoCheckInIntervalDesc');
  String get hours => get('hours');
  String get disabled => get('disabled');
  String get autoCheckInEnabled => get('autoCheckInEnabled');
  String get autoCheckInSaved => get('autoCheckInSaved');
  // ── Check-in config page ──
  String get configureCheckIn => get('configureCheckIn');
  String get currentConfiguration => get('currentConfiguration');
  String get autoTracking => get('autoTracking');
  String get alertWindow => get('alertWindow');
  String get trackingLabel => get('trackingLabel');
  String get notSet => get('notSet');
  String get alertInterval => get('alertInterval');
  String get liveLabel => get('liveLabel');
  String get enabled => get('enabled');
  String configureTitle(String name) => get('configureTitle').replaceAll('{name}', name);
  String get manualCheckInSection => get('manualCheckInSection');
  String get manualCheckInAlwaysOn => get('manualCheckInAlwaysOn');
  String get alwaysOn => get('alwaysOn');
  String get automaticSignals => get('automaticSignals');
  String get enableAutoTracking => get('enableAutoTracking');
  String get autoTrackingSubtitle => get('autoTrackingSubtitle');
  String get phoneUnlockLabel => get('phoneUnlockLabel');
  String get phoneUnlockSubtitle => get('phoneUnlockSubtitle');
  String get stepsWalking => get('stepsWalking');
  String get stepsWalkingSubtitle => get('stepsWalkingSubtitle');
  String get phonePickupLabel => get('phonePickupLabel');
  String get phonePickupSubtitle => get('phonePickupSubtitle');
  String get alertWindowSection => get('alertWindowSection');
  String alertAfterHours(int h) => get('alertAfterHours')
      .replaceAll('{hours}', '$h')
      .replaceAll('{s}', h == 1 ? '' : 's');
  String get alertWindowDesc => get('alertWindowDesc');
  String get defaultTenH => get('defaultTenH');
  String get sleepWindowSection => get('sleepWindowSection');
  String get sleepWindowPauseDesc => get('sleepWindowPauseDesc');
  String get clearLabel => get('clearLabel');
  String get sleepTimeLabel => get('sleepTimeLabel');
  String get wakeTimeLabel => get('wakeTimeLabel');
  String get noSleepWindowSet => get('noSleepWindowSet');
  String get saveAndSync => get('saveAndSync');
  String get syncBannerText => get('syncBannerText');
  String get sleepValidationError => get('sleepValidationError');
  String get settingsSaved => get('settingsSaved');
  String saveFailed(String error) => get('saveFailed').replaceAll('{error}', error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh', 'ms', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}