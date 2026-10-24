import sys
p=sys.argv[1]+'/lib/core/services/card_reminder_service.dart'
s=open(p).read()
s=s.replace("final override = debugNotificationsAllowed;","final override = debugNotificationsAllowed ?? false; // store shots")
open(p,'w').write(s)
print('patched', s.count('// store shots'))
