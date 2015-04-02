# TODO
- [ ] Add parameters to the Quartz file so I can change them in the preferences.
- [x] Create an animation to move the text across.
- [ ] Add a preferences pane.
- [ ] Add a list of the Core Image filters that can be applied.
- [ ] Add a list of Quartz background animations the user can pick from (or which can be selected randomly after a time interval).

# Implementation notes
The User Preferences app dlopen()s the preference application, so if you replace the screensaver binary while the User Preferences is open you will not see the changes until you restart User Preferences.

The screensaver view is a bit weird so modifying it directly is not recommended. Instead create Core Animation layers above it and modify those.

The User Preferences and the System count as separate applications, so if you get the ‘default bundle’ for setting NSUserDefaults and retrieving them, the values you set will not be visible when the screensaver starts up properly. So instead hard-code the bundle-ID in the program somewhere and always refer to that.

Screensavers do not use the normal AppIcon image when displayed. Instead provide two PNG files called 'thumbnail.png' and 'thumbnail@2x.png' which will be displayed.
