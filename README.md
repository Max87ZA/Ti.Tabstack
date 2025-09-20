# Titanium iOS Tab stack module

This module can track tab's window stack and determine if root window is visible. Usefull if you open controllers from various tabs and want to react when window closes

## Example
in your tiapp.xml add module:
<module platform="iphone">sk.maxapp.titabstack</module>

and then:

const TiTabstack = require('ti.tabstack');

// Is root shown on a tab?
if (TiTabstack.isRootVisible($.homeTab)) {
  // do something
}

// Get count / top title
const count = TiTabstack.stackCount($.homeTab);
const top = TiTabstack.topTitle($.homeTab);

// On tab switch
$.tabGroup.addEventListener('focus', e => {
  const info = TiTabstack.infoForSelectedTab($.tabGroup);
  Ti.API.debug(info.debugPath);
});

