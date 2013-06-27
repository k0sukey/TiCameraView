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
	cameraPosition: TiCamera.hasBackCamera() ? TiCamera.CAMERA_BACK : TiCamera.CAMERA_FRONT,
	frameDuration: 16
});
win.add(cameraView);

cameraView.add(Ti.UI.createView({
	width: 20,
	height: 20,
	backgroundColor: '#f00',
	borderRadius: 10
}));

var camera = Ti.UI.createButton({
	top: 10,
	left: 10,
	width: Ti.UI.SIZE,
	height: 44,
	title: 'camera'
});
win.add(camera);

camera.addEventListener('click', function(){
	cameraView.toggleCamera();
});

var torch = Ti.UI.createButton({
	top: 64,
	left: 10,
	width: Ti.UI.SIZE,
	height: 44,
	title: 'torch'
});
win.add(torch);

torch.addEventListener('click', function(){
	if (cameraView.isBackCamera()) {
		cameraView.toggleTorch();
	} else {
		alert('Do not use toggleTorch method, in front camera mode');
	}
});

var recording = Ti.UI.createButton({
	top: 10,
	right: 10,
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
			recordingSound: shutter.getValue()		// default true
		});
	}
});

var capture = Ti.UI.createButton({
	top: 64,
	right: 10,
	width: Ti.UI.SIZE,
	height: 44,
	title: 'photo'
});
win.add(capture);

capture.addEventListener('click', function(){
	cameraView.takePicture({
		saveToPhotoGallery: save.getValue(),	// default false
		shutterSound: shutter.getValue(),		// default true
		success: function(e){
			console.log(e);
			console.log('width: ' + e.media.width);
			console.log('height: ' + e.media.height);
			console.log('mime: ' + e.media.mime);
			preview.setImage(e.media);
		},
		error: function(e){
			console.log(e);
		}
	});
});

var save = Ti.UI.createSwitch({
	top: 10,
	value: false
});
win.add(save);

var shutter = Ti.UI.createSwitch({
	top: 64,
	value: false
});
win.add(shutter);

var preview = Ti.UI.createImageView({
	bottom: 10,
	width: 48,
	height: 64
});
win.add(preview);