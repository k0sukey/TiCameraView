// This is a test harness for your module
// You should do something interesting in this harness 
// to test out the module and to provide instructions 
// to users on how to use it by example.


// open a single window
var win = Ti.UI.createWindow({
	backgroundColor:'white'
});
win.open();

// TODO: write your module tests here
var TiCamera = require('be.k0suke.ticamera');

var cameraView = TiCamera.createView({
	width: 240,
	height: 320,
	backgroundColor: '#000',
	videoQuality: TiCamera.QUALITY_MEDIUM,
	cameraPosition: TiCamera.hasFrontCamera() ? TiCamera.CAMERA_FRONT : TiCamera.CAMERA_BACK,
	frameDuration: 30
});
win.add(cameraView);

var toggle = Ti.UI.createButton({
	top: 10,
	left: 10,
	width: Ti.UI.SIZE,
	height: 44,
	title: 'toggle'
});
win.add(toggle);

toggle.addEventListener('click', function(){
	cameraView.toggleCamera();
});

var recording = Ti.UI.createButton({
	top: 10,
	width: Ti.UI.SIZE,
	height: 44,
	title: 'recording'
});
win.add(recording);

var isRecording = false;
recording.addEventListener('click', function(){
	if (isRecording) {
		cameraView.stopRecording({
			saveToPhotoGallery: save.getValue(),	// default false
			recordingSound: shutter.getValue(),		// default true
			success: function(e){
				var player = Ti.Media.createVideoPlayer({
					media: e.media,
					autoplay: true,
					mediaControlStyle: Ti.Media.VIDEO_CONTROL_FULLSCREEN,
					scalingMode: Ti.Media.VIDEO_SCALING_ASPECT_FIT
				});
				win.add(player);

				player.addEventListener('complete', function(){
					win.remove(player);
				});
			},
			error: function(e){
				console.log(e);
			}
		});
		recording.setTitle('recording');
		isRecording = false;
	} else {
		isRecording = true;
		recording.setTitle('stop');

		cameraView.startRecording({
			recordingSound: shutter.getValue()	// default true
		});
	}
});

var capture = Ti.UI.createButton({
	top: 10,
	right: 10,
	width: Ti.UI.SIZE,
	height: 44,
	title: 'capture'
});
win.add(capture);

capture.addEventListener('click', function(){
	cameraView.takePicture({
		saveToPhotoGallery: save.getValue(),	// default false
		shutterSound: shutter.getValue(),		// default true
		success: function(e){
			preview.setImage(e.media);
		},
		error: function(e){
			console.log(e);
		}
	});
});

var save = Ti.UI.createSwitch({
	top: 64,
	left: 10,
	value: false
});
win.add(save);

var shutter = Ti.UI.createSwitch({
	top: 64,
	right: 10,
	value: false
});
win.add(shutter);

var preview = Ti.UI.createImageView({
	bottom: 10,
	width: 48,
	height: 64
});
win.add(preview);