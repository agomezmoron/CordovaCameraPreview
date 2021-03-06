var argscheck = require('cordova/argscheck'),
  utils = require('cordova/utils'),
  exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function() {};

CameraPreview.ROTATION_FREE = -1; // Do not lock rotation
CameraPreview.ROTATION_PORTRAIT = 0; // 0°
CameraPreview.ROTATION_LANDSCAPE_RIGHT = 1; // 90°
CameraPreview.ROTATION_PORTRAIT_UPSIDE_DOWN = 2; // 180°
CameraPreview.ROTATION_LANDSCAPE_LEFT = 3; // 270°

CameraPreview.FLASH_AUTO = 0;
CameraPreview.FLASH_ON = 1;
CameraPreview.FLASH_OFF = 2;
CameraPreview.FLASH_TORCH = 3;

CameraPreview.setOnPictureTakenHandler = function(onPictureTaken) {
  exec(onPictureTaken, onPictureTaken, PLUGIN_NAME, "setOnPictureTakenHandler", []);
};

//@param rect {x: 0, y: 0, width: 100, height:100}
//@param defaultCamera "front" | "back"
CameraPreview.startCamera = function(rect, defaultCamera, toBack, rotation, alpha, prefix) {
  if (typeof(alpha) === 'undefined') alpha = 1;
  return new Promise(function(resolve, reject){
    exec(resolve, reject, PLUGIN_NAME, "startCamera", [rect.x, rect.y, rect.width, rect.height, defaultCamera, !!toBack, rotation, alpha, prefix]);
  });
};
CameraPreview.stopCamera = function() {
  exec(null, null, PLUGIN_NAME, "stopCamera", []);
};
//@param size {maxWidth: 100, maxHeight:100}
CameraPreview.takePicture = function(size) {
  var params = [0, 0];
  if (size) {
    params = [size.maxWidth, size.maxHeight];
  }
  return new Promise(function(resolve, reject){
    exec(resolve, reject, PLUGIN_NAME, "takePicture", params);
  });
};

CameraPreview.switchCamera = function() {
  exec(null, null, PLUGIN_NAME, "switchCamera", []);
};

CameraPreview.hide = function() {
  exec(null, null, PLUGIN_NAME, "hideCamera", []);
};

CameraPreview.show = function() {
  exec(null, null, PLUGIN_NAME, "showCamera", []);
};

CameraPreview.disable = function(disable) {
  exec(null, null, PLUGIN_NAME, "disable", [disable]);
};
CameraPreview.setFlashMode = function(mode) {
  exec(null, null, PLUGIN_NAME, "setFlashMode", [mode]);
}
module.exports = CameraPreview;
