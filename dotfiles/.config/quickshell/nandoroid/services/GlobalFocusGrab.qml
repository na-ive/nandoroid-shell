pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
  id: root

  property list<var> _persistent: []
  property list<var> _dismissable: []

  signal dismissed()

  function addPersistent(w) {
    if (_persistent.indexOf(w) === -1) {
      _persistent.push(w);
    }
  }
  function removePersistent(w) {
    var i = _persistent.indexOf(w);
    if (i !== -1) {
      _persistent.splice(i, 1);
    }
  }
  function addDismissable(w) {
    if (_dismissable.indexOf(w) === -1) {
      _dismissable.push(w);
    }
    _grab.active = _dismissable.length > 0;
  }
  function removeDismissable(w) {
    var i = _dismissable.indexOf(w);
    if (i !== -1) {
      _dismissable.splice(i, 1);
    }
    _grab.active = _dismissable.length > 0;
  }
  function dismiss() {
    _dismissable = [];
    _grab.active = false;
    dismissed();
  }

  HyprlandFocusGrab {
    id: _grab
    windows: root._persistent.concat(root._dismissable)
    onCleared: root.dismiss()
  }
}
